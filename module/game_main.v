module gm(
    input wire clk_1mhz, input wire rst,
    input wire [10:0] btn_in, // button inputs
    output wire piezo_out, // piezo output
    output wire [7:0] led_out, // LED outputs
    output wire [7:0] seg_out, // 7-segment display output
    output wire [7:0] seg_arr_out, // 7-segment display outputs
    output wire [7:0] seg_sel_out, // 7-segment array digit select outputs
    output wire servo_out, // servo output,
    output wire [3:0] led_red_out,
    output wire [3:0] led_green_out,
    output wire [3:0] led_blue_out,
    output wire [7:0] lcd_data,
    output wire lcd_rs,
    output wire lcd_rw,
    output wire lcd_en
);

/*
===============================================================================
instantiate game state manager
===============================================================================
*/
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
wire [6:0] gsm_base_score;
wire [9:0] gsm_high_score;
wire gsm_high_score_updated;
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
    .score(gsm_score),
    .base_score(gsm_base_score),
    .high_score(gsm_high_score),
    .high_score_updated(gsm_high_score_updated)
);
/*
===============================================================================
instantiate in-game manager
===============================================================================
*/
wire [3:0] igm_mole_pos1;
wire [3:0] igm_mole_pos2;
wire igm_enable;
assign igm_enable = ((gsm_state == 3'b010) && gsm_timer_running); // enable when playing and timer running
igm igm_inst1(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .enable(igm_enable), // enable when playing
    .seed(9'd123), // fixed seed for first mole
    .gsm_stage(gsm_stage),
    .mole_pos(igm_mole_pos1)
);

igm igm_inst2(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .enable(igm_enable), // enable when playing
    .seed(9'd456), // fixed seed for second mole
    .gsm_stage(gsm_stage),
    .mole_pos(igm_mole_pos2)
);

/*
===============================================================================
instantiate sound manager
===============================================================================
*/
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

/*
===============================================================================
instantiate button input module
===============================================================================
*/
wire btn_pressed;
wire [3:0] btn_value;
key_button_input kbi_inst(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .key_button_in(btn_in),
    .button_pressed(btn_pressed),
    .button_value(btn_value)
);

/*
===============================================================================
instantiate LED output module
===============================================================================
*/
leds_output leds_inst(
    .mole_pos1(igm_mole_pos1),
    .mole_pos2(igm_mole_pos2),
    .leds(led_out)
);
/*
===============================================================================
instantiate bin to 7-segment display module
===============================================================================
*/
seg_output seg_single_inst(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .lives(gsm_lives),
    .seg_out(seg_out)
);

/*
===============================================================================
instantiate bin to 7-segment 8 array display module
===============================================================================
*/
seg_arr_output seg_inst(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .base_score(gsm_base_score), // 0~10
    .score(gsm_score),
    .seg_out(seg_arr_out),
    .array_out(seg_sel_out)
);

/*
===============================================================================
instanciate servo output module
===============================================================================
*/

servo_output servo_inst(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .enable(igm_enable), // enable when playing
    .timer(gsm_timer),
    .servo_out(servo_out)
);

/*
===============================================================================
instanciate rgb led output module
===============================================================================
*/
rgb_led_output rgb_led_inst(
    .clk(clk_1mhz),
    .rst(rst),
    .state(gsm_state),
    .timer_running(gsm_timer_running),
    .timer(gsm_timer),
    .led_red(led_red_out),
    .led_green(led_green_out),
    .led_blue(led_blue_out)
);

/*
===============================================================================
instantiate text LCD output module
*/

text_lcd_output lcd_inst(
    .clk_1mhz(clk_1mhz),
    .rst(rst),
    .gsm_state(gsm_state),
    .gsm_stage(gsm_stage),
    .gsm_high_score(gsm_high_score),
    .gsm_high_score_updated(gsm_high_score_updated),
    .lcd_rs(lcd_rs),
    .lcd_rw(lcd_rw),
    .lcd_en(lcd_en),
    .lcd_data(lcd_data)
);


/*
===============================================================================
*/

/*
===============================================================================
implement game main FSM
===============================================================================
*/
reg [1:0] snd_sync, btn_sync, gsm_timer_sync, gsm_sec_sync;
reg ready_btn_clicked, state_sound_played;

always @(posedge clk_1mhz or posedge rst) begin
    if (rst) begin
        gsm_trig <= 1'b0;
        gsm_flag <= 4'd0;
        snd_trig <= 1'b0;
        snd_mode <= 3'd0;
        snd_sync <= 2'd0;
        btn_sync <= 2'd0;
        gsm_timer_sync <= 2'd0;
        gsm_sec_sync <= 2'd0;
        ready_btn_clicked <= 1'b0;
        state_sound_played <= 1'b0;
    end else begin
        // synchronize signals
        gsm_timer_sync <= {gsm_timer_sync[0], gsm_timer_running};
        snd_sync <= {snd_sync[0], snd_playing};
        btn_sync <= {btn_sync[0], btn_pressed};
        gsm_sec_sync <= {gsm_sec_sync[0], gsm_sec_posedge};
        
        // ready state
        if (gsm_state == 3'b001) begin
            gsm_trig <= 1'b0;
            snd_trig <= 1'b0;

            if ((btn_sync == 2'b01) && (btn_value == 4'd10)) begin // start button pressed
                gsm_flag <= 4'b0101; // resume timer
                gsm_trig <= 1'b1;
                ready_btn_clicked <= 1'b1;
            end 

            if (ready_btn_clicked) begin
                if (gsm_sec_sync == 2'b01 && !snd_playing) begin // every second, only if sound idle
                    if (gsm_timer == 7'd0) begin
                        snd_mode <= 3'b010; // start beep (last second)
                        snd_trig <= 1'b1;
                    end else begin
                        snd_mode <= 3'b001; // normal countdown beep
                        snd_trig <= 1'b1;
                    end
                end
                if (gsm_timer_sync == 2'b10) begin // timer stopped by zero(negative edge)
                    gsm_flag <= 4'b1010; // to playing
                    gsm_trig <= 1'b1;
                end
            end
        end
        
        // playing state    
        else if (gsm_state == 3'b010) begin
            gsm_trig <= 1'b0;
            snd_trig <= 1'b0;
            ready_btn_clicked <= 1'b0;
            state_sound_played <= 1'b0;
            
            if (gsm_lives != 2'd0) begin
                if (btn_sync == 2'b01) begin // button pressed(1~8)
                    if ((btn_value >= 4'd1) && (btn_value <= 4'd8)) begin
                        if ((igm_mole_pos1 == btn_value) || (igm_mole_pos2 == btn_value)) begin // hit
                            gsm_flag <= 4'b0001; // increment score
                            gsm_trig <= 1'b1;
                            snd_mode <= 3'b011; // hit sound
                            snd_trig <= 1'b1;
                        end else begin // miss
                            gsm_flag <= 4'b0010; // decrement life
                            gsm_trig <= 1'b1;
                            snd_mode <= 3'b100; // miss sound
                            snd_trig <= 1'b1;
                        end
                    end
                end
                if (gsm_timer_sync == 2'b10) begin // timer stopped by zero(negative edge)
                    if (gsm_base_score > 7'd0) begin
                        gsm_flag <= 4'b1101; // to game over
                    end else if (gsm_stage < 2'd3) begin
                        gsm_flag <= 4'b1100; // to stage clear
                    end else begin
                        gsm_flag <= 4'b1110; // to game clear
                    end
                    gsm_trig <= 1'b1;
                end
            end else begin
                // if lives reach zero stage end
                if (!gsm_done) begin
                    if (gsm_base_score > 7'd0) begin
                        gsm_flag <= 4'b1101; // to game over
                    end else if (gsm_stage < 2'd3) begin
                        gsm_flag <= 4'b1100; // to stage clear
                    end else begin
                        gsm_flag <= 4'b1110; // to game clear
                    end
                    gsm_trig <= 1'b1;
                end
            end
        end

        // game over state
        else if (gsm_state == 3'b011) begin
            gsm_trig <= 1'b0;
            snd_trig <= 1'b0;
            if (!snd_playing && !state_sound_played) begin
                snd_mode <= 3'b110; // game over sound
                snd_trig <= 1'b1;
                state_sound_played <= 1'b1; // ensure sound played only once
            end
            if (btn_sync == 2'b01 && (btn_value == 4'd10)) begin // start button pressed
                gsm_flag <= 4'b1111; // reset to ready
                gsm_trig <= 1'b1;
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
            if (!snd_playing && !state_sound_played) begin
                snd_mode <= 3'b111; // game clear sound
                snd_trig <= 1'b1;
                state_sound_played <= 1'b1; // ensure sound played only once
            end
            
            if (btn_sync == 2'b01 && (btn_value == 4'd10)) begin // start button pressed
                gsm_flag <= 4'b1111; // reset to ready
                gsm_trig <= 1'b1;
            end
        end
    end
end
endmodule
/*
===============================================================================
*/