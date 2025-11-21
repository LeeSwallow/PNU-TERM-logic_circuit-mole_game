module rand_gen(
    input wire clk_1mhz, input wire rst,
    output reg [8:0] rand_num
);
reg [15:0] lfsr;
always @(posedge clk_1mhz or posedge rst) begin
    if (rst) begin
        lfsr <= 16'hACE1; // non-zero seed
        rand_num <= 9'd0;
    end else begin
        // LFSR feedback polynomial: x^16 + x^14 + x^13 + x^11 + 1
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        rand_num <= lfsr[8:0]; // output lower 9 bits as random number
    end
end
endmodule