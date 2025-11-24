// 8-digit 7-segment array output driver
// Layout updated: use 4-digit block for score (left side), 4-digit block for lives (right side).
// Score shown in thousands,hundreds,tens,ones with leading zero blanking.
// Lives (2-bit) shown in ones place of right block; its upper 3 digits always blank.
// Base clock: 1MHz. Simple time-multiplexing.
module seg_arr_output(
    input  wire       clk_1mhz,
    input  wire       rst,
    input  wire [1:0] lives,     // 0~3 (2-bit), will be zero-extended internally
    input  wire [9:0] score,     // 0~999
    output reg  [7:0] seg_out,   // segment pattern (a b c d e f g dp)
    output reg  [7:0] array_out  // digit select (one-hot, active LOW by default)
);
    // Extend lives to 4 bits for uniform digit handling
    wire [3:0] lives_ext = {2'b00, lives};

    // Parameters
    localparam integer REFRESH_DIV = 1000; // 1MHz/1000 = 1kHz per digit step
    localparam COMMON_ANODE = 1;           // If display is common-anode (active low digit select)

    // Refresh counter & scan index
    reg [9:0] refresh_cnt; // counts to REFRESH_DIV-1
    reg [2:0] scan_idx;    // 0..7

    always @(posedge clk_1mhz or posedge rst) begin
        if (rst) begin
            refresh_cnt <= 10'd0;
            scan_idx    <= 3'd0;
        end else if (refresh_cnt == REFRESH_DIV - 1) begin
            refresh_cnt <= 10'd0;
            scan_idx    <= scan_idx + 3'd1;
        end else begin
            refresh_cnt <= refresh_cnt + 10'd1;
        end
    end

    // Score digit extraction (extend to 4 digits block)
    // Clamp score to 0~9999 (input is 10 bits so actual max 1023)
    wire [13:0] score_clamped = (score > 14'd9999) ? 14'd9999 : score;
    wire [3:0] thousands = score_clamped / 14'd1000;
    wire [3:0] hundreds  = (score_clamped / 14'd100) % 10;
    wire [3:0] tens      = (score_clamped / 14'd10) % 10;
    wire [3:0] ones      = score_clamped % 14'd10;

    // Leading zero blanking flags for score block
    wire blank_thousands = (thousands == 4'd0);
    wire blank_hundreds  = blank_thousands && (hundreds == 4'd0);
    wire blank_tens      = blank_hundreds && (tens == 4'd0);

    // Digit mapping (scan_idx -> value)
    // New swapped layout (scan_idx 7→0):
    // [7] score thousands (blank if leading zero)
    // [6] score hundreds  (blank if leading zero)
    // [5] score tens      (blank if leading zero)
    // [4] score ones
    // [3] lives thousands (blank)
    // [2] lives hundreds  (blank)
    // [1] lives tens      (blank)
    // [0] lives ones (lives_ext)
    reg [3:0] digit_val;
    reg       digit_blank;
    always @(*) begin
        digit_blank = 1'b0;
        case (scan_idx)
            3'd7: begin digit_val = thousands; digit_blank = blank_thousands; end // score thousands
            3'd6: begin digit_val = hundreds;  digit_blank = blank_hundreds;  end // score hundreds
            3'd5: begin digit_val = tens;      digit_blank = blank_tens;      end // score tens
            3'd4: digit_val = ones;                                           // score ones
            3'd3: begin digit_val = 4'h0; digit_blank = 1'b1; end             // lives thousands (blank)
            3'd2: begin digit_val = 4'h0; digit_blank = 1'b1; end             // lives hundreds (blank)
            3'd1: begin digit_val = 4'h0; digit_blank = 1'b1; end             // lives tens (blank)
            3'd0: digit_val = lives_ext;                                      // lives ones
            default: begin digit_val = 4'h0; digit_blank = 1'b1; end
        endcase
    end

    // Segment encoding (common-anode style, 1 = segment ON in reference patterns)
    // Reference provided only 0-7; extend 8,9 plus blank.
    function [7:0] encode_digit;
        input [3:0] d;
        begin
            case (d)
                4'd0: encode_digit = 8'b11111100; // 0
                4'd1: encode_digit = 8'b01100000; // 1
                4'd2: encode_digit = 8'b11011010; // 2
                4'd3: encode_digit = 8'b11110010; // 3
                4'd4: encode_digit = 8'b01100110; // 4
                4'd5: encode_digit = 8'b10110110; // 5
                4'd6: encode_digit = 8'b10111110; // 6
                4'd7: encode_digit = 8'b11100000; // 7
                4'd8: encode_digit = 8'b11111110; // 8 (added)
                4'd9: encode_digit = 8'b11110110; // 9 (added)
                default: encode_digit = 8'b00000000; // blank / off
            endcase
        end
    endfunction

    wire [7:0] seg_raw = encode_digit(digit_val);

    always @(*) begin
        // Blank handling
        seg_out = digit_blank ? 8'b00000000 : seg_raw;
        // Digit select one-hot
        if (COMMON_ANODE) begin
            array_out = ~(8'b0000_0001 << scan_idx); // active low
        end else begin
            array_out = (8'b0000_0001 << scan_idx);  // active high
        end
    end

endmodule
