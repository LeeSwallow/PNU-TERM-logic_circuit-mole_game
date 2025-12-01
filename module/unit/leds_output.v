module leds_output(
    input wire [3:0] mole_pos1, // which mole to show
    input wire [3:0] mole_pos2, // which mole to show
    output reg [7:0] leds // LED outputs
);
// LED output logic
always @(*) begin
    leds = 8'b00000000;
    leds = (mole_pos1 != 4'b0000) ? (leds | (8'b1 << (mole_pos1 - 1))) : leds;
    leds = (mole_pos2 != 4'b0000) ? (leds | (8'b1 << (mole_pos2 - 1))) : leds;
end
endmodule