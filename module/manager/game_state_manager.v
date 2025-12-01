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
    output reg [9:0] score, // current score
    output reg [6:0] base_score, // base score for current stage
    output reg [9:0] high_score, // high score ever achieved
    output reg high_score_updated // high score updated flag
);
localparam integer BASE_DURATION = 10'd1000;
localparam integer BASE_SCORE = 7'd30; 
localparam integer PLAY_DURATION = 7'd60; 
localparam integer READY_DURATION = 7'd4; 

reg [1:0] sync_trig;
reg [9:0] clk_cnt, mille_cnt;

always @(posedge clk_1mhz) begin
    if (rst || state == 3'b000) begin
        done <= 1'b0;
        sec_posedge <= 1'b0;
        timer_running <= 1'b0;
        timer <= READY_DURATION;
        state <= 3'b001; // ready
        stage <= 2'd1; // stage 1
        lives <= 2'd3; // 3 lives
        base_score <= BASE_SCORE; // base score
        score <= 10'd0; // 0 score
        high_score <= 10'd0; // 0 high score
        high_score_updated <= 1'b0; // high score updated flag
        sync_trig <= 2'b00;
        clk_cnt <= 10'd0;
        mille_cnt <= 10'd0;
    end
    else begin
        done <= 1'b0;
        sec_posedge <= 1'b0;
        sync_trig <= {sync_trig[0], trig};

        // on rising edge of trig
        if (sync_trig[0] & ~sync_trig[1]) begin

            case (flag)
                // in-game updates
                4'b0001: begin 
                    score <= score + 10'd1; 
                    if (base_score > 0) begin
                        base_score <= base_score - 7'd1;
                    end
                end // score increment
                4'b0010: begin if (lives > 0) lives <= lives - 2'd1; end // life decrement
                4'b0100: begin timer_running <= 1'b0; end // pause timer countdown
                4'b0101: begin timer_running <= 1'b1; end // resume timer countdown

                // state transitions
                4'b1000: begin  // to ready
                    state <= 3'b001; 
                    timer <= READY_DURATION;
                    timer_running <= 1'b0; 
                    lives <= 2'd3; // reset lives
                    base_score <= BASE_SCORE; // reset base score
                    high_score_updated <= 1'b0;
                end
                // to playing(from ready)                
                4'b1010: begin 
                    state <= 3'b010; // playing
                    timer <= PLAY_DURATION;
                    timer_running <= 1'b1;
                    high_score_updated <= 1'b0;
                end
                // to stage clear(from playing)
                4'b1100: begin
                    state <= 3'b100;
                    stage <= stage + 2'd1;
                    timer_running <= 1'b0;
                    high_score_updated <= 1'b0;
                end
                // to game over(from playing)
                4'b1101: begin 
                    state <= 3'b011;
                    timer_running <= 1'b0;
                    if (score > high_score) begin
                        high_score <= score; // update high score
                        high_score_updated <= 1'b1;
                    end
                end
                // to game clear(from playing)
                4'b1110: begin 
                    state <= 3'b101;
                    timer_running <= 1'b0;
                    if (score > high_score) begin
                        high_score <= score; // update high score
                        high_score_updated <= 1'b1;
                    end
                end
                // reset to ready(from stage clear)
                4'b1111: begin 
                    state <= 3'b001; // ready
                    timer <= READY_DURATION;
                    timer_running <= 1'b0;
                    stage <= 2'd1; // reset stage
                    lives <= 2'd3; // reset lives
                    score <= 10'd0; // reset score
                    base_score <= BASE_SCORE; // reset base score
                    high_score_updated <= 1'b0;
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