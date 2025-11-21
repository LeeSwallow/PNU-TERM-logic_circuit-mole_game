module igm(
    input wire clk_1mhz,
    input wire rst,
    input wire enable,
    input wire [1:0] gsm_stage,
    output reg [3:0] mole_pos // which mole to show
);
localparam integer BASE_DURATION = 10'd1000; // 1 second = 1000 ms, 1ms = 1000 clk_1mhz cycles

wire [9:0] mole_dur;
wire [8:0] inter_limit;

// game difficulty signals (combinational wires)
assign mole_dur = (gsm_stage == 2'b01) ? 10'd1000 : // 1 second
                  (gsm_stage == 2'b10) ? 10'd750  : // 0.75 second
                  (gsm_stage == 2'b11) ? 10'd500  : // 0.5 second
                                         10'd1000; // default 1 second

assign inter_limit = (gsm_stage == 2'b01) ? 9'd500 : // 0.5 second
                     (gsm_stage == 2'b10) ? 9'd250 : // 0.25 second
                     (gsm_stage == 2'b11) ? 9'd200 : // 0.2 second
                                            9'd500; // default 0.5 second

reg [9:0] clk_cnt, mille_cnt;
wire [8:0] rand_val; // random value from rand_gen (driven by instance => wire)
reg [1:0] mole_state; // mole state internal(00: idle, 01: show, 10: hide)
reg [8:0] mole_interval; // mole interval timer

// set random generator
rand_gen rg_inst(
    .clk(clk_1mhz),
    .rst(rst),
    .rand_num(rand_val)
);

// in-game manager logic
always @(posedge clk_1mhz or posedge rst) begin
    if (rst) begin
        clk_cnt <= 10'd0;
        mille_cnt <= 10'd0;
        mole_pos <= 4'b0000;
        mole_state <= 2'b00;
        mole_interval <= 9'd0;
    end else if (!enable) begin
        // when game is disabled, keep everything cleared
        clk_cnt <= 10'd0;
        mille_cnt <= 10'd0;
        mole_pos <= 4'b0000;
        mole_state <= 2'b00;
        mole_interval <= 9'd0;
    end else begin
        if (mole_state == 2'b01) begin // show
            // timer for mole show duration (BASE_DURATION cycles -> 1 ms)
            if (clk_cnt < BASE_DURATION - 1) begin
                clk_cnt <= clk_cnt + 10'd1;
            end else begin
                clk_cnt <= 10'd0;
                if (mille_cnt < mole_dur - 1) begin
                    mille_cnt <= mille_cnt + 10'd1;
                end else begin
                    clk_cnt <= 10'd0;
                    mille_cnt <= 10'd0;
                    mole_interval <= (rand_val % inter_limit) + 9'd1; // set random interval (ms)
                    mole_pos <= 4'b0000; // hide mole
                    mole_state <= 2'b10; // move to hide state
                end
            end
        end else if (mole_state == 2'b10) begin // hide
            // timer for mole hide duration
            if (clk_cnt < BASE_DURATION - 1) begin
                clk_cnt <= clk_cnt + 10'd1;
            end else begin
                clk_cnt <= 10'd0;
                if (mille_cnt < mole_interval - 1) begin
                    mille_cnt <= mille_cnt + 10'd1;
                end else begin
                    clk_cnt <= 10'd0;
                    mille_cnt <= 10'd0;
                    mole_pos <= (rand_val % 8) + 4'b0001; // set random mole to show (1..8)
                    mole_state <= 2'b01; // move to show state
                end
            end

        end else begin // idle(enable & idle -> initialize mole show)
            clk_cnt <= 10'd0;
            mille_cnt <= 10'd0;
            mole_interval <= (rand_val % inter_limit) + 9'd1; // set random interval
            mole_pos <= (rand_val % 8) + 4'b0001; // show a mole
            mole_state <= 2'b01; // move to show state
        end
    end
end
endmodule