module rgb_led_output (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  state,
    input  wire        timer_running,
    input  wire [6:0]  timer,
    output reg [3:0]  led_red,
    output reg [3:0]  led_green,
    output reg [3:0]  led_blue
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led_red   <= 4'b0000;
            led_green <= 4'b0000;
            led_blue  <= 4'b0000;
        end else begin
            case (state)
                3'b001: begin 
                    if (timer_running) begin
                        if (timer > 7'd0) begin // READY state with timer running -> YELLOW
                            led_red   <= 4'b1111;
                            led_green <= 4'b1111;
                            led_blue  <= 4'b0000;
                        end else begin // READY state with timer expired -> GREEN
                            led_red   <= 4'b0000;
                            led_green <= 4'b1111;
                            led_blue  <= 4'b0000;
                        end
                    end else begin
                        // default READY state (not running) -> OFF
                        led_red   <= 4'b0000;
                        led_green <= 4'b0000;
                        led_blue  <= 4'b0000;
                    end
                end

                3'b011: begin // GAME OVER -> RED
                    led_red   <= 4'b1111;
                    led_green <= 4'b0000;
                    led_blue  <= 4'b0000;
                end
                
                3'b101: begin // GAME CLEAR -> GREEN
                    led_red   <= 4'b0000;
                    led_green <= 4'b1111;
                    led_blue  <= 4'b0000;
                end
                
                default: begin // Others -> OFF
                    led_red   <= 4'b0000;
                    led_green <= 4'b0000;
                    led_blue  <= 4'b0000;
                end
            endcase
        end
    end
endmodule