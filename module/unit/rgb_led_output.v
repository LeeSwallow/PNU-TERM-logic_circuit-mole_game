module rgb_led_output (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  state,
    output reg [2:0]  led_red,
    output reg [2:0]  led_green,
    output reg [2:0]  led_blue
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led_red   <= 3'b000;
            led_green <= 3'b000;
            led_blue  <= 3'b000;
        end else begin
            case (state)
                3'd3: begin // GAME OVER -> RED
                    led_red   <= 3'b111;
                    led_green <= 3'b000;
                    led_blue  <= 3'b000;
                end
                3'd5: begin // GAME CLEAR -> GREEN
                    led_red   <= 3'b000;
                    led_green <= 3'b111;
                    led_blue  <= 3'b000;
                end
                default: begin // Others -> OFF
                    led_red   <= 3'b000;
                    led_green <= 3'b000;
                    led_blue  <= 3'b000;
                end
            endcase
        end
    end
endmodule