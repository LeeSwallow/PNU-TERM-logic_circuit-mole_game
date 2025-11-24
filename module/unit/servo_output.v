// Servo output module
// Base clock: 1MHz
// Standard hobby servo expects ~50Hz (20ms) frame.
// Pulse width range (~0.7ms .. ~2.3ms) maps to timer (0..60).
// When enable=0 outputs neutral (center) pulse.
module servo_output (
    input  wire       clk_1mhz,
    input  wire       rst,
    input  wire       enable,      // enable position mapping
    input  wire [6:0] timer,       // 0~60 seconds value
    output reg        servo_out
);

    // Frame parameters (1MHz clock)
    localparam integer FRAME_CYCLES       = 20_000; // 20ms period
    localparam integer MIN_PULSE_CYCLES   = 700;    // 0.7ms
    localparam integer MAX_PULSE_CYCLES   = 2_300;  // 2.3ms
    localparam integer CENTER_PULSE_CYCLES= (MIN_PULSE_CYCLES + MAX_PULSE_CYCLES)/2; // ~1.5ms
    localparam integer TIMER_MAX          = 60;     // clamp upper

    // Counter for frame timing
    reg [14:0] frame_cnt; // needs to count up to 20_000 (<2^15)
    wire frame_last = (frame_cnt == FRAME_CYCLES - 1);

    always @(posedge clk_1mhz or posedge rst) begin
        if (rst) begin
            frame_cnt <= 15'd0;
        end else if (frame_last) begin
            frame_cnt <= 15'd0;
        end else begin
            frame_cnt <= frame_cnt + 15'd1;
        end
    end

    // Compute desired pulse width from timer (linear mapping)
    // pulse = MIN + (MAX-MIN)*timer/60
    // Use integer arithmetic; clamp timer if > TIMER_MAX
    wire [6:0] timer_clamped = (timer > TIMER_MAX[6:0]) ? TIMER_MAX[6:0] : timer;
    localparam integer RANGE = (MAX_PULSE_CYCLES - MIN_PULSE_CYCLES); // 1600
    // Multiply then divide; widen for intermediate product
    wire [21:0] scaled = RANGE * timer_clamped; // <= 1600*60 = 96000 < 2^17
    wire [12:0] mapped_pulse = MIN_PULSE_CYCLES + (scaled / TIMER_MAX); // 13 bits enough

    reg [12:0] active_pulse;
    always @(*) begin
        if (!enable) begin
            active_pulse = CENTER_PULSE_CYCLES;
        end else begin
            active_pulse = mapped_pulse;
        end
    end

    // Generate PWM output
    always @(posedge clk_1mhz or posedge rst) begin
        if (rst) begin
            servo_out <= 1'b0; // will go high at frame_cnt start
        end else begin
            servo_out <= (frame_cnt < active_pulse);
        end
    end

endmodule