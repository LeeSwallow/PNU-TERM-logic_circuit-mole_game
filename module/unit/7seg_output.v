module seg_output(
    input  wire       clk_1mhz,
    input  wire       rst,
    input  wire [1:0] lives,     // 0~3 (2-bit), will be zero-extended internally
    output reg  [7:0] seg_out   // segment pattern (a b c d e f g dp)
);

    // Extend lives to 4 bits for uniform digit handling
    wire [3:0] lives_ext = {2'b00, lives};

    // 7-segment encoding (common cathode)
    function [7:0] encode_7seg(input [3:0] digit);
        begin
            case (digit)
                4'd0: encode_7seg = 8'b00111111;
                4'd1: encode_7seg = 8'b00000110;
                4'd2: encode_7seg = 8'b01011011;
                4'd3: encode_7seg = 8'b01001111;
                4'd4: encode_7seg = 8'b01100110;
                4'd5: encode_7seg = 8'b01101101;
                4'd6: encode_7seg = 8'b01111101;
                4'd7: encode_7seg = 8'b00000111;
                4'd8: encode_7seg = 8'b01111111;
                4'd9: encode_7seg = 8'b01101111;
                default: encode_7seg = 8'b00000000; // blank for invalid input
            endcase
        end
    endfunction

    always @(posedge clk_1mhz or posedge rst) begin
        if (rst) begin
            seg_out <= 8'b00000000; // all segments off
        end else begin
            seg_out <= encode_7seg(lives_ext[3:0]); // display lives on 7-seg
        end
    end


endmodule