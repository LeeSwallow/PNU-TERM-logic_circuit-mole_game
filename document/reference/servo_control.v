module servo_control(
    input wire clk,
    input wire rst,
    input wire l_ctrl,
    input wire r_ctrl,
    output wire servo
);
    // click freq : 10kHz, period : 0.1us
    // 0 rad : 0.7ms
    // 180 rad : 2.3ms
    localparam integer FRAME_TICKS = 100; // 10ms
    localparam integer MIN_PULSE_TICKS = 7;   // 0.7ms
    localparam integer MAX_PULSE_TICKS = 23;  // 2.3ms
    localparam integer PULSE_STEP = 1;

    reg [16:0] cnt;
    reg [16:0] pulse;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 17'd0;
            pulse <= MIN_PULSE_TICKS;
        end
        else if (cnt == FRAME_TICKS - 1) begin
            cnt <= 17'd0;
            
            // 10ms * 16000 ticks / 50 = 3.2s 
            if (l_ctrl && !r_ctrl && pulse > MIN_PULSE_TICKS) begin
                pulse <= pulse - PULSE_STEP; // turn left
            end
            else if (!l_ctrl && r_ctrl && pulse < MAX_PULSE_TICKS) begin
                pulse <= pulse + PULSE_STEP; // turn right
            end
        end
        else begin
            cnt <= cnt + 17'd1;
        end
    end
    assign servo = (cnt < pulse);
endmodule