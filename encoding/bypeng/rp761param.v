`include "params.v"

module rp761q4591encode_param ( state_max, state_l, state_s,
    param_r_max, param_m0, param_1st_round,
    param_outs1, param_outsl
    /* , and something else about the parameters */
) ; 

    output      [4:0]               state_max;

    input       [4:0]               state_l;
    input       [4:0]               state_s;
    output reg  [`RP_DEPTH-1:0]     param_r_max;
    output reg  [`RP_D_SIZE-1:0]    param_m0;
    output                          param_1st_round;
    output reg  [2:0]               param_outs1;
    output reg  [2:0]               param_outsl;

    assign state_max = 5'd9;

    always @ (*) begin // length of R array for each round.
        case(state_l)
            5'd0:    param_r_max = 10'd761;
            5'd1:    param_r_max = 10'd381;
            5'd2:    param_r_max = 10'd191;
            5'd3:    param_r_max = 10'd96;
            5'd4:    param_r_max = 10'd48;
            5'd5:    param_r_max = 10'd24;
            5'd6:    param_r_max = 10'd12;
            5'd7:    param_r_max = 10'd6;
            5'd8:    param_r_max = 10'd3;
            5'd9:    param_r_max = 10'd2;
            default: param_r_max = 10'd0;
        endcase
    end

    always @ (*) begin // M0 for each round.
        case(state_s)  // Note: In the last round, M will be forgot.
            5'd0:    param_m0 = 14'd4591;
            5'd1:    param_m0 = 14'd322;
            5'd2:    param_m0 = 14'd406;
            5'd3:    param_m0 = 14'd644;
            5'd4:    param_m0 = 14'd1621;
            5'd5:    param_m0 = 14'd10265;
            5'd6:    param_m0 = 14'd1608;
            5'd7:    param_m0 = 14'd10101;
            5'd8:    param_m0 = 14'd1557;
            5'd9:    param_m0 = 14'd9470;
            default: param_m0 = 14'd1;
        endcase
    end

    always @ (*) begin // Regular output bytes count for each round.
        case(state_s)  // Note: It is the special case for the round of |R| <= 2.
            5'd0:    param_outs1 = 3'd1; // 2 bytes outputed then set to 1.
            5'd1:    param_outs1 = 3'd0; // 1 byte outputed then set to 0.
            5'd2:    param_outs1 = 3'd0; // 0 bytes outputed then set to 7.
            5'd3:    param_outs1 = 3'd0;
            5'd4:    param_outs1 = 3'd0;
            5'd5:    param_outs1 = 3'd1;
            5'd6:    param_outs1 = 3'd0;
            5'd7:    param_outs1 = 3'd1;
            5'd8:    param_outs1 = 3'd0;
            5'd9:    param_outs1 = 3'd6; // Special case: set to 6.
            default: param_outs1 = 3'd6;
        endcase
    end

    always @ (*) begin // The last-pair output bytes count for each round.
        case(state_s)  // Note: It is the special case for the round of |R| <= 2.
            5'd0:    param_outsl = 3'd7; // 0 bytes outputed then set to 7.
            5'd1:    param_outsl = 3'd7;
            5'd2:    param_outsl = 3'd7;
            5'd3:    param_outsl = 3'd0; // 1 byte outputed then set to 0.
            5'd4:    param_outsl = 3'd1; // 2 bytes outputed then set to 1.
            5'd5:    param_outsl = 3'd0;
            5'd6:    param_outsl = 3'd1;
            5'd7:    param_outsl = 3'd0;
            5'd8:    param_outsl = 3'd7;
            5'd9:    param_outsl = 3'd3; // the last round: output them all.
            default: param_outsl = 3'd6; // In 761-4591 case: 4 bytes.
        endcase
    end

    assign param_1st_round = (state_l == 5'd0);

endmodule

module rp761q1531encode_param ( state_max, state_l, state_s,
    param_r_max, param_m0, param_1st_round,
    param_outs1, param_outsl
    /* , and something else about the parameters */
) ; 

    output      [4:0]               state_max;

    input       [4:0]               state_l;
    input       [4:0]               state_s;
    output reg  [`RP_DEPTH-1:0]     param_r_max;
    output reg  [`RP_D_SIZE-1:0]    param_m0;
    output                          param_1st_round;
    output reg  [2:0]               param_outs1;
    output reg  [2:0]               param_outsl;

    assign state_max = 5'd9;

    always @ (*) begin
        case(state_l)
            5'd0:    param_r_max = 10'd761;
            5'd1:    param_r_max = 10'd381;
            5'd2:    param_r_max = 10'd191;
            5'd3:    param_r_max = 10'd96;
            5'd4:    param_r_max = 10'd48;
            5'd5:    param_r_max = 10'd24;
            5'd6:    param_r_max = 10'd12;
            5'd7:    param_r_max = 10'd6;
            5'd8:    param_r_max = 10'd3;
            5'd9:    param_r_max = 10'd2;
            default: param_r_max = 10'd0;
        endcase
    end

    always @ (*) begin
        case(state_s)
            5'd0:    param_m0 = 14'd1531;
            5'd1:    param_m0 = 14'd9157;
            5'd2:    param_m0 = 14'd1280;
            5'd3:    param_m0 = 14'd6400;
            5'd4:    param_m0 = 14'd625;
            5'd5:    param_m0 = 14'd1526;
            5'd6:    param_m0 = 14'd9097;
            5'd7:    param_m0 = 14'd1263;
            5'd8:    param_m0 = 14'd6232;
            5'd9:    param_m0 = 14'd593;
            default: param_m0 = 14'd1;
        endcase
    end

    always @ (*) begin
        case(state_s)
            5'd0:    param_outs1 = 3'd0;
            5'd1:    param_outs1 = 3'd1;
            5'd2:    param_outs1 = 3'd0;
            5'd3:    param_outs1 = 3'd1;
            5'd4:    param_outs1 = 3'd0;
            5'd5:    param_outs1 = 3'd0;
            5'd6:    param_outs1 = 3'd1;
            5'd7:    param_outs1 = 3'd0;
            5'd8:    param_outs1 = 3'd1;
            5'd9:    param_outs1 = 3'd6;
            default: param_outs1 = 3'd6;
        endcase
    end

    always @ (*) begin
        case(state_s)
            5'd0:    param_outsl = 3'd7;
            5'd1:    param_outsl = 3'd7;
            5'd2:    param_outsl = 3'd7;
            5'd3:    param_outsl = 3'd1;
            5'd4:    param_outsl = 3'd0;
            5'd5:    param_outsl = 3'd0;
            5'd6:    param_outsl = 3'd1;
            5'd7:    param_outsl = 3'd0;
            5'd8:    param_outsl = 3'd7;
            5'd9:    param_outsl = 3'd2;
            default: param_outsl = 3'd6;
        endcase
    end

    assign param_1st_round = (state_l == 5'd0);

endmodule

module rp761q4591decode_param ( state_l, state_e, state_s,
    state_max, param_r_max, param_ro_max, param_small_r2,

    param_state_ct, 
    param_ri_offset, param_ri_len,
    param_outoffset, param_outs1, param_outsl, 
    param_m0, param_m0inv,
    param_ro_offset
) ; 

    input       [4:0]               state_l;
    input       [4:0]               state_e;
    input       [4:0]               state_s;

    output      [4:0]               state_max;
    output      [`RP_DEPTH-2:0]     param_r_max;
    output      [`RP_DEPTH-1:0]     param_ro_max;
    output                          param_small_r2;

    output reg  [10:0]              param_state_ct;
    output reg  [`RP_DEPTH-2:0]     param_ri_offset;
    output reg  [`RP_DEPTH-2:0]     param_ri_len;
    output reg  [`OUT_DEPTH-1:0]    param_outoffset;
    output reg  [1:0]               param_outs1;
    output reg  [1:0]               param_outsl;
    output reg  [`RP_D_SIZE-1:0]    param_m0;
    output reg  [`RP_INV_SIZE-1:0]  param_m0inv;
    output reg  [`RP_DEPTH-2:0]     param_ro_offset;

    wire        [1:0]               outsl_r2;

    assign state_max = 5'd10;
    assign param_r_max = 'd380; // R: 0 - 380
    assign param_ro_max = 'd760;

    always @ (*) begin // state counters.
        case(state_l)  // Indicating the cycle count (0 for 1 cycle) for each round.
            5'd0:    param_state_ct = 11'd8; // initial round, +1
            5'd1:    param_state_ct = 11'd4;
            5'd2:    param_state_ct = 11'd5;
            5'd3:    param_state_ct = 11'd11;
            5'd4:    param_state_ct = 11'd23;
            5'd5:    param_state_ct = 11'd47;
            5'd6:    param_state_ct = 11'd95;
            5'd7:    param_state_ct = 11'd189;
            5'd8:    param_state_ct = 11'd379;
            5'd9:    param_state_ct = 11'd760;
            default: param_state_ct = 11'd0;
        endcase
    end

    always @ (*) begin // R array offset. The last entry of R array for
        case(state_l)  // each round should be aligned at the last.
            5'd0:    param_ri_offset = 9'd0;   // no need to refer to R for 1st round
            5'd1:    param_ri_offset = 9'd379; // R_i =   1+1 to   2+1
            5'd2:    param_ri_offset = 9'd378; // R_i =   3   to   6
            5'd3:    param_ri_offset = 9'd375; // R_i =   6   to  12
            5'd4:    param_ri_offset = 9'd369; // R_i =  12   to  24
            5'd5:    param_ri_offset = 9'd357; // R_i =  24   to  48
            5'd6:    param_ri_offset = 9'd333; // R_i =  48   to  96
            5'd7:    param_ri_offset = 9'd285; // R_i =  95+1 to 190+1
            5'd8:    param_ri_offset = 9'd190; // R_i = 190+1 to 380+1
            5'd9:    param_ri_offset = 9'd0;   // R_i = 380+1 to 760+1
            default: param_ri_offset = 9'd0;
        endcase
    end

    always @ (*) begin // R array offset. The last entry of R array for
        case(state_l)  // each round should be aligned at the last.
            5'd1:    param_ri_len = 9'd0;   // no need to refer to R for 1st round
            5'd2:    param_ri_len = 9'd0;   // R_i =   1+1 to   2+1
            5'd3:    param_ri_len = 9'd2;   // R_i =   3   to   6
            5'd4:    param_ri_len = 9'd5;   // R_i =   6   to  12
            5'd5:    param_ri_len = 9'd11;  // R_i =  12   to  24
            5'd6:    param_ri_len = 9'd23;  // R_i =  24   to  48
            5'd7:    param_ri_len = 9'd47;  // R_i =  48   to  96
            5'd8:    param_ri_len = 9'd94;  // R_i =  95+1 to 190+1
            5'd9:    param_ri_len = 9'd189; // R_i = 190+1 to 380+1
            5'd10:   param_ri_len = 9'd379; // R_i = 380+1 to 760+1
            default: param_ri_len = 9'd0;
        endcase
    end

    always @ (*) begin // Compressed bytes offset.
        case(state_l)  // Indicating the first byte for each round.
            5'd1:    param_outoffset = 11'd1154; // Bytes 1154-1157 (by 4)
            5'd2:    param_outoffset = 11'd1153; // Bytes 1153      (by 1)
            5'd3:    param_outoffset = 11'd1148; // Bytes 1148-1151 (by 2), 1152      (by 1)
            5'd4:    param_outoffset = 11'd1141; // Bytes 1141-1145 (by 1), 1146-1147 (by 2)
            5'd5:    param_outoffset = 11'd1118; // Bytes 1118-1139 (by 2), 1140      (by 1)
            5'd6:    param_outoffset = 11'd1093; // Bytes 1093-1115 (by 1), 1116-1117 (by 2)
            5'd7:    param_outoffset = 11'd1045; // Bytes 1045-1091 (by 1), 1092      (by 1)
            5'd8:    param_outoffset = 11'd950;  // Bytes  950-1044 (by 1)
            5'd9:    param_outoffset = 11'd760;  // Bytes  760- 949 (by 1)
            5'd10:   param_outoffset = 11'd0;    // Bytes    0- 759 (by 2)
            default: param_outoffset = 11'd0;
        endcase
    end

    always @ (*) begin // Regular load bytes
        case(state_l)
            5'd1:    param_outs1 = 2'd3; // Last two rounds: 1 for 2 bytes, 2 for 3, 3 for 4
            5'd2:    param_outs1 = 2'd1; // 9               1
            5'd3:    param_outs1 = 2'd2; // 8               2 
            5'd4:    param_outs1 = 2'd1; // 7               1
            5'd5:    param_outs1 = 2'd2; // 6               2
            5'd6:    param_outs1 = 2'd1; // 5               1
            5'd7:    param_outs1 = 2'd1; // 4th round: load 1  byte
            5'd8:    param_outs1 = 2'd1; // 3rd round: load 1  byte
            5'd9:    param_outs1 = 2'd1; // 2nd round: load 1  byte
            5'd10:   param_outs1 = 2'd2; // 1st round: load 2  bytes
            default: param_outs1 = 2'd0;
        endcase
    end

    assign outsl_r2 = 2'd3;              // 9th round: no last need
    assign param_small_r2 = (outsl_r2 == 2'd3);
    always @ (*) begin // Last load bytes
        case(state_l)
            5'd1:    param_outsl = 2'd0; // Last two rounds: N/A
            5'd2:    param_outsl = outsl_r2;
            5'd3:    param_outsl = 2'd1; // 8               1
            5'd4:    param_outsl = 2'd2; // 7               2
            5'd5:    param_outsl = 2'd1; // 6               1
            5'd6:    param_outsl = 2'd2; // 5th round: load 2 bytes
            5'd7:    param_outsl = 2'd1; // 4th round: load 1 byte
            5'd8:    param_outsl = 2'd3; // 3rd round: no last need
            5'd9:    param_outsl = 2'd3; // 2nd round: no last need
            5'd10:   param_outsl = 2'd3; // 1st round: no last need
            default: param_outsl = 2'd0;
        endcase
    end

    always @ (*) begin // M0 for each round.
        case(state_e)
            5'd1:    param_m0 = 14'd9470;  // 1557*1557   / 256   (round up) = 9470
            5'd2:    param_m0 = 14'd1557;  // 10101*10101 / 65536 (round up) = 1557
            5'd3:    param_m0 = 14'd10101; // 1608*1608   / 256   (round up) = 10101
            5'd4:    param_m0 = 14'd1608;  // 10265*10265 / 65536 (round up) = 1608
            5'd5:    param_m0 = 14'd10265; // 1621*1621   / 256   (round up) = 10265
            5'd6:    param_m0 = 14'd1621;  // 644*644     / 256   (round up) = 1621
            5'd7:    param_m0 = 14'd644;   // 406*406     / 256   (round up) = 644
            5'd8:    param_m0 = 14'd406;   // 322*322     / 256   (round up) = 406
            5'd9:    param_m0 = 14'd322;   // 4591*4591   / 65536 (round up) = 322
            5'd10:   param_m0 = 14'd4591;  // Q = 4591
            default: param_m0 = 14'd1;
        endcase
    end

    always @ (*) begin // M0^(-1) for each round.
        case(state_e)
            5'd1:    param_m0inv = 27'd14172;
            5'd2:    param_m0inv = 27'd86202;
            5'd3:    param_m0inv = 27'd13287;
            5'd4:    param_m0inv = 27'd83468;
            5'd5:    param_m0inv = 27'd13075;
            5'd6:    param_m0inv = 27'd82799;
            5'd7:    param_m0inv = 27'd208412;
            5'd8:    param_m0inv = 27'd330585;
            5'd9:    param_m0inv = 27'd416825;
            5'd10:   param_m0inv = 27'd29234;  // 29234 = (2^27 / 4591)
            default: param_m0inv = 27'd1;
        endcase
    end

    always @ (*) begin // Output R array offset.
        case(state_s)  // Indicating the first entry for each round.
            5'd1:    param_ro_offset = 9'd379; // R: 379-380, |R| = 2
            5'd2:    param_ro_offset = 9'd378; // R: 378-379, |R| = 3   (380 rest)
            5'd3:    param_ro_offset = 9'd375; // R: 375-380, |R| = 6
            5'd4:    param_ro_offset = 9'd369; // R: 369-380, |R| = 12
            5'd5:    param_ro_offset = 9'd357; // R: 357-380, |R| = 24
            5'd6:    param_ro_offset = 9'd333; // R: 333-380, |R| = 48
            5'd7:    param_ro_offset = 9'd285; // R: 285-380, |R| = 96
            5'd8:    param_ro_offset = 9'd190; // R: 190-379, |R| = 191 (380 rest)
            5'd9:    param_ro_offset = 9'd0;   // R:   0-379, |R| = 381 (380 rest)
            5'd10:   param_ro_offset = 9'd0;   // R:   0-760, |R| = 761 (output round)
            default: param_ro_offset = 9'd0;
        endcase
    end

endmodule

module rp761q1531decode_param ( state_l, state_e, state_s,
    state_max, param_r_max, param_ro_max, param_small_r2,

    param_state_ct, 
    param_ri_offset, param_ri_len,
    param_outoffset, param_outs1, param_outsl, 
    param_m0, param_m0inv,
    param_ro_offset
) ; 

    input       [4:0]               state_l;
    input       [4:0]               state_e;
    input       [4:0]               state_s;

    output      [4:0]               state_max;
    output      [`RP_DEPTH-2:0]     param_r_max;
    output      [`RP_DEPTH-1:0]     param_ro_max;
    output                          param_small_r2;

    output reg  [10:0]              param_state_ct;
    output reg  [`RP_DEPTH-2:0]     param_ri_offset;
    output reg  [`RP_DEPTH-2:0]     param_ri_len;
    output reg  [`OUT_DEPTH-1:0]    param_outoffset;
    output reg  [1:0]               param_outs1;
    output reg  [1:0]               param_outsl;
    output reg  [`RP_D_SIZE-1:0]    param_m0;
    output reg  [`RP_INV_SIZE-1:0]  param_m0inv;
    output reg  [`RP_DEPTH-2:0]     param_ro_offset;

    wire        [1:0]               outsl_r2;

    assign state_max = 5'd10;
    assign param_r_max = 'd380; // R: 0 - 380
    assign param_ro_max = 'd760;

    always @ (*) begin // state counters.
        case(state_l)  // Indicating the cycle count (0 for 1 cycle) for each round.
            5'd0:    param_state_ct = 11'd8; // initial round, +1
            5'd1:    param_state_ct = 11'd4;
            5'd2:    param_state_ct = 11'd5;
            5'd3:    param_state_ct = 11'd11;
            5'd4:    param_state_ct = 11'd23;
            5'd5:    param_state_ct = 11'd47;
            5'd6:    param_state_ct = 11'd95;
            5'd7:    param_state_ct = 11'd189;
            5'd8:    param_state_ct = 11'd379;
            5'd9:    param_state_ct = 11'd760;
            default: param_state_ct = 11'd0;
        endcase
    end

    always @ (*) begin // R array offset. The last entry of R array for
        case(state_l)  // each round should be aligned at the last.
            5'd0:    param_ri_offset = 9'd0;   // no need to refer to R for 1st round
            5'd1:    param_ri_offset = 9'd379; // R_i =   1+1 to   2+1
            5'd2:    param_ri_offset = 9'd378; // R_i =   3   to   6
            5'd3:    param_ri_offset = 9'd375; // R_i =   6   to  12
            5'd4:    param_ri_offset = 9'd369; // R_i =  12   to  24
            5'd5:    param_ri_offset = 9'd357; // R_i =  24   to  48
            5'd6:    param_ri_offset = 9'd333; // R_i =  48   to  96
            5'd7:    param_ri_offset = 9'd285; // R_i =  95+1 to 190+1
            5'd8:    param_ri_offset = 9'd190; // R_i = 190+1 to 380+1
            5'd9:    param_ri_offset = 9'd0;   // R_i = 380+1 to 760+1
            default: param_ri_offset = 9'd0;
        endcase
    end

    always @ (*) begin // R array offset. The last entry of R array for
        case(state_l)  // each round should be aligned at the last.
            5'd1:    param_ri_len = 9'd0;   // no need to refer to R for 1st round
            5'd2:    param_ri_len = 9'd0;   // R_i =   1+1 to   2+1
            5'd3:    param_ri_len = 9'd2;   // R_i =   3   to   6
            5'd4:    param_ri_len = 9'd5;   // R_i =   6   to  12
            5'd5:    param_ri_len = 9'd11;  // R_i =  12   to  24
            5'd6:    param_ri_len = 9'd23;  // R_i =  24   to  48
            5'd7:    param_ri_len = 9'd47;  // R_i =  48   to  96
            5'd8:    param_ri_len = 9'd94;  // R_i =  95+1 to 190+1
            5'd9:    param_ri_len = 9'd189; // R_i = 190+1 to 380+1
            5'd10:   param_ri_len = 9'd379; // R_i = 380+1 to 760+1
            default: param_ri_len = 9'd0;
        endcase
    end

    always @ (*) begin
        case(state_l)
            5'd1:    param_outoffset = 11'd1004;
            5'd2:    param_outoffset = 11'd1002;
            5'd3:    param_outoffset = 11'd999;
            5'd4:    param_outoffset = 11'd987;
            5'd5:    param_outoffset = 11'd975;
            5'd6:    param_outoffset = 11'd951;
            5'd7:    param_outoffset = 11'd855;
            5'd8:    param_outoffset = 11'd760;
            5'd9:    param_outoffset = 11'd380;
            5'd10:   param_outoffset = 11'd0;
            default: param_outoffset = 11'd0;
        endcase
    end

    always @ (*) begin
        case(state_l)
            5'd1:    param_outs1 = 2'd2;
            5'd2:    param_outs1 = 2'd2;
            5'd3:    param_outs1 = 2'd1;
            5'd4:    param_outs1 = 2'd2;
            5'd5:    param_outs1 = 2'd1;
            5'd6:    param_outs1 = 2'd1;
            5'd7:    param_outs1 = 2'd2;
            5'd8:    param_outs1 = 2'd1;
            5'd9:    param_outs1 = 2'd2;
            5'd10:   param_outs1 = 2'd1;
            default: param_outs1 = 2'd0;
        endcase
    end

    assign outsl_r2 = 2'd3;              // 9th round: no last need
    assign param_small_r2 = (outsl_r2 == 2'd3);
    always @ (*) begin
        case(state_l)
            5'd1:    param_outsl = 2'd0;
            5'd2:    param_outsl = outsl_r2;
            5'd3:    param_outsl = 2'd1;
            5'd4:    param_outsl = 2'd2;
            5'd5:    param_outsl = 2'd1;
            5'd6:    param_outsl = 2'd1;
            5'd7:    param_outsl = 2'd2;
            5'd8:    param_outsl = 2'd3;
            5'd9:    param_outsl = 2'd3;
            5'd10:   param_outsl = 2'd3;
            default: param_outsl = 2'd0;
        endcase
    end

    always @ (*) begin
        case(state_e)
            5'd1:    param_m0 = 14'd593;
            5'd2:    param_m0 = 14'd6232;
            5'd3:    param_m0 = 14'd1263;
            5'd4:    param_m0 = 14'd9097;
            5'd5:    param_m0 = 14'd1526;
            5'd6:    param_m0 = 14'd625;
            5'd7:    param_m0 = 14'd6400;
            5'd8:    param_m0 = 14'd1280;
            5'd9:    param_m0 = 14'd9157;
            5'd10:   param_m0 = 14'd1531;
            default: param_m0 = 14'd1;
        endcase
    end

    always @ (*) begin
        case(state_e)
            5'd1:    param_m0inv = 27'd226336;
            5'd2:    param_m0inv = 27'd21536;
            5'd3:    param_m0inv = 27'd106268;
            5'd4:    param_m0inv = 27'd14754;
            5'd5:    param_m0inv = 27'd87953;
            5'd6:    param_m0inv = 27'd214748;
            5'd7:    param_m0inv = 27'd20971;
            5'd8:    param_m0inv = 27'd104857;
            5'd9:    param_m0inv = 27'd14657;
            5'd10:   param_m0inv = 27'd87666;
            default: param_m0inv = 27'd1;
        endcase
    end

    always @ (*) begin
        case(state_s)
            5'd1:    param_ro_offset = 9'd379;
            5'd2:    param_ro_offset = 9'd378;
            5'd3:    param_ro_offset = 9'd375;
            5'd4:    param_ro_offset = 9'd369;
            5'd5:    param_ro_offset = 9'd357;
            5'd6:    param_ro_offset = 9'd333;
            5'd7:    param_ro_offset = 9'd285;
            5'd8:    param_ro_offset = 9'd190;
            5'd9:    param_ro_offset = 9'd0;
            5'd10:   param_ro_offset = 9'd0;
            default: param_ro_offset = 9'd0;
        endcase
    end

endmodule



