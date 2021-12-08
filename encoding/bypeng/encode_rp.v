/*
    NTRU Prime General R/q[x] / x^p - x - 1 Encoder

    Author: Bo-Yuan Peng, bypeng@crypto.tw

    Version:

*/

`include "params.v"

module encode_rp ( clk, start, done, state_l, state_s,
    rp_rd_addr, rp_rd_data,
    cd_wr_addr, cd_wr_data, cd_wr_en,
    state_max,
    param_r_max, param_m0, param_1st_round,
    param_outs1, param_outsl
) ; 

    input                           clk;
    input                           start;
    output                          done;
    output      [4:0]               state_l;
    output      [4:0]               state_s;

    output      [`RP_DEPTH-1:0]     rp_rd_addr;
    input       [`RP_D_SIZE-1:0]    rp_rd_data;
    output reg  [`OUT_DEPTH-1:0]    cd_wr_addr;
    output      [`OUT_D_SIZE-1:0]   cd_wr_data;
    output                          cd_wr_en;

    input       [4:0]               state_max;

    input       [`RP_DEPTH-1:0]     param_r_max;
    input       [`RP_D_SIZE-1:0]    param_m0;
    input                           param_1st_round;
    input       [2:0]               param_outs1;
    input       [2:0]               param_outsl;

    wire                            rb_wr_en;
    reg         [`RP_DEPTH-2:0]     rb_wr_addr;
    wire        [`RP_D_SIZE-1:0]    rb_wr_data;
    wire        [`RP_D_SIZE-1:0]    rb_wr_rd_data;
    wire        [`RP_DEPTH-2:0]     rb_rd_addr;
    wire        [`RP_D_SIZE-1:0]    rb_rd_data;
    wire        [`RP_D_SIZE-1:0]    rb_rd_data_out;
    
    reg                             rb_wr_through;
    
    reg         [4:0]               state[4:0];
    wire        [4:0]               state_l1;
    wire        [4:0]               state_s1;
    reg         [4:0]               state_next;
    reg         [1:0]               state_counter[3:0];

    reg         [`RP_D_SIZE-1:0]    r0[2:0];
    reg         [`RP_D_SIZE-1:0]    r1[1:0];

    wire        [`RP_D_SIZE-1:0]    r0_l;
    wire        [`RP_D_SIZE-1:0]    r1_l;
    wire        [`RP_D_SIZE-1:0]    r0_s;
    wire        [`RP_D_SIZE-1:0]    r1_s;
    wire        [1:0]               sc_l;
    wire        [1:0]               sc_s;


    wire        [`RP_D_SIZE2-1:0]   r1m0_r0;
    reg         [`RP_D_SIZE2-1:0]   r_next;

    reg         [2:0]               starts;

    reg         [2:0]               out_counter;

    wire                            r_m0m1_next;
    reg         [3:0]               r_m0m1;
    wire                            rl_s;

    reg         [`RP_DEPTH-1:0]     r_rd_addr;
    wire        [`RP_DEPTH-1:0]     r_rd_diff;
    wire                            r_rd_end;
    wire        [`RP_D_SIZE-1:0]    r_data;
    reg         [`OUT_DEPTH-1:0]    o_addr;
    wire        [`OUT_D_SIZE-1:0]   o_data;

    bram_n # ( .D_SIZE(`RP_D_SIZE), .Q_DEPTH(`RP_DEPTH-1) ) r_buffer (
        .clk(clk),
        .wr_en(rb_wr_en),
        .wr_addr(rb_wr_addr),
        .wr_din(rb_wr_data),
        .wr_dout(rb_wr_rd_data),
        .rd_addr(rb_rd_addr),
        .rd_dout(rb_rd_data_out)
    ) ;

    always @(negedge clk) begin
    	if(rb_wr_en == 1'b1 && rb_wr_addr == rb_rd_addr ) begin
    		rb_wr_through <= 1'b1;
    	end else begin
    		rb_wr_through <= 1'b0;
    	end
    end
    
    assign rb_rd_data = (rb_wr_through) ? rb_wr_rd_data : rb_rd_data_out;
    //assign rb_rd_data = rb_rd_data_out;
    
    always @ ( posedge clk ) begin
        if(start) begin
            state[4] <= 5'd0;
            state[3] <= 5'd0;
            state[2] <= 5'd0;
            state[1] <= 5'd0;
            state[0] <= 5'd0;
        end else begin
            state[4] <= state_next;
            state[3] <= state[4];
            state[2] <= state[3];
            state[1] <= state[2];
            state[0] <= state[1];
        end
    end
    assign state_l = state[4];
    assign state_l1 = state[3];
    assign state_s = state[1];
    assign state_s1 = state[0];

    assign done = (state_l == 5'd31);

    always @ (*) begin
        if( r_rd_end && ~|sc_l ) begin
            if(state_l == state_max || done) begin
                state_next = 5'd31;
            end else begin
                state_next = state_l + 5'd1;
            end
        end else begin
            state_next = state_l;
        end
    end

    always @ ( posedge clk ) begin
        if(start || ~|(state_counter[3])) begin
            state_counter[3] <= 2'd2;
        end else begin
            state_counter[3] <= state_counter[3] - 2'd1;
        end
        if(start) begin
            state_counter[2] <= 2'd2;
            state_counter[1] <= 2'd2;
            state_counter[0] <= 2'd2;
        end else begin
            state_counter[2] <= state_counter[3];
            state_counter[1] <= state_counter[2];
            state_counter[0] <= state_counter[1];
        end
    end
    assign sc_l = state_counter[3];
    assign sc_s = state_counter[0];

    assign rb_rd_addr = r_rd_addr[0 +: `RP_DEPTH_2];
    assign rp_rd_addr = r_rd_addr;
    assign r_data = param_1st_round ? rp_rd_data : rb_rd_data; 

    assign r_rd_diff = param_r_max - r_rd_addr;
    assign r_rd_end = ~|r_rd_diff;

    always @ ( posedge clk ) begin
        if(start) begin
            r_rd_addr <= { `RP_DEPTH {1'b0} };
        end else begin
            if(r_rd_end) begin
                if(~|sc_l) begin
                    r_rd_addr <= { `RP_DEPTH {1'b0} };
                end
            end else begin
                if(|sc_l) begin
                    r_rd_addr <= r_rd_addr + { { `RP_DEPTH_2 {1'b0} }, 1'b1 };
                end
            end
        end
    end

    always @ ( posedge clk ) begin
        if(start) begin
            r0[2] <= { `RP_D_SIZE {1'b0} };
            r0[1] <= { `RP_D_SIZE {1'b0} };
            r0[0] <= { `RP_D_SIZE {1'b0} };
            r1[1] <= { `RP_D_SIZE {1'b0} };
            r1[0] <= { `RP_D_SIZE {1'b0} };
        end else begin
            if(sc_l == 2'd2 && ~&state_s) begin
                r0[2] <= r_data;
            end
            r0[1] <= r0[2];
            r0[0] <= r0[1];
            if(sc_l == 2'd1) begin
                r1[1] <= (~r_rd_end || ~param_r_max[0]) ? r_data : { `RP_D_SIZE {1'b0} };
            end
            r1[0] <= r1[1];
        end
    end
    assign r0_l = r0[2];
    assign r0_s = r0[0];
    assign r1_l = r1[1];
    assign r1_s = r1[0];

    assign r1m0_r0 = r1_s * param_m0 + r0_s;

    always @ ( posedge clk ) begin
        if(start) begin
            r_next <= { `RP_D_SIZE2 {1'b0} };
        end else begin
            if(sc_s == 2'd2 && ~&state_s) begin
                r_next <= r1m0_r0;
            end else begin
                r_next <= { 8'b0, r_next[8 +: (`RP_D_SIZE2 - 8)] };
            end
        end
    end

    assign r_m0m1_next = param_r_max[0] ? ~|r_rd_diff[1 +: (`RP_DEPTH-1)] : (~|r_rd_diff[2 +: (`RP_DEPTH-2)] && ~&r_rd_diff[1:0]) ;

    always @ ( posedge clk ) begin
        if(start) begin
            r_m0m1 <= 4'b0;
        end else begin
            r_m0m1[2] <= r_m0m1_next;
            r_m0m1[1] <= r_m0m1[2];
            r_m0m1[0] <= r_m0m1[1];
        end
    end
    assign rl_s = r_m0m1[0];

    always @ ( posedge clk ) begin
        starts <= { start, starts[2:1] };
    end

    always @ ( posedge clk ) begin
        if(starts[0]) begin
            out_counter <= 3'd6;
        end else begin
            if(sc_s == 2'd2 && ~&state_s) begin
                out_counter <= rl_s ? param_outsl : param_outs1;
            end else begin
                if(~out_counter[2] || &out_counter) begin
                    out_counter <= out_counter - 3'd1;
                end
            end
        end
    end

    assign cd_wr_en = ~out_counter[2];
    assign cd_wr_data = r_next[7:0];
    always @ ( posedge clk ) begin
        if(start) begin
            cd_wr_addr <= { `OUT_DEPTH { 1'b0 } };
        end else begin
            if(cd_wr_en) begin
                cd_wr_addr <= cd_wr_addr + { { (`OUT_DEPTH - 1) {1'b0} }, 1'b1 };
            end
        end
    end

    assign rb_wr_en = &out_counter;
    assign rb_wr_data = r_next[13:0];

    always @ ( posedge clk ) begin
        if(start) begin
            rb_wr_addr <= { (`RP_DEPTH-1) { 1'b0 } };
        end else begin
            if(rb_wr_en) begin
                if(state_l1 != state_s1) begin
                    rb_wr_addr <= { (`RP_DEPTH-1) { 1'b0 } };
                end else begin 
                    rb_wr_addr <= rb_wr_addr + { { (`RP_DEPTH - 2) {1'b0} }, 1'b1 };
                end
            end
        end
    end

endmodule
