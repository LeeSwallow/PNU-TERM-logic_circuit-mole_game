module bin_to_seg(num, seg);
    input [2:0] num;
    output reg [7:0] seg; // include . for decimal point

    always @(*) begin
        case(num)
            3'b000: seg = 8'b11111100; // 0
            3'b001: seg = 8'b01100000; // 1
            3'b010: seg = 8'b11011010; // 2
            3'b011: seg = 8'b11110010; // 3
            3'b100: seg = 8'b01100110; // 4
            3'b101: seg = 8'b10110110; // 5
            3'b110: seg = 8'b10111110; // 6
            3'b111: seg = 8'b11100000; // 7
        endcase
    end
endmodule