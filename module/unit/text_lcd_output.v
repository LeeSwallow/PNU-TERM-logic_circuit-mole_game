module text_lcd_output (
    input  wire        clk_1mhz,
    input  wire        rst,
    input  wire [2:0]  gsm_state,
    input  wire [1:0]  gsm_stage,
    input  wire [9:0]  gsm_high_score,
    input  wire        gsm_high_score_updated,
    output reg         lcd_rs,
    output reg         lcd_rw,
    output wire        lcd_en,
    output reg [7:0]   lcd_data
);


reg [3:0] state;
parameter delay = 4'd0, 
    function_set = 4'd1, 
    entry_mode = 4'd2,
    disp_onoff = 4'd3,
    line1 = 4'd4,
    line2 = 4'd5,
    delay_t = 4'd6,
    clear_disp = 4'd7,
    idle = 4'd8;

reg update_req;
reg [2:0] prev_gsm_state;
reg prev_high_score_updated;

// 0~999 high score digit extraction
wire [9:0] high_score_clamped = (gsm_high_score > 10'd999) ? 10'd999 : gsm_high_score;
wire [3:0] hs_hundreds = (high_score_clamped / 10'd100) % 10;
wire [3:0] hs_tens     = (high_score_clamped / 10'd10) % 10;
wire [3:0] hs_ones     = high_score_clamped % 10;

// Update Request Logic
always @(posedge clk_1mhz or posedge rst) begin
    if (rst) begin
        update_req <= 1'b1;
        prev_gsm_state <= 3'b000;
    end
    else begin
        if (gsm_state != prev_gsm_state) begin
            update_req <= 1'b1;
            prev_gsm_state <= gsm_state;
        end
        if (gsm_high_score_updated != prev_high_score_updated) begin
            update_req <= 1'b1;
            prev_high_score_updated <= gsm_high_score_updated;
        end
        else if (state == clear_disp) update_req <= 1'b0;
    end
end

reg clk_100hz;
reg [19:0] cnt_100hz, cnt;

// Generate 100Hz clock from 1MHz clock
always @(posedge clk_1mhz or posedge rst) begin
    if (rst) begin
        cnt_100hz = 20'd0;
        clk_100hz = 1'b0;
    end else begin
        if (cnt_100hz < 20'd4999) begin
            cnt_100hz = cnt_100hz + 20'd1;
        end else begin
            cnt_100hz = 20'd0;
            clk_100hz = ~clk_100hz;
        end
    end
end


// FSM for LCD control
always @(posedge clk_100hz or posedge rst) begin
    if (rst) begin
        state = delay;
        cnt = 20'd0;
    end
    else begin
        cnt = cnt + 20'd1;
        case (state)
            delay:          begin if (cnt >= 70) begin state = function_set; cnt = 20'd0; end end
            function_set:   begin if (cnt >= 30) begin state = disp_onoff; cnt = 20'd0; end end
            disp_onoff:     begin if (cnt >= 30) begin state = entry_mode; cnt = 20'd0; end end
            entry_mode:     begin if (cnt >= 30) begin state = idle; cnt = 20'd0; end end
            idle:           begin if (update_req) begin state = clear_disp; cnt = 20'd0; end end
            line1:          begin if (cnt >= 20) begin state = line2; cnt = 20'd0; end end
            line2:          begin if (cnt >= 20) begin state = idle; cnt = 20'd0; end end
            delay_t:        begin if (cnt >= 2) begin state = clear_disp; cnt = 20'd0; end end
            clear_disp:     begin if (cnt >= 2) begin state = line1; cnt = 20'd0; end end
            default:        begin state = delay; cnt = 20'd0; end
        endcase
    end
end


// Counter for state timing
always @(posedge clk_100hz or posedge rst) begin
    if (rst) begin
        lcd_rs   = 1'b1;
        lcd_rw   = 1'b1;
        lcd_data = 8'b00000000;
    end
    else begin
        case (state)
            function_set: begin
                lcd_rs   = 1'b0; lcd_rw   = 1'b0; lcd_data = 8'b00111100;
            end
            disp_onoff: begin 
                lcd_rs   = 1'b0; lcd_rw   = 1'b0; lcd_data = 8'b00001100;
            end
            entry_mode: begin
                lcd_rs   = 1'b0; lcd_rw   = 1'b0; lcd_data = 8'b00000110;
            end
            line1: begin
                lcd_rw = 1'b0;
                
                // ready
                if (gsm_state == 3'b001) begin
                    case (cnt)
                        0: begin
                            lcd_rs   = 1'b0; lcd_data = 8'b10000000; // Set DDRAM address to 0x00
                        end
                        1: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01010010; // 'R'
                        end
                        2: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000101; // 'E'
                        end
                        3: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000001; // 'A'
                        end
                        4: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000100; // 'D'
                        end
                        5: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01011001; // 'Y'
                        end
                        default : begin
                            lcd_rs = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                    endcase
                end
                // playing
                else if (gsm_state == 3'b010) begin
                    case (cnt)
                        0: begin
                            lcd_rs   = 1'b0; lcd_data = 8'b10000000; // Set DDRAM address to 0x00
                        end
                        1: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01010000; // 'P'
                        end
                        2: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01001100; // 'L'
                        end
                        3: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000001; // 'A'
                        end
                        4: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01011001; // 'Y'
                        end
                        5: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01001001; // 'I'
                        end
                        6: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01001110; // 'N'
                        end
                        7: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000111; // 'G'
                        end
                        default : begin
                            lcd_rs = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                    endcase
                end
                // game over
                else if (gsm_state == 3'b011) begin
                    case (cnt)
                        0: begin
                            lcd_rs   = 1'b0; lcd_data = 8'b10000000; // Set DDRAM address to 0x00
                        end
                        1: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000111; // 'G'
                        end
                        2: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000001; // 'A'
                        end
                        3: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01001101; // 'M'
                        end
                        4: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000101; // 'E'
                        end
                        5: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                        6: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01001111; // 'O'
                        end
                        7: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01010110; // 'V'
                        end
                        8: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000101; // 'E'
                        end
                        9: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01010010; // 'R'
                        end
                        default : begin
                            lcd_rs = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                    endcase
                end
                // stage clear
                else if (gsm_state == 3'b100) begin
                    case (cnt)
                        0: begin
                            lcd_rs   = 1'b0; lcd_data = 8'b10000000; // Set DDRAM address to 0x00
                        end
                        1: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01010011; // 'S'
                        end
                        2: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01010100; // 'T'
                        end
                        3: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000001; // 'A'
                        end
                        4: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000111; // 'G'
                        end
                        5: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000101; // 'E'
                        end
                        6: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                        7: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000011; // 'C'
                        end
                        8: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01001100; // 'L'
                        end
                        9: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000101; // 'E'
                        end
                        10: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000001; // 'A'
                        end
                        default : begin
                            lcd_rs = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                    endcase
                end
                // game clear
                else if (gsm_state == 3'b101) begin
                    case (cnt)
                        0: begin
                            lcd_rs   = 1'b0; lcd_data = 8'b10000000; // Set DDRAM address to 0x00
                        end
                        1: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000111; // 'G'
                        end
                        2: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000001; // 'A'
                        end
                        3: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01001101; // 'M'
                        end
                        4: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000101; // 'E'
                        end
                        5: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                        6: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000011; // 'C'
                        end
                        7: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01001100; // 'L'
                        end
                        8: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000101; // 'E'
                        end
                        9: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000001; // 'A'
                        end
                        10: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01010010; // 'R'
                        end
                        default : begin
                            lcd_rs = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                    endcase
                end
                // default blank
                else begin
                    case (cnt)
                        0: begin
                            lcd_rs   = 1'b0; lcd_data = 8'b10000000; // Set DDRAM address to 0x00
                        end
                        default : begin
                            lcd_rs = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                    endcase
                end 
            end
            line2: begin
                // ready or playing
                if (gsm_state == 3'b001 || gsm_state == 3'b010) begin
                    case(cnt)
                        0: begin
                            lcd_rs   = 1'b0; lcd_data = 8'b11000000; // Set DDRAM address to 0x40
                        end
                        1: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01010011; // 'S'
                        end
                        2: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01010100; // 'T'
                        end
                        3: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000001; // 'A'
                        end
                        4: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000111; // 'G'
                        end
                        5: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b01000101; // 'E'
                        end
                        6: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b00111010; // ':'
                        end
                        7: begin
                            lcd_rs   = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                        8: begin
                            lcd_rs   = 1'b1; lcd_data = {6'b001100, gsm_stage}; // stage number
                        end
                        default : begin
                            lcd_rs = 1'b1; lcd_data = 8'b00100000; // ' '
                        end
                    endcase
                end
                else if (gsm_state == 3'b011 || gsm_state == 3'b101) begin
                    case (cnt)
                        0: begin
                            lcd_rs   = 1'b0;
                            lcd_data = 8'b11000000; // Set DDRAM address to 0x40
                        end
                        1: begin
                            lcd_rs   = 1'b1;
                            lcd_data = 8'b01000010; // 'B'
                        end
                        2: begin
                            lcd_rs   = 1'b1;
                            lcd_data = 8'b01000101; // 'E'
                        end
                        3: begin
                            lcd_rs   = 1'b1;
                            lcd_data = 8'b01010011; // 'S'
                        end
                        4: begin
                            lcd_rs   = 1'b1;
                            lcd_data = 8'b01010100; // 'T'
                        end
                        5: begin
                            lcd_rs   = 1'b1;
                            lcd_data = 8'b00111010; // ':'
                        end
                        6: begin
                            lcd_rs   = 1'b1;
                            lcd_data = 8'b00100000; // ' '
                        end
                        8: begin
                            lcd_rs   = 1'b1;
                            if (hs_hundreds != 4'd0) begin
                                lcd_data = {4'b0011, hs_hundreds}; // high score hundreds
                            end else begin
                                lcd_data = 8'b00100000; // ' '
                            end
                        end
                        9: begin
                            lcd_rs   = 1'b1;
                            if (hs_hundreds != 4'd0 || hs_tens != 4'd0) begin
                                lcd_data = {4'b0011, hs_tens};     // high score tens
                            end else begin
                                lcd_data = 8'b00100000; // ' '
                            end
                        end
                        10: begin
                            lcd_rs   = 1'b1;
                            lcd_data = {4'b0011, hs_ones};     // high score ones
                        end
                        11: begin
                            lcd_rs   = 1'b1;
                            if (gsm_high_score_updated) begin
                                lcd_data = 8'b00101010; // '*' if high score updated
                            end else begin
                                lcd_data = 8'b00100000; // ' '
                            end
                        end
                        default : begin
                            lcd_rs = 1'b1;
                            lcd_data = 8'b00100000; // ' '
                        end
                    endcase
                end

                // default blank
                else begin
                    case (cnt)
                        0: begin
                            lcd_rs   = 1'b0;
                            lcd_data = 8'b11000000; // Set DDRAM address to 0x40
                        end
                        default : begin
                            lcd_rs = 1'b1;
                            lcd_data = 8'b00100000; // ' '
                        end
                    endcase
                end
            end
            delay_t: begin
                lcd_rs   = 1'b0;
                lcd_rw   = 1'b0;
                lcd_data = 8'b00000010;             
            end
            clear_disp: begin
                lcd_rs   = 1'b0;
                lcd_rw   = 1'b0;
                lcd_data = 8'b00000001; // Clear display
            end
            default: begin
                lcd_rs   = 1'b1;
                lcd_rw   = 1'b1;
                lcd_data = 8'b00000000;
            end
        endcase
    end
end

assign lcd_en = (state == idle) ? 1'b0 : clk_100hz;

endmodule