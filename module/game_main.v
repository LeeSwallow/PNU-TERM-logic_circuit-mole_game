module gm(
    input wire clk_1mhz, input wire rst,
    input wire [10:0] btn_in, // button inputs
    output wire piezo_out, // piezo output
    output wire [7:0] led_out // LED outputs
);

// game state manager signals
reg gsm_trig;
reg[3:0] gsm_flag;
wire gsm_done;
wire gsm_sec_posedge;
wire gsm_timer_running;
wire [6:0] gsm_timer;
wire [2:0] gsm_state;
wire [1:0] gsm_stage;
wire [1:0] gsm_lives;
wire [9:0] gsm_score;
gsm gsm_inst(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .flag(gsm_flag),
    .trig(gsm_trig),
    .done(gsm_done),
    .sec_posedge(gsm_sec_posedge),
    .timer_running(gsm_timer_running),
    .timer(gsm_timer),
    .state(gsm_state),
    .stage(gsm_stage),
    .lives(gsm_lives),
    .score(gsm_score)
);

// in-game manager signals
wire [3:0] igm_mole_pos;
wire igm_enable;
assign igm_enable = ((gsm_state == 3'd1) && gsm_timer_running); // enable when playing and timer running
igm igm_inst(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .enable(igm_enable), // enable when playing
    .gsm_stage(gsm_stage),
    .mole_pos(igm_mole_pos)
);

// instantiate sound manager
wire snd_playing;
reg snd_trig;
reg [2:0] snd_mode;
sndm sndm_inst(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .snd_mode(snd_mode),
    .trig(snd_trig),
    .playing(snd_playing),
    .piezo_out(piezo_out)
);

// key button input signals
wire btn_pressed;
wire [3:0] btn_value;
key_button_input kbi_inst(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .key_button_in(btn_in),
    .button_pressed(btn_pressed),
    .button_value(btn_value)
);

reg [1:0] gsm_sync, snd_sync, btn_sync, gsm_timer_sync;
reg ready_btn_clicked;

// main game logic
always @(posedge clk_1mhz) begin
    if (rst) begin
        gsm_trig <= 1'b0;
        gsm_flag <= 4'd0;
        snd_trig <= 1'b0;
        snd_mode <= 3'd0;
        gsm_sync <= 2'd0;
        snd_sync <= 2'd0;
        btn_sync <= 2'd0;
        gsm_timer_sync <= 2'd0;
        ready_btn_clicked <= 1'b0;
    end else begin
        // synchronize signals
        gsm_sync <= {gsm_sync[0], gsm_done};
        gsm_timer_sync <= {gsm_timer_sync[0], gsm_timer_running};
        snd_sync <= {snd_sync[0], snd_playing};
        btn_sync <= {btn_sync[0], btn_pressed};
        
        // ready state
        if (gsm_state == 3'b000) begin
            gsm_trig <= 1'b0;
            snd_trig <= 1'b0;

            if ((btn_sync == 2'b01) && (btn_value == 4'd10)) begin // start button pressed
                gsm_flag <= 4'b0101; // resume timer
                gsm_trig <= 1'b1;
                ready_btn_clicked <= 1'b1;
            end 

            if (ready_btn_clicked) begin
                if (gsm_sec_posedge) begin // every second
                    if (gsm_timer == 7'd1) begin
                        snd_mode <= 3'b010; // start beep
                        snd_trig <= 1'b1;
                    end else begin
                        snd_mode <= 3'b010; // no sound
                        snd_trig <= 1'b1;
                    end
                end
                
                if (gsm_timer_sync == 2'b10) begin // timer stopped by zero(negative edge)
                    gsm_flag <= 4'b1000; // to ready
                    gsm_trig <= 1'b1;
                end
            end
        end
        
        // playing state    
        else if (gsm_state == 3'b001) begin
            gsm_trig <= 1'b0;
            snd_trig <= 1'b0;
            ready_btn_clicked <= 1'b0;
            
            if (gsm_lives == 2'd0) begin
                gsm_flag <= 4'b1101; // to game over
                gsm_trig <= 1'b1;
            end
            if (btn_sync == 2'b01) begin // button pressed(1~8)
                if ((btn_value >= 4'd1) && (btn_value <= 4'd8)) begin
                    if (igm_mole_pos == btn_value) begin // hit
                        gsm_flag <= 4'b0001; // increment score
                        gsm_trig <= 1'b1;
                        snd_mode <= 3'b001; // hit sound
                        snd_trig <= 1'b1;
                    end else begin // miss
                        gsm_flag <= 4'b0010; // decrement life
                        gsm_trig <= 1'b1;
                        snd_mode <= 3'b011; // miss sound
                        snd_trig <= 1'b1;
                    end
                end
            end
            if (gsm_timer_sync == 2'b10) begin // timer stopped by zero(negative edge)
                if (gsm_stage < 2'd3) begin
                    gsm_flag <= 4'b1100; // to stage clear
                end else begin
                    gsm_flag <= 4'b1110; // to game over
                end
                gsm_trig <= 1'b1;
            end
        end

        // game over state
        else if (gsm_state == 3'b011) begin
            gsm_trig <= 1'b0;
            snd_trig <= 1'b0;
            if (!snd_playing) begin
                if (snd_mode != 3'b110) begin
                    snd_mode <= 3'b110; // game over sound
                    snd_trig <= 1'b1;
                end else begin
                    gsm_flag <= 4'b1000; // to ready
                    gsm_trig <= 1'b1;
                end
            end
        end

        // stage clear state
        else if (gsm_state == 3'b100) begin
            gsm_trig <= 1'b0;
            snd_trig <= 1'b0;
            if (!snd_playing) begin
                if (snd_mode != 3'b101) begin
                    snd_mode <= 3'b101; // stage clear sound
                    snd_trig <= 1'b1;
                end else begin
                    gsm_flag <= 4'b1000; // to ready
                    gsm_trig <= 1'b1;
                end
            end
        end

        // game clear state
        else if (gsm_state == 3'b101) begin
            gsm_trig <= 1'b0;
            snd_trig <= 1'b0;
            if (!snd_playing) begin
                if (snd_mode != 3'b111) begin
                    snd_mode <= 3'b111; // game clear sound
                    snd_trig <= 1'b1;
                end else begin
                    gsm_flag <= 4'b1000; // to ready
                    gsm_trig <= 1'b1;
                end
            end
        end
    end
end
endmodule