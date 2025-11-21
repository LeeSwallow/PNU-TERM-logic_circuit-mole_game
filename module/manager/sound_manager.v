module sndm(
    input wire clk_1mhz,
    input wire rst,
    input wire [2:0] snd_mode, // sound mode
    input wire trig, // sound trigger
    output reg playing,
    output wire piezo_out // piezo output
);

wire [3:0] buzzer_mode;

// piezo output instance
peizo_output peizo_inst(
    .clk_1MHz(clk_1mhz),
    .rst(rst),
    .mode(buzzer_mode),
    .piezo_out(piezo_out)
);

// sound timing
// For 1 MHz clock, 200 ms = 200_000 cycles. Use BASE_CYCLES for full-note duration.
localparam integer BASE_CYCLES = 18'd200000; // 200 ms @ 1 MHz

// sound mode table (standard Verilog array declaration)
wire [3:0] snd_table [0:6]; // 7 entries, each 4-bit

assign snd_table[0] = (snd_mode == 3'b001) ? 4'b0010 : // D4(beep[0])
                      (snd_mode == 3'b010) ? 4'b1000 : // C5(start[0])
                      (snd_mode == 3'b011) ? 4'b0001 : // C4(hit[0])
                      (snd_mode == 3'b100) ? 4'b0011 : // E4(miss[0])
                      (snd_mode == 3'b101) ? 4'b0001 : // C4(win[0])
                      (snd_mode == 3'b110) ? 4'b1000 : // C5(gameover[0])
                      (snd_mode == 3'b111) ? 4'b0111 : // C4(gameclear[0])
                                              4'b1111; // end(idle[0])

assign snd_table[1] = (snd_mode == 3'b011) ? 4'b0101 : // G4(hit[1])
                      (snd_mode == 3'b100) ? 4'b0000 : // no sound(miss[1])
                      (snd_mode == 3'b101) ? 4'b0011 : // E4(win[1])
                      (snd_mode == 3'b110) ? 4'b0101 : // G4(gameover[1])
                      (snd_mode == 3'b111) ? 4'b0011 : // E4(gameclear[1])
                                              4'b1111; // end(else[1])

assign snd_table[2] = (snd_mode == 3'b100) ? 4'b0011 : // E4(miss[2])
                      (snd_mode == 3'b101) ? 4'b0101 : // G4(win[2])
                      (snd_mode == 3'b110) ? 4'b0011 : // E4(gameover[2])
                      (snd_mode == 3'b111) ? 4'b0101 : // G4(gameclear[2])
                                              4'b1111; // end(else[2])   

assign snd_table[3] = (snd_mode == 3'b101) ? 4'b1000 : // C5(win[3])
                      (snd_mode == 3'b110) ? 4'b0001 : // C4(gameover[3])
                      (snd_mode == 3'b111) ? 4'b0000 : // no sound(gameclear[3])
                                              4'b1111; // end(else[3])

assign snd_table[4] = (snd_mode == 3'b111) ? 4'b0010 : // F4(gameclear[4])
                                              4'b1111; // end(else[4])

assign snd_table[5] = (snd_mode == 3'b111) ? 4'b0100 : // A4(gameclear[5])
                                              4'b1111; // end(else[5])

assign snd_table[6] = (snd_mode == 3'b111) ? 4'b1000 : // C5(gameclear[6])
                                              4'b1111; // end(else[6])

// buzzer_mode drives peizo mode while playing; silence on sentinel or when not playing
assign buzzer_mode = (playing && (snd_table[snd_idx] != 4'b1111)) ? snd_table[snd_idx] : 4'b0000;


reg [17:0] clk_cnt; // enough to count up to BASE_CYCLES
reg [2:0] snd_idx; // sound index

reg [1:0] sync_trig;

// sound manager logic
always @(posedge clk_1mhz or posedge rst) begin
    if (rst) begin
        clk_cnt <= 18'd0;
        snd_idx <= 3'd0;
        playing <= 1'b0;
        sync_trig <= 2'b00;
    end else begin
        sync_trig <= {sync_trig[0], trig};

        // triggered sound play
        if (sync_trig[0] & ~sync_trig[1]) begin
            // restart playback immediately when trigger arrives
            playing <= 1'b1;
            snd_idx <= 3'd0;
            clk_cnt <= 18'd0;
        end
        // sound playing logic (skip this cycle if we just restarted)
        else if (playing) begin
            if (clk_cnt < BASE_CYCLES - 1) begin
                clk_cnt <= clk_cnt + 18'd1;
            end else begin
                clk_cnt <= 18'd0;

                // move to next sound in table: if next entry exists and is not sentinel, advance
                if ((snd_idx < 3'd6) && (snd_table[snd_idx + 3'd1] != 4'b1111)) begin
                    snd_idx <= snd_idx + 3'd1;
                end else begin
                    // end of sound table or next is sentinel -> stop playing
                    playing <= 1'b0;
                    snd_idx <= 3'd0;
                end
            end
        end else begin
            clk_cnt <= 18'd0;
            snd_idx <= 3'd0;
        end
    end
end
endmodule