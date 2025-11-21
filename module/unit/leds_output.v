module leds_output(
    input wire [3:0] mole_pos, // which mole to show
    output reg [7:0] leds // LED outputs
);
// LED output logic
always @(*) begin
    case (mole_pos)
        4'b0001: leds = 8'b0000_0001; // mole 1
        4'b0010: leds = 8'b0000_0010; // mole 2
        4'b0011: leds = 8'b0000_0100; // mole 3
        4'b0100: leds = 8'b0000_1000; // mole 4
        4'b0101: leds = 8'b0001_0000; // mole 5
        4'b0110: leds = 8'b0010_0000; // mole 6
        4'b0111: leds = 8'b0100_0000; // mole 7
        4'b1000: leds = 8'b1000_0000; // mole 8
        default: leds = 8'b0000_0000; // no mole
    endcase
end
endmodule