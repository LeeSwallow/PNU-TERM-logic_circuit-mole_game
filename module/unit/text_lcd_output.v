module text_lcd_output (
    input  wire        clk_1mhz,
    input  wire        rst,
    input  wire [2:0]  state,
    input  wire [1:0]  stage,
    output reg         lcd_rs,
    output reg         lcd_rw,
    output reg         lcd_en,
    output reg [7:0]   lcd_data
);

// -----------------------------------------------------------------------------
// Parameters & timing
// -----------------------------------------------------------------------------
localparam INIT_DELAY_US  = 16_000; // >15ms after power
localparam CMD_DELAY_US   = 60;     // command settle (>40us)
localparam CHAR_DELAY_US  = 60;     // data write delay
localparam PULSE_WIDTH_US = 2;      // EN high width (~ > 450ns)

// Simple microsecond delay counter
reg [15:0] us_cnt;  // enough for >65ms
reg        delay_active;
reg [15:0] delay_target;

task start_delay(input [15:0] d);
begin
    delay_target  <= d;
    us_cnt        <= 16'd0;
    delay_active  <= 1'b1;
end
endtask

always @(posedge clk_1mhz or posedge rst) begin
    if (rst) begin
        us_cnt <= 16'd0;
        delay_active <= 1'b0;
    end else if (delay_active) begin
        if (us_cnt < delay_target) begin
            us_cnt <= us_cnt + 16'd1;
        end else begin
            delay_active <= 1'b0;
        end
    end
end

// -----------------------------------------------------------------------------
// Build line buffers on demand
// -----------------------------------------------------------------------------
reg [7:0] line1 [0:15];
reg [7:0] line2 [0:15];

// Previous sampled values to detect change
reg [2:0]  prev_state;
reg [1:0]  prev_stage;

wire need_update = (state != prev_state) || (stage != prev_stage);

// Digit to ASCII helper
function [7:0] D;
    input [3:0] v;
begin
    D = 8'h30 + v; // '0'+v
end
endfunction

// Select full state name (16 chars)
function [127:0] get_state_text;
    input [2:0] s;
begin
    case (s)
        3'd0: get_state_text = "READY           ";
        3'd1: get_state_text = "PLAY            ";
        3'd3: get_state_text = "GAME OVER       ";
        3'd4: get_state_text = "STAGE CLEAR     ";
        3'd5: get_state_text = "GAME CLEAR      ";
        default: get_state_text = "                ";
    endcase
end
endfunction

// Build buffers
reg [127:0] next_line1;
reg [127:0] next_line2;
integer i;

always @(posedge clk_1mhz or posedge rst) begin
    if (rst) begin
        prev_state <= 3'd7; // force first update
        prev_stage <= 2'd0;
    end else if (need_update && !updating && !init_phase) begin
        prev_state <= state;
        prev_stage <= stage;

        // Prepare text
        next_line1 = get_state_text(state);

        if (state == 3'd3 || state == 3'd5) begin
            // Game Over / Game Clear: No stage info
            next_line2 = "                ";
        end else begin
            // "Stage X         "
            next_line2 = {"Stage ", D({2'b00, stage}), "         "};
        end

        // Assign to line buffers
        for (i=0; i<16; i=i+1) begin
            line1[i] <= next_line1[127 - i*8 -: 8];
            line2[i] <= next_line2[127 - i*8 -: 8];
        end

        request_update <= 1'b1;
    end
end

// -----------------------------------------------------------------------------
// LCD write FSM
// -----------------------------------------------------------------------------
localparam S_INIT_WAIT = 0,
           S_INIT_FUNC = 1,
           S_INIT_DISP = 2,
           S_INIT_CLR  = 3,
           S_INIT_ENTRY= 4,
           S_IDLE      = 5,
           S_SET_LINE1 = 6,
           S_WRITE_L1  = 7,
           S_SET_LINE2 = 8,
           S_WRITE_L2  = 9;

reg [3:0]  fsm_state;
reg [4:0]  char_idx;
reg        init_phase;
reg        updating;
reg        request_update;

// Helper: issue command/data
reg [7:0] pending_byte;
reg       pending_is_data;
reg [1:0] pulse_cnt;
reg       issuing;

task issue(input [7:0] b, input is_data, input [15:0] wait_us);
begin
    pending_byte    <= b;
    pending_is_data <= is_data;
    issuing         <= 1'b1;
    pulse_cnt       <= 2'd0;
    start_delay(wait_us);
end
endtask

always @(posedge clk_1mhz or posedge rst) begin
    if (rst) begin
        fsm_state      <= S_INIT_WAIT;
        init_phase     <= 1'b1;
        updating       <= 1'b0;
        request_update <= 1'b0;
        lcd_en         <= 1'b0;
        lcd_rs         <= 1'b0;
        lcd_rw         <= 1'b0; // write only
        lcd_data       <= 8'h00;
        issuing        <= 1'b0;
        char_idx       <= 5'd0;
    end else begin
        // Handle issuing pulse
        if (issuing) begin
            // Drive signals
            lcd_rs <= pending_is_data;
            lcd_rw <= 1'b0;
            lcd_data <= pending_byte;
            // Simple EN pulse generation for few microseconds
            if (pulse_cnt == 2'd0) begin
                lcd_en   <= 1'b1;
                pulse_cnt <= 2'd1;
            end else if (pulse_cnt == 2'd1) begin
                // keep EN high for PULSE_WIDTH_US via delay_active
                if (!delay_active) begin
                    // falling edge
                    lcd_en <= 1'b0;
                    pulse_cnt <= 2'd2;
                    start_delay(pending_is_data ? CHAR_DELAY_US : CMD_DELAY_US);
                end
            end else if (pulse_cnt == 2'd2) begin
                if (!delay_active) begin
                    issuing <= 1'b0; // finished
                end
            end
        end else begin
            lcd_en <= 1'b0;
        end

        if (!issuing) begin
            case (fsm_state)
                S_INIT_WAIT: begin
                    if (!delay_active) begin
                        start_delay(INIT_DELAY_US);
                        fsm_state <= S_INIT_FUNC;
                    end
                end
                S_INIT_FUNC: begin
                    if (!delay_active) begin
                        issue(8'h38, 1'b0, CMD_DELAY_US); // 8-bit, 2 line
                        fsm_state <= S_INIT_DISP;
                    end
                end
                S_INIT_DISP: begin
                    if (!delay_active) begin
                        issue(8'h0C, 1'b0, CMD_DELAY_US); // display on, cursor off
                        fsm_state <= S_INIT_CLR;
                    end
                end
                S_INIT_CLR: begin
                    if (!delay_active) begin
                        issue(8'h01, 1'b0, CMD_DELAY_US); // clear
                        fsm_state <= S_INIT_ENTRY;
                    end
                end
                S_INIT_ENTRY: begin
                    if (!delay_active) begin
                        issue(8'h06, 1'b0, CMD_DELAY_US); // entry mode
                        init_phase <= 1'b0;
                        fsm_state  <= S_IDLE;
                    end
                end
                S_IDLE: begin
                    updating <= 1'b0;
                    char_idx <= 5'd0;
                    if (request_update) begin
                        request_update <= 1'b0;
                        updating <= 1'b1;
                        fsm_state <= S_SET_LINE1;
                    end
                end
                S_SET_LINE1: begin
                    issue(8'h80, 1'b0, CMD_DELAY_US); // line1 address
                    fsm_state <= S_WRITE_L1;
                    char_idx <= 5'd0;
                end
                S_WRITE_L1: begin
                    if (char_idx < 16) begin
                        issue(line1[char_idx], 1'b1, CHAR_DELAY_US);
                        char_idx <= char_idx + 5'd1;
                    end else begin
                        fsm_state <= S_SET_LINE2;
                        char_idx <= 5'd0;
                    end
                end
                S_SET_LINE2: begin
                    issue(8'hC0, 1'b0, CMD_DELAY_US); // line2 address
                    fsm_state <= S_WRITE_L2;
                end
                S_WRITE_L2: begin
                    if (char_idx < 16) begin
                        issue(line2[char_idx], 1'b1, CHAR_DELAY_US);
                        char_idx <= char_idx + 5'd1;
                    end else begin
                        fsm_state <= S_IDLE;
                    end
                end
                default: fsm_state <= S_IDLE;
            endcase
        end
    end
end

endmodule