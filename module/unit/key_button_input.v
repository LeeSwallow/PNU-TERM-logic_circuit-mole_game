module key_button_input(
    input wire clk_1MHz, input wire rst,
    input wire[11:0] key_button_in,
    output reg button_pressed,
    output reg[3:0] button_value
);

always @(posedge clk_1MHz or posedge rst) begin
    if (rst) begin
        button_pressed <= 1'b0;
        button_value <= 4'd0;
    end else begin
        case (key_button_in)
            12'b0000_0000_0001: begin button_pressed <= 1'b1; button_value <= 4'd1; end
            12'b0000_0000_0010: begin button_pressed <= 1'b1; button_value <= 4'd2; end
            12'b0000_0000_0100: begin button_pressed <= 1'b1; button_value <= 4'd3; end
            12'b0000_0000_1000: begin button_pressed <= 1'b1; button_value <= 4'd4; end
            12'b0000_0001_0000: begin button_pressed <= 1'b1; button_value <= 4'd5; end
            12'b0000_0010_0000: begin button_pressed <= 1'b1; button_value <= 4'd6; end
            12'b0000_0100_0000: begin button_pressed <= 1'b1; button_value <= 4'd7; end
            12'b0000_1000_0000: begin button_pressed <= 1'b1; button_value <= 4'd8; end
            12'b0001_0000_0000: begin button_pressed <= 1'b1; button_value <= 4'd9; end
            12'b0010_0000_0000: begin button_pressed <= 1'b1; button_value <= 4'd10; end
            12'b0100_0000_0000: begin button_pressed <= 1'b1; button_value <= 4'd11; end
            12'b1000_0000_0000: begin button_pressed <= 1'b1; button_value <= 4'd12; end
            default: begin button_pressed <= 1'b0; button_value <= 4'd0; end
        endcase
    end
end
endmodule