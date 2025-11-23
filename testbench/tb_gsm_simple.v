`timescale 1ns/1ps

// Simple testbench for game_state_manager (gsm)
// Applies flags with trig pulses and prints key outputs.

module tb_gsm_simple;
    reg clk_1mhz;
    reg rst;
    reg [3:0] flag;
    reg trig;

    wire done;
    wire sec_posedge;
    wire timer_running;
    wire [6:0] timer;
    wire [2:0] state;
    wire [1:0] stage;
    wire [1:0] lives;
    wire [9:0] score;

    // instantiate DUT
    gsm uut (
        .clk_1mhz(clk_1mhz),
        .rst(rst),
        .flag(flag),
        .trig(trig),
        .done(done),
        .sec_posedge(sec_posedge),
        .timer_running(timer_running),
        .timer(timer),
        .state(state),
        .stage(stage),
        .lives(lives),
        .score(score)
    );

    // clock: 1 MHz -> 1 us period -> toggle every 500 ns
    initial begin
        clk_1mhz = 0;
        forever #5 clk_1mhz = ~clk_1mhz; // using small delay for fast sim (period=10ns)
    end

    initial begin
        // init
        rst = 1; flag = 4'b0000; trig = 0;
        #10; rst = 0;
        
        // 1) increment score
        #10; flag = 4'b0001; trig = 1; 
        #20; trig = 0;

        // 2) decrement life
        #100; flag = 4'b0010; trig = 1; 
        #20; trig = 0;

        // 3) pause timer
        #100; flag = 4'b0100; trig = 1; 
        #20; trig = 0;

        // 4) resume timer
        #100; flag = 4'b0101; trig = 1; 
        #20; trig = 0;

        // 5) to ready
        #100; flag = 4'b1000; trig = 1; 
        #20; trig = 0;

        // 6) to playing
        #100; flag = 4'b1010; trig = 1; 
        #20; trig = 0;

        // 7) to stage clear
        #100; flag = 4'b1100; trig = 1; 
        #20; trig = 0;

        // 8) to game over
        #100; flag = 4'b1101; trig = 1; 
        #20; trig = 0;

        // 9) to game clear
        #100; flag = 4'b1110; trig = 1; 
        #20; trig = 0;

        // 10) reset to ready
        #100; flag = 4'b1111; trig = 1; 
        #20; trig = 0;

        #10 $finish;
    end
endmodule
