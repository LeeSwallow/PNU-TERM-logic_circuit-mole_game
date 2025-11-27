module gsm(
    input wire clk_1mhz, input wire rst,
    input wire [3:0] flag, // what to change
    input wire trig, // change global state trigger
    output reg done, // alert if trigger is done
    output reg sec_posedge, // 1 when second passes
    output reg timer_running, // timer countdown running flag
    output reg [6:0] timer, // game timer(0~127)
    output reg [2:0] state, // current state
    output reg [1:0] stage, // current stage
    output reg [1:0] lives, // current lives
    output reg [9:0] score // current score
);
localparam integer BASE_DURATION = 10'd1000; // 1 second = 1000 ms, 1ms = 1000 clk_1mhz cycles
localparam integer PLAY_DURATION = 7'd30; // default play duration = 60 seconds
localparam integer READY_DURATION = 7'd4; // ready duration = 4 seconds beep-beep-beep-go

// Notification pulse widths (in clk_1mhz cycles). Tune these to extend notification visibility.
// Removed pulse cycles as we use single cycle pulses now

reg [1:0] sync_trig;
reg [9:0] clk_cnt, mille_cnt;

// synchronize trigger signal (use synchronous reset to avoid ambiguous clock event)
always @(posedge clk_1mhz) begin
    if (rst || state == 3'b000) begin
        done <= 1'b0;
        sec_posedge <= 1'b0;
        timer_running <= 1'b0;
        timer <= 7'd0;
        state <= 3'b001; // ready
        stage <= 2'd1; // stage 1
        lives <= 2'd3; // 3 lives
        score <= 10'd0; // 0 score
        sync_trig <= 2'b00;
        clk_cnt <= 10'd0;
        mille_cnt <= 10'd0;
    end
    else begin
        // Default values for pulses
        done <= 1'b0;
        sec_posedge <= 1'b0;
        
        // synchronous reset: update synchronizer and rest of logic on clock
        sync_trig <= {sync_trig[0], trig};
        // triggered state change
        if (sync_trig[0] & ~sync_trig[1]) begin
            // state change logic
            case (flag)
                // increment score
                4'b0001: begin 
                    score <= score + 10'd1;
                end
                
                // decrement life
                4'b0010: begin 
                    if (lives > 0)
                        lives <= lives - 2'd1;
                end
                
                // pause timer countdown
                4'b0100: begin 
                    timer_running <= 1'b0;
                end
                
                // resume timer countdown
                4'b0101: begin 
                    timer_running <= 1'b1;
                end
                
                // to ready
                4'b1000: begin 
                    state <= 3'b001; // ready
                    // reset game parameters
                    timer <= READY_DURATION;
                    timer_running <= 1'b0; // start on btn pressed
                    
                    // Reset only if NOT coming from Stage Clear (3'b100)
                    if (state != 3'b100) begin
                        stage <= 2'd1; // reset stage
                        lives <= 2'd3; // reset lives
                        score <= 10'd0; // reset score
                    end
                end
                
                // to playing(from ready)
                4'b1010: begin 
                    state <= 3'b010; // playing
                    timer <= PLAY_DURATION;
                    timer_running <= 1'b1;
                end

                // to stage clear(from playing)
                4'b1100: begin
                    state <= 3'b100;
                    stage <= stage + 2'd1;
                    timer_running <= 1'b0;
                end
            
                4'b1101: begin 
                    // to game over(from playing)
                    state <= 3'b011;
                    timer_running <= 1'b0;
                end
            
                4'b1110: begin 
                    // to game clear(from playing)
                    state <= 3'b101;
                    timer_running <= 1'b0;
                end

                4'b1111: begin 
                    // reset to ready(from stage clear)
                    state <= 3'b001; // ready
                    timer <= READY_DURATION;
                    timer_running <= 1'b0;
                    stage <= 2'd1; // reset stage
                    lives <= 2'd3; // reset lives
                    score <= 10'd0; // reset score
                end
            endcase
            // pulse done signal
            done <= 1'b1;
        end

        // timer countdown logic
        if (timer_running) begin
            if (clk_cnt < BASE_DURATION - 1) begin
                clk_cnt <= clk_cnt + 10'd1;
            end else begin
                clk_cnt <= 10'd0;
                // 1 ms passed
                if (mille_cnt < 10'd999) begin
                    mille_cnt <= mille_cnt + 10'd1;
                end else begin
                    mille_cnt <= 10'd0;
                    if (timer > 0) begin
                        timer <= timer - 7'd1;
                        sec_posedge <= 1'b1;
                    end else begin
                        timer_running <= 1'b0; 
                    end
                end
            end
        end else begin
            clk_cnt <= 10'd0;
            mille_cnt <= 10'd0;
        end
    end
end
endmodule