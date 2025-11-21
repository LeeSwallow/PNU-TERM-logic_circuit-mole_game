module peizo_output (
    input wire clk_1MHz, input wire rst,
    input wire [3:0] mode,
    output reg piezo_out
);

wire [11:0] freq;
reg  [11:0] cnt;

// select frequency based on mode (combinational wire)
assign freq = (mode == 4'b0001) ? 12'd1911 : // C4
              (mode == 4'b0010) ? 12'd1703 : // D4
              (mode == 4'b0011) ? 12'd1517 : // E4
              (mode == 4'b0100) ? 12'd1432 : // F4
              (mode == 4'b0101) ? 12'd1275 : // G4
              (mode == 4'b0110) ? 12'd1136 : // A4
              (mode == 4'b0111) ? 12'd1012 : // B4
              (mode == 4'b1000) ? 12'd956  : // C5
                                    12'd0;  // no sound

// generate piezo output signal based on frequency
always @(posedge clk_1MHz or posedge rst) begin
    if (rst) begin
        cnt <= 12'd0;
        piezo_out <= 1'b0;
    end 
    // toggle piezo output at the specified frequency
    else if (freq > 0) begin
        cnt <= cnt + 12'd1;
        if (cnt >= freq) begin 
            piezo_out <= ~piezo_out;
            cnt <= 12'd0;
        end
    end 
    // no sound
    else begin
        cnt <= 12'd0;
        piezo_out <= 1'b0;
    end
end
endmodule
