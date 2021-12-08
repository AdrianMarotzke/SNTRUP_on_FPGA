/*
    NTRU Prime General R/q[x] / x^p - x - 1 Decoder

    Author: Bo-Yuan Peng, bypeng@crypto.tw

    Version:

*/

`include "params.v"

module decode_rp ( clk, start, done,
    rp_rd_addr, rp_rd_data,
    cd_wr_addr, cd_wr_data, cd_wr_en,

    state_l, state_e, state_s,
    state_max, param_r_max, param_ro_max, param_small_r2,

    param_state_ct,
    param_ri_offset, param_ri_len,
    param_outoffset, param_outs1, param_outsl, 
    param_m0, param_m0inv,
    param_ro_offset
) ; 

    input                           clk;
    input                           start;
    output                          done;
    output      [`OUT_DEPTH-1:0]    rp_rd_addr;
    input       [`OUT_D_SIZE-1:0]   rp_rd_data;
    output      [`RP_DEPTH-1:0]     cd_wr_addr;
    output      [`RP_D_SIZE-1:0]    cd_wr_data;
    output                          cd_wr_en;

    output      [4:0]               state_l;
    output      [4:0]               state_e;
    output      [4:0]               state_s;

    input       [4:0]               state_max;
    input       [`RP_DEPTH-2:0]     param_r_max;
    input       [`RP_DEPTH-1:0]     param_ro_max;
    input                           param_small_r2;

    input       [10:0]              param_state_ct;
    input       [`RP_DEPTH-2:0]     param_ri_offset;
    input       [`RP_DEPTH-2:0]     param_ri_len;
    input       [`OUT_DEPTH-1:0]    param_outoffset;
    input       [1:0]               param_outs1;
    input       [1:0]               param_outsl;
    input       [`RP_D_SIZE-1:0]    param_m0;
    input       [`RP_INV_SIZE-1:0]  param_m0inv;
    input       [`RP_DEPTH-2:0]     param_ro_offset;

    reg                             rb_wr_en;
    wire        [`RP_DEPTH-2:0]     rb_wr_addr;
    wire        [`RP_D_SIZE-1:0]    rb_wr_data;
    wire        [`RP_D_SIZE-1:0]    rb_wr_rd_data;
    wire        [`RP_DEPTH-2:0]     rb_rd_addr;
    wire        [`RP_D_SIZE-1:0]    rb_rd_data;
    wire        [`RP_D_SIZE-1:0]    rb_rd_data_out;
    
    reg                             rb_wr_through;

    reg         [4:0]               state[6:0];
    reg         [4:0]               state_next;
    wire        [4:0]               state_l2;
    reg         [9:0]               state_ct[6:0];
    reg         [9:0]               state_ctF[6:0];
    wire        [9:0]               sc_l;
    wire        [9:0]               sc_lF;
    wire        [9:0]               sc_l2;
    wire        [9:0]               sc_l2F;
    wire        [9:0]               sc_e;
    wire        [9:0]               sc_eF;
    wire        [9:0]               sc_s;
    wire        [9:0]               sc_sF;
    wire                            doneL;

    reg         [`RP_DEPTH-1:0]     state_l_addr;
    wire        [`RP_DEPTH-1:0]     state_l_addr_plus;
    wire                            rb_rd_addr_nearmax;
    wire                            rb_rd_addr_max;
    wire        [`RP_DEPTH-2:0]     param_r_max_minus;

    reg         [`OUT_DEPTH-1:0]    o_addr;
    wire        [`OUT_DEPTH-1:0]    o_addr_plus;
    wire                            oaddr_r1_max;

    reg                             rb_rd_addr_max_reg;
    reg         [1:0]               param_outs1_reg;
    reg         [1:0]               param_outsl_reg;

    reg         [`OUT_D_SIZE-1:0]   o0;
    reg         [`OUT_D_SIZE-1:0]   o1;
    reg         [`OUT_D_SIZE-1:0]   o2;
    wire                            load_o0;
    wire                            load_o1;
    wire                            load_o2;

    reg         [`RP_D_SIZE2-1:0]   sl_r;
    wire        [`RP_D_SIZE2-1:0]   sl1_r;
    wire        [`RP_D_SIZE2-1:0]   sl_r_none;
    wire        [`RP_D_SIZE2-1:0]   sl_r_o0;
    wire        [`RP_D_SIZE2-1:0]   sl_r_o1o0;
    reg         [`RP_D_SIZE2-1:0]   slr_r;
    reg         [`RP_D_SIZE2-1:0]   sll_r;

    wire        [`RP_D_SIZE-1:0]    r0_next;
    wire        [`RP_D_SIZE-1:0]    r1_next;
    reg         [`RP_D_SIZE-1:0]    r0;
    reg         [`RP_D_SIZE-1:0]    r1;

    reg         [`RP_D_SIZE-1:0]    rb_rd_data_last;

    assign param_r_max_minus = (param_r_max - 'd1);

    bram_p # ( .D_SIZE(`RP_D_SIZE), .Q_DEPTH(`RP_DEPTH-1) ) r_buffer (
    //bram_n # ( .D_SIZE(`RP_D_SIZE), .Q_DEPTH(`RP_DEPTH-1) ) r_buffer (
        .clk(clk),
        .wr_en(rb_wr_en),
        .wr_addr(rb_wr_addr),
        .wr_din(rb_wr_data),
        .wr_dout(rb_wr_rd_data),
        .rd_addr(rb_rd_addr),
        .rd_dout(rb_rd_data_out)
    ) ;
    
    always @(posedge clk) begin
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
            state[0] <= 5'd0;
            state[1] <= 5'd0;
            state[2] <= 5'd0;
            state[3] <= 5'd0;
            state[4] <= 5'd0;
            state[5] <= 5'd0;
            state[6] <= 5'd0;
        end else begin
            state[0] <= state_next;
            state[1] <= state[0];
            state[2] <= state[1];
            state[3] <= state[2];
            state[4] <= state[3];
            state[5] <= state[4];
            state[6] <= state[5];
        end
    end
    assign state_l  = state[0];
    assign state_l2 = state[1];
    assign state_e  = state[3];
    assign state_s  = state[6];

    assign doneL = (state_l == 5'd31);
    assign done  = (state_s == 5'd31);

    always @ (*) begin
        if( state_l == 5'd0 ) begin
            state_next = 5'd1;
        end else if ( ~|sc_l ) begin
            if ( ( state_l == state_max ) || doneL ) begin
                state_next = 5'd31;
            end else begin
                state_next = state_l + 5'd1;
            end
        end else begin
            state_next = state_l;
        end
    end

    always @ ( posedge clk ) begin
        if ( start ) begin
            state_ct[0]  <= param_state_ct ;
            state_ctF[0] <= -'d1 ;
        end else if ( ~|sc_l ) begin
            state_ct[0]  <= param_state_ct ;
            state_ctF[0] <= 'd0 ;
        end else begin
            state_ct[0]  <= state_ct[0]  - 'd1;
            state_ctF[0] <= state_ctF[0] + 'd1;
        end
        state_ct[1] <= state_ct[0]; state_ctF[1] <= state_ctF[0];
        state_ct[2] <= state_ct[1]; state_ctF[2] <= state_ctF[1];
        state_ct[3] <= state_ct[2]; state_ctF[3] <= state_ctF[2];
        state_ct[4] <= state_ct[3]; state_ctF[4] <= state_ctF[3];
        state_ct[5] <= state_ct[4]; state_ctF[5] <= state_ctF[4];
        state_ct[6] <= state_ct[5]; state_ctF[6] <= state_ctF[5];
    end
    assign sc_l = state_ct[0];
    assign sc_lF = state_ctF[0];
    assign sc_l2 = state_ct[1];
    assign sc_l2F = state_ctF[1];
    assign sc_e = state_ct[2];
    assign sc_eF = state_ctF[2];
    assign sc_s = state_ct[6];
    assign sc_sF = state_ctF[6];

    assign state_l_addr_plus = state_l_addr + 'd1;
    always @ ( posedge clk ) begin
        if ( start || ~|sc_l ) begin
            //state_l_addr <= { (`RP_DEPTH) {1'b0} };
            state_l_addr <= { param_ri_offset, 1'b0 };
        end else begin
            //if ( state_l == 5'd2 ) begin
            //    if ( state_l_addr != { param_ri_len, 1'b1 } ) begin
            //        state_l_addr <= state_l_addr_plus;
            //    end
            //end else if (state_l != 5'd1) begin
            
            //if ( state_l != 5'd1 ) begin

                state_l_addr <= state_l_addr_plus;

            //end
        end
    end
    //assign rb_rd_addr = state_l_addr[1+:(`RP_DEPTH-1)] + param_ri_offset;
    assign rb_rd_addr = state_l_addr[1+:(`RP_DEPTH-1)];
    assign rb_rd_addr_nearmax = (rb_rd_addr == param_r_max_minus);
    assign rb_rd_addr_max = (rb_rd_addr == param_r_max);

    assign oaddr_r1_max = (o_addr[1:0] == param_outs1);
    assign o_addr_plus = o_addr + 'd1;
    always @ ( posedge clk ) begin
        if ( start || ~|sc_l ) begin
            o_addr <= { (`OUT_DEPTH) {1'b0} };
        end else begin
            if(state_l == 5'd1) begin
                if(~oaddr_r1_max) begin
                    o_addr <= o_addr_plus;
                end
            end else if(state_l == 5'd2) begin
                if ( ~sc_lF[2] ) begin
                    if (state_l_addr[0]) begin
                        casez( { rb_rd_addr_nearmax, param_outs1, param_outsl } )
                            5'b001??, 5'b010??, 5'b1??01, 5'b1??10: begin
                              o_addr <= o_addr_plus;
                            end
                            default: ;
                        endcase
                    end else begin
                        casez( { rb_rd_addr_max, param_outs1, param_outsl } )
                            5'b010??, 5'b1??10: begin
                              o_addr <= o_addr_plus;
                            end
                            default: ;
                        endcase
                    end
                end
            end else if(state_l != 5'd0) begin
                if (state_l_addr[0]) begin
                    casez( { rb_rd_addr_nearmax, param_outs1, param_outsl } )
                        5'b001??, 5'b010??, 5'b1??01, 5'b1??10: begin
                          o_addr <= o_addr_plus;
                        end
                        default: ;
                    endcase
                end else begin
                    casez( { rb_rd_addr_max, param_outs1, param_outsl } )
                        5'b010??, 5'b1??10: begin
                          o_addr <= o_addr_plus;
                        end
                        default: ;
                    endcase
                end
            end
        end
    end
    assign rp_rd_addr = param_outoffset + o_addr;

    always @ ( posedge clk ) begin
        rb_rd_addr_max_reg <= rb_rd_addr_max;
        param_outs1_reg <= param_outs1;
        param_outsl_reg <= param_outsl;
    end

    assign load_o0 =
        ((state_l2 == 5'd1) && (sc_l2F[2:0] == 'd0)) ||
        ((state_l2 == 5'd2) && ((sc_l2F[2:0] == 'd0 && ^param_outs1_reg) || (sc_l2F[2:0] == 'd2 && ^param_outsl_reg))) ||
        ((|state_l2[4:2] || &state_l2[1:0]) && ~sc_l2F[0] && ((~rb_rd_addr_max_reg && ^param_outs1_reg) || (rb_rd_addr_max_reg && ^param_outsl_reg)));
    assign load_o1 =
        ((state_l2 == 5'd1) && (sc_l2F[2:0] == 'd1)) ||
        ((state_l2 == 5'd2) && ((sc_l2F[2:0] == 'd1 && (param_outs1_reg == 'd2)) || (sc_l2F[2:0] == 'd3 && (param_outsl_reg == 'd2)))) ||
        ((|state_l2[4:2] || &state_l2[1:0]) && sc_l2F[0] && ((~rb_rd_addr_max_reg && (param_outs1_reg == 'd2)) || (rb_rd_addr_max_reg && (param_outsl_reg == 'd2))));
    assign load_o2 =            
        ((state_l2 == 5'd1) && (sc_l2F[2:0] == 'd2));

    always @ ( posedge clk ) begin
        if ( start ) begin
            o0 <= 'h0;
            o1 <= 'h0;
            o2 <= 'h0;
        end else begin
            if ( load_o0 ) o0 <= rp_rd_data;
            if ( load_o1 ) o1 <= rp_rd_data;
            if ( load_o2 ) o2 <= rp_rd_data;
        end
    end

    assign sl1_r = { (&param_outs1_reg) ? rp_rd_data : 8'b0,
        (&param_outs1_reg) ? o2 : (param_outs1_reg[1]) ? rp_rd_data : 8'b0, o1, o0 } ;
    assign sl_r_none = { { (`RP_D_SIZE) {1'b0} }, rb_rd_data };
    assign sl_r_o0   = { { (`RP_D_SIZE - `OUT_D_SIZE) {1'b0} }, rb_rd_data, o0 };
    assign sl_r_o1o0 = { rb_rd_data[0 +: (`RP_D_SIZE2 - 2*`OUT_D_SIZE)], rp_rd_data, o0 };
    always @ (*) begin
        case(param_outs1_reg)
            2'd0: slr_r = sl_r_none;
            2'd1: slr_r = sl_r_o0;
            2'd2: slr_r = sl_r_o1o0;
            2'd3: slr_r = 'h0;
            default: slr_r = 'h0;
        endcase
        case(param_outsl_reg)
            2'd0: sll_r = sl_r_none;
            2'd1: sll_r = sl_r_o0;
            2'd2: sll_r = sl_r_o1o0;
            2'd3: sll_r = 'h0;
            default: sll_r = 'h0;
        endcase
    end

    always @ ( posedge clk ) begin
        if ( start ) begin
            sl_r <= 'd0;
        end else if (sc_l2F[0] == 1'b1) begin
            if (state_l2 == 5'd1) begin
                sl_r <= sl1_r;
            end else begin
                sl_r <= (rb_rd_addr_max_reg) ? sll_r : slr_r;
            end
        end
    end

    barrett barrett0 (
        .clk(clk),
        .dividend(sl_r),
        .m0(param_m0),
        .m0_inverse(param_m0inv),
        .quotient(r1_next),
        .remainder(r0_next)
    ) ;

    always @ ( posedge clk ) begin
        r1 <= r1_next;
        r0 <= r0_next;
    end

    assign rb_wr_addr = param_ro_offset + ((state_s == 5'd1) ? sc_sF[0] : sc_sF);
    assign rb_wr_data = sc_sF[0] ? r1 : r0;
    always @ (*) begin
        if ((state_s == state_max) || ~|state_s || &state_s) begin
            rb_wr_en = 1'b0;
        end else if (state_s == 5'd1) begin
            if ((sc_sF == 'd2) || (sc_sF == 'd3)) begin
              rb_wr_en = 1'b1;
            end else begin
              rb_wr_en = 1'b0;
            end
        end else if (state_s == 5'd2) begin
            if (|sc_sF[9:2] || (sc_sF[1] && param_small_r2)) begin
              rb_wr_en = 1'b0;
            end else begin
              rb_wr_en = 1'b1;
            end
        end else begin
            rb_wr_en = 1'b1;
        end
    end

    always @ ( posedge clk ) begin
        if ( start ) begin
            rb_rd_data_last <= 'd0;
        end else begin
            if(rb_rd_addr_max_reg) begin
                rb_rd_data_last <= rb_rd_data;
            end
        end
    end

    assign cd_wr_addr = (state_s == state_max) ? param_ro_offset + sc_sF : 'd0;
    assign cd_wr_addr_max = (cd_wr_addr == param_ro_max);
    assign cd_wr_data = (state_s == state_max) ? (
        cd_wr_addr_max ? rb_rd_data_last : sc_sF[0] ? r1 : r0 ) : 'd0;
    assign cd_wr_en = (state_s == state_max);

endmodule
