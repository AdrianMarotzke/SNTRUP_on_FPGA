module ntt_7681_12289_15361 (clk, rst, start, input_fg, addr, din, dout, valid);

    parameter P_WIDTH = 13;
    parameter Q1 = 7681;
    parameter Q2 = 12289;
    parameter Q3 = 15361;
    parameter Q23inv = 2562;
    parameter Q31inv = -4107;
    parameter Q12inv = 10;

    parameter Q2Q3PREFIX = 184347;
    parameter Q3Q1PREFIX = 230445;
    parameter Q1Q2PREFIX = 184359;

    parameter Q2Q3SHIFT = 10;
    parameter Q3Q1SHIFT = 9;
    parameter Q1Q2SHIFT = 9;

    parameter bit = 9; // 512 point

    localparam Q1Q2Q3p = 34'sh197E88A01; // 1449952578049='h15197E88A01, w.o.prefix
    localparam Q1Q2Q3n = 34'sh2681775FF;

    // state
    parameter idle = 0;
    parameter ntt = 1;
    parameter point_mul = 2;
    parameter reload = 3;
    parameter intt = 4;
    parameter crt = 5;
    parameter finish = 6;

    input                clk;
    input                rst;
    input                start;
    input                input_fg;
    input       [10 : 0] addr;
    input       [12 : 0] din;
    output reg  [13 : 0] dout;
    output reg           valid;

    // bram
    reg            wr_en   [0 : 2];
    reg   [10 : 0] wr_addr [0 : 2];
    reg   [10 : 0] rd_addr [0 : 2];
    reg   [41 : 0] wr_din  [0 : 2];
    wire  [41 : 0] rd_dout [0 : 2];
    wire  [41 : 0] wr_dout [0 : 2];

    // addr_gen
    wire         bank_index_rd [0 : 1];
    wire         bank_index_wr [0 : 1];
    wire [7 : 0] data_index_rd [0 : 1];
    wire [7 : 0] data_index_wr [0 : 1];
    reg  bank_index_wr_0_shift_1, bank_index_wr_0_shift_2;

    // w_addr_gen
    reg  [7 : 0] stage_bit;
    wire [7 : 0] w_addr;

    // bfu
    reg                  ntt_state; 
    reg  signed [13 : 0] in_a  [0 : 2];
    reg  signed [13 : 0] in_b  [0 : 2];
    reg  signed [18 : 0] w     [0 : 2];
    wire signed [32 : 0] bw    [0 : 2];
    wire signed [13 : 0] out_a [0 : 2];
    wire signed [13 : 0] out_b [0 : 2];

    // state, stage, counter
    reg  [2 : 0] state, next_state;
    reg  [3 : 0] stage, stage_wr;
    reg  [8 : 0] ctr;
    reg  [8 : 0] ctr_shift_7, ctr_shift_8, ctr_shift_1, ctr_shift_2;
    reg  [2 : 0] ctr_ntt;
    reg  [1 : 0] count_f, count_g;
    reg          part, part_shift, ctr_8_shift_1;
    wire         ctr_end, ctr_shift_7_end, stage_end, stage_wr_end, ntt_end, point_mul_end;
    reg  [1 : 0] count_f_shift_1, count_f_shift_2;
    reg  [1 : 0] count_g_shift_1, count_g_shift_2, count_g_shift_3, count_g_shift_4, count_g_shift_5;

    // w_7681
    reg         [8  : 0] w_addr_in;
    wire signed [13 : 0] w_dout [0 : 2];

    reg          bank_index_rd_shift_1, bank_index_rd_shift_2;
    reg [8  : 0] wr_ctr [0 : 1];
    reg [12 : 0] din_shift_1, din_shift_2, din_shift_3;
    reg [8  : 0] w_addr_in_shift_1;

    // mod_3
    wire [2 : 0] in_addr;

    // crt
    reg  signed [13 : 0] in_b_1 [0 : 2];
    reg  signed [15 : 0] in_b_sum;
    reg  signed [32 : 0] bw_sum;
    wire signed [33 : 0] bw_sum_ALL;
    wire signed [33 : 0] q1q2q3_ALL;
    reg  signed [32 : 0] bw_sum_mod;
    wire signed [12 : 0] mod4591_out;

    // crt debug
    wire signed [13 : 0] in_b0_1;
    wire signed [13 : 0] in_b1_1;
    wire signed [13 : 0] in_b2_1;

    bram_p #(.D_SIZE(42), .Q_DEPTH(11)) bank_0 
    (clk, wr_en[0], wr_addr[0], rd_addr[0], wr_din[0], wr_dout[0], rd_dout[0]);
    bram_p #(.D_SIZE(42), .Q_DEPTH(11)) bank_1
    (clk, wr_en[1], wr_addr[1], rd_addr[1], wr_din[1], wr_dout[1], rd_dout[1]);
    bram_p #(.D_SIZE(42), .Q_DEPTH(11)) bank_2
    (clk, wr_en[2], wr_addr[2], rd_addr[2], wr_din[2], wr_dout[2], rd_dout[2]);

    addr_gen addr_rd_0 (clk, stage,    {1'b0, ctr[7 : 0]}, bank_index_rd[0], data_index_rd[0]);
    addr_gen addr_rd_1 (clk, stage,    {1'b1, ctr[7 : 0]}, bank_index_rd[1], data_index_rd[1]);
    addr_gen addr_wr_0 (clk, stage_wr, {wr_ctr[0]}, bank_index_wr[0], data_index_wr[0]);
    addr_gen addr_wr_1 (clk, stage_wr, {wr_ctr[1]}, bank_index_wr[1], data_index_wr[1]);

    w_addr_gen w_addr_gen_0 (clk, stage_bit, ctr[7 : 0], w_addr);

    bfu_7681 bfu_0 (clk, ntt_state, in_a[0], in_b[0], w[0], bw[0], out_a[0], out_b[0]);
    bfu_12289 bfu_1 (clk, ntt_state, in_a[1], in_b[1], w[1], bw[1], out_a[1], out_b[1]);
    bfu_15361 bfu_2 (clk, ntt_state, in_a[2], in_b[2], w[2], bw[2], out_a[2], out_b[2]);

    w_7681 rom_w_7681 (clk, w_addr_in_shift_1, w_dout[0]);
    w_12289 rom_w_12289 (clk, w_addr_in_shift_1, w_dout[1]);
    w_15361 rom_w_15361 (clk, w_addr_in_shift_1, w_dout[2]);

    mod_3 in_addr_gen (clk, addr, input_fg, in_addr);
    mod4591S33 mod_4591 ( clk, rst, bw_sum_mod, mod4591_out);

    assign ctr_end         = (ctr[7 : 0] == 255) ? 1 : 0;
    assign ctr_shift_7_end = (ctr_shift_7[7 : 0] == 255) ? 1 : 0;
    assign stage_end       = (stage == 9) ? 1 : 0;
    assign stage_wr_end    = (stage_wr == 9) ? 1 : 0;
    assign ntt_end         = (stage_end && ctr[7 : 0] == 10) ? 1 : 0;
    // change assign ntt_end         = (stage_end && ctr[7 : 0] == 8) ? 1 : 0;
    assign point_mul_end   = (count_f == 3 && ctr_shift_7 == 511) ? 1 : 0;
    assign reload_end      = (count_f == 0 && ctr == 4) ? 1 : 0;

    // crt debug
    assign in_b0_1 = in_b_1[0];
    assign in_b1_1 = in_b_1[1];
    assign in_b2_1 = in_b_1[2];

    assign bw_sum_ALL = $signed({ bw_sum[24:0], 9'b0 }) + in_b_sum;
    assign q1q2q3_ALL = bw_sum[32] ? (bw_sum[31] ? $signed(0) : $signed(Q1Q2Q3p))
                                   : (bw_sum[31] ? $signed(Q1Q2Q3n) : $signed(0));

    always @(posedge clk ) begin
        in_b_1[0] <= in_b[0];
        in_b_1[1] <= in_b[1];
        in_b_1[2] <= in_b[2];

        in_b_sum <= in_b_1[0] + in_b_1[1] + in_b_1[2];
        bw_sum <= $signed({ bw[0], 1'b0 }) + $signed( bw[1] + bw[2] );
        
        bw_sum_mod <= bw_sum_ALL + q1q2q3_ALL;
        //if (bw_sum[32:31] == 2'b01) begin
        //    bw_sum_mod <= bw_sum_ALL + $signed(Q1Q2Q3n);
        //end else if (bw_sum[32:31] == 2'b10) begin
        //    bw_sum_mod <= bw_sum_ALL + $signed(Q1Q2Q3p);
        //end else begin
        //    bw_sum_mod <= bw_sum_ALL;
        //end
    end

    // dout
    always @(posedge clk ) begin
        if (bank_index_wr_0_shift_2) begin
            //dout <= wr_dout[1][27 : 14];
            dout <= wr_dout[1][13 : 0];
        end else begin
            //dout <= wr_dout[0][27 : 14];
            dout <= wr_dout[0][13 : 0];
        end
    end

    // bank_index_wr_0_shift_1
    always @(posedge clk ) begin
        bank_index_wr_0_shift_1 <= bank_index_wr[0];
        bank_index_wr_0_shift_2 <= bank_index_wr_0_shift_1;
    end

    // part
    always @(posedge clk ) begin
        ctr_8_shift_1 <= ctr[8];
        part <= ctr_8_shift_1;
        part_shift <= ctr_shift_7[8];
    end

    // count_f, count_g
    always @(posedge clk ) begin
        if (state == point_mul || state == reload || state == crt) begin
            if (count_g == 2 && ctr == 511) begin
                count_f <= count_f + 1;
            end else begin
                count_f <= count_f;
            end
        end else begin
            count_f <= 0;
        end
        count_f_shift_1 <= count_f;
        count_f_shift_2 <= count_f_shift_1;


        if (state == point_mul || state == reload || state == crt) begin
            if (ctr == 511) begin
                if (count_g == 2) begin
                    count_g <= 0;
                end else begin
                    count_g <= count_g + 1;
                end
            end else begin
                count_g <= count_g;
            end
        end else begin
            count_g <= 0;
        end
        count_g_shift_1 <= count_g;
        count_g_shift_2 <= count_g_shift_1;
        count_g_shift_3 <= count_g_shift_2;
        count_g_shift_4 <= count_g_shift_3;
        count_g_shift_5 <= count_g_shift_4;
    end

    // rd_addr[2]
    always @(posedge clk ) begin
        if (state == point_mul) begin
            rd_addr[2][8 : 0] <= ctr;
        end else if (state == reload) begin
            rd_addr[2][8 : 0] <= {bank_index_wr[1], data_index_wr[1]};
        end else begin
            rd_addr[2][8 : 0] <= 0;
        end

        if (state == point_mul) begin
            if (ctr == 0) begin
                if (count_g == 0) begin
                    rd_addr[2][10 : 9] <= count_f;
                end else begin
                    if (rd_addr[2][10 : 9] == 0) begin
                        rd_addr[2][10 : 9] <= 1;
                    end else if (rd_addr[2][10 : 9] == 1) begin
                        rd_addr[2][10 : 9] <= 2;
                    end else begin
                        rd_addr[2][10 : 9] <= 0;
                    end
                end
            end else begin
                rd_addr[2][10 : 9] <= rd_addr[2][10 : 9];
            end
        end else if (state == reload) begin
            rd_addr[2][10 : 9] <= count_g_shift_3;
        end else begin
            rd_addr[2][10 : 9] <= 0;
        end
    end

    // wr_en[2]
    always @(posedge clk ) begin
        if (state == point_mul) begin
            if (count_f == 0 && count_g == 0 && ctr < 8 /* change ctr < 6*/) begin
                wr_en[2] <= 0;
            end else begin
                wr_en[2] <= 1;
            end
        end else begin
            wr_en[2] <= 0;
        end
    end

    // wr_addr[2]
    always @(posedge clk ) begin
        if (state == point_mul) begin
            wr_addr[2][8 : 0] <= ctr_shift_7;
        end else begin
            wr_addr[2][8 : 0] <= 0;
        end        

        if (state == point_mul) begin
            if (ctr_shift_7 == 0) begin
                if (count_g == 0) begin
                    wr_addr[2][10 : 9] <= count_f;
                end else begin
                    if (wr_addr[2][10 : 9] == 0) begin
                        wr_addr[2][10 : 9] <= 1;
                    end else if (wr_addr[2][10 : 9] == 1) begin
                        wr_addr[2][10 : 9] <= 2;
                    end else begin
                        wr_addr[2][10 : 9] <= 0;
                    end
                end
            end else begin
                wr_addr[2][10 : 9] <= wr_addr[2][10 : 9];
            end
        end else begin
            wr_addr[2][10 : 9] <= 0;
        end
    end

    // wr_din[2]
    always @(* ) begin
        wr_din[2][13 : 0] = out_a[0];
        wr_din[2][27 : 14] = out_a[1];
        wr_din[2][41 : 28] = out_a[2];
    end

    // ctr_ntt
    always @(posedge clk ) begin
        if (state == ntt || state == intt) begin
            if (ntt_end) begin
                ctr_ntt <= ctr_ntt + 1;
            end else begin
                ctr_ntt <= ctr_ntt;
            end    
        end else begin
            ctr_ntt <= 0;
        end
    end

    // w_addr_in_shift_1
    always @(posedge clk ) begin
        w_addr_in_shift_1 <= w_addr_in;
    end

    // din_shift
    always @(posedge clk ) begin
        din_shift_1 <= din;
        din_shift_2 <= din_shift_1;
        din_shift_3 <= din_shift_2;
    end

    // rd_addr
    always @(posedge clk ) begin
        if (state == point_mul || state == crt) begin
            rd_addr[0][7 : 0] <= ctr[7 : 0];
            rd_addr[1][7 : 0] <= ctr[7 : 0];
        end else begin
            if (bank_index_rd[0] == 0) begin
                rd_addr[0][7 : 0] <= data_index_rd[0];
                rd_addr[1][7 : 0] <= data_index_rd[1];
            end else begin
                rd_addr[0][7 : 0] <= data_index_rd[1];
                rd_addr[1][7 : 0] <= data_index_rd[0];
            end
        end

        if (state == point_mul) begin
            rd_addr[0][10 : 8] <= count_f;
            rd_addr[1][10 : 8] <= count_f;
        end else if (state == crt) begin
            rd_addr[0][10 : 8] <= count_g;
            rd_addr[1][10 : 8] <= count_g;  
        end else begin
            rd_addr[0][10 : 8] <= ctr_ntt;
            rd_addr[1][10 : 8] <= ctr_ntt;
        end
    end

    // wr_ctr
    always @(posedge clk ) begin
        if (state == idle) begin
            wr_ctr[0] <= addr[8 : 0];
        end else if (state == reload) begin
            wr_ctr[0] <= {ctr_shift_2[0], ctr_shift_2[1], ctr_shift_2[2], ctr_shift_2[3], ctr_shift_2[4], ctr_shift_2[5], ctr_shift_2[6], ctr_shift_2[7], ctr_shift_2[8]};
        end else if (state == finish) begin
            wr_ctr[0] <= {addr[0], addr[1], addr[2], addr[3], addr[4], addr[5], addr[6], addr[7], addr[8]};
        end else begin
            wr_ctr[0] <= {1'b0, ctr_shift_7[7 : 0]};
        end

        if (state == reload) begin
            wr_ctr[1] <= ctr;
        end else begin
            wr_ctr[1] <= {1'b1, ctr_shift_7[7 : 0]};
        end
    end

    // wr_en
    always @(posedge clk ) begin
        if (state == idle || state == reload) begin
            if (bank_index_wr[0]) begin
                wr_en[0] <= 0;
                wr_en[1] <= 1;
            end else begin
                wr_en[0] <= 1;
                wr_en[1] <= 0;
            end
        end else if (state == ntt || state == intt) begin
            if (stage == 0 && ctr < 11 /*change 9*/) begin
                wr_en[0] <= 0;
                wr_en[1] <= 0;
            end else begin
                wr_en[0] <= 1;
                wr_en[1] <= 1;
            end
        end else if (state == crt) begin
            if (count_f == 0 && count_g == 0 && ctr < 9/* change */) begin
                wr_en[0] <= 0;
                wr_en[1] <= 0;
            end else if (!part_shift) begin
                wr_en[0] <= 1;
                wr_en[1] <= 0;
            end else begin
                wr_en[0] <= 0;
                wr_en[1] <= 1;
            end
        end else begin
            wr_en[0] <= 0;
            wr_en[1] <= 0;
        end
    end

    // wr_addr
    always @(posedge clk ) begin
        if (state == point_mul) begin
            wr_addr[0][7 : 0] <= ctr[7 : 0];
            wr_addr[1][7 : 0] <= ctr[7 : 0];
        end else if (state == reload) begin
            wr_addr[0][7 : 0] <= data_index_wr[0];
            wr_addr[1][7 : 0] <= data_index_wr[0];
        end else if (state == crt) begin
            wr_addr[0][7 : 0] <= ctr_shift_8[7 : 0];
            wr_addr[1][7 : 0] <= ctr_shift_8[7 : 0];
        end else begin
            if (bank_index_wr[0] == 0) begin
                wr_addr[0][7 : 0] <= data_index_wr[0];
                wr_addr[1][7 : 0] <= data_index_wr[1];
            end else begin
                wr_addr[0][7 : 0] <= data_index_wr[1];
                wr_addr[1][7 : 0] <= data_index_wr[0];
            end
        end  

        if (state == idle || state == finish) begin
            wr_addr[0][10 : 8] <= in_addr;
            wr_addr[1][10 : 8] <= in_addr;
        end else if(state == ntt || state == intt) begin
            wr_addr[0][10 : 8] <= ctr_ntt;
            wr_addr[1][10 : 8] <= ctr_ntt;
        end else if (state == point_mul) begin
            wr_addr[0][10 : 8] <= count_g + 3;
            wr_addr[1][10 : 8] <= count_g + 3;
        end else if (state == reload) begin
            wr_addr[0][10 : 8] <= count_g_shift_5;
            wr_addr[1][10 : 8] <= count_g_shift_5;
        end else if (state == crt) begin
            if (ctr_shift_8 == 0) begin
                wr_addr[0][10 : 8] <= count_g;
                wr_addr[1][10 : 8] <= count_g;
            end else begin
                wr_addr[0][10 : 8] <= wr_addr[0][10 : 8];
                wr_addr[1][10 : 8] <= wr_addr[1][10 : 8];
            end
        end else begin
            wr_addr[0][10 : 8] <= 0;
            wr_addr[1][10 : 8] <= 0;
        end     
    end

    // wr_din
    always @(posedge clk ) begin
        if (state == idle) begin
            wr_din[0][13 : 0] <= {din_shift_3[12], din_shift_3};
            wr_din[1][13 : 0] <= {din_shift_3[12], din_shift_3};
        end else if (state == reload) begin
            wr_din[0][13 : 0] <= rd_dout[2][13 : 0];
            wr_din[1][13 : 0] <= rd_dout[2][13 : 0];
        end else if (state == crt) begin
            wr_din[0][13 : 0] <= out_a[0];
            wr_din[1][13 : 0] <= out_a[0];
            if (count_f == 0 || (count_f == 1 && count_g == 0 && ctr < 9)) begin
                wr_din[0][13 : 0] <= out_a[0];
                wr_din[1][13 : 0] <= out_a[0];
            end else begin
                wr_din[0][13 : 0] <= mod4591_out;
                wr_din[1][13 : 0] <= mod4591_out;
            end
        end else begin
            if (bank_index_wr[0] == 0) begin
                wr_din[0][13 : 0] <= out_a[0];
                wr_din[1][13 : 0] <= out_b[0];
            end else begin
                wr_din[0][13 : 0] <= out_b[0];
                wr_din[1][13 : 0] <= out_a[0];
            end
        end

        if (state == idle) begin
            wr_din[0][27 : 14] <= {din_shift_3[12], din_shift_3};
            wr_din[1][27 : 14] <= {din_shift_3[12], din_shift_3};
        end else if (state == reload) begin
            wr_din[0][27 : 14] <= rd_dout[2][27 : 14];
            wr_din[1][27 : 14] <= rd_dout[2][27 : 14];
        end else if (state == crt) begin
            wr_din[0][27 : 14] <= out_a[1];
            wr_din[1][27 : 14] <= out_a[1];
        end else begin
            if (bank_index_wr[0] == 0) begin
                wr_din[0][27 : 14] <= out_a[1];
                wr_din[1][27 : 14] <= out_b[1];
            end else begin
                wr_din[0][27 : 14] <= out_b[1];
                wr_din[1][27 : 14] <= out_a[1];
            end
        end

        if (state == idle) begin
            wr_din[0][41 : 28] <= {din_shift_3[12], din_shift_3};
            wr_din[1][41 : 28] <= {din_shift_3[12], din_shift_3};
        end else if (state == reload) begin
            wr_din[0][41 : 28] <= rd_dout[2][41 : 28];
            wr_din[1][41 : 28] <= rd_dout[2][41 : 28];
        end else if (state == crt) begin
            wr_din[0][41 : 28] <= out_a[2];
            wr_din[1][41 : 28] <= out_a[2];
        end else begin
            if (bank_index_wr[0] == 0) begin
                wr_din[0][41 : 28] <= out_a[2];
                wr_din[1][41 : 28] <= out_b[2];
            end else begin
                wr_din[0][41 : 28] <= out_b[2];
                wr_din[1][41 : 28] <= out_a[2];
            end
        end        
    end

    // bank_index_rd_shift
    always @(posedge clk ) begin
        bank_index_rd_shift_1 <= bank_index_rd[0];
        bank_index_rd_shift_2 <= bank_index_rd_shift_1;
    end

    // ntt_state
    always @(posedge clk ) begin
        if (state == intt) begin
            ntt_state <= 1;
        end else begin
            ntt_state <= 0;
        end
    end

    // in_a, in_b
    always @(posedge clk ) begin
        if (state == point_mul || state == crt) begin
            if (!part) begin
                in_b[0] <= rd_dout[0][13 : 0];
                in_b[1] <= rd_dout[0][27 : 14];
                in_b[2] <= rd_dout[0][41 : 28];
            end else begin
                in_b[0] <= rd_dout[1][13 : 0];
                in_b[1] <= rd_dout[1][27 : 14];
                in_b[2] <= rd_dout[1][41 : 28];
            end
        end else begin
            if (bank_index_rd_shift_2 == 0) begin
                in_b[0] <= rd_dout[1][13 : 0];
                in_b[1] <= rd_dout[1][27 : 14];
                in_b[2] <= rd_dout[1][41 : 28];
            end else begin
                in_b[0] <= rd_dout[0][13 : 0];
                in_b[1] <= rd_dout[0][27 : 14];
                in_b[2] <= rd_dout[0][41 : 28];
            end
        end

        if (state == point_mul) begin
            if (count_f_shift_2 == 0) begin
                in_a[0] <= 0;
                in_a[1] <= 0;
                in_a[2] <= 0;
            end else begin
                in_a[0] <= rd_dout[2][13 : 0];
                in_a[1] <= rd_dout[2][27 : 14];
                in_a[2] <= rd_dout[2][41 : 28];
            end
        end else if (state == crt) begin
            in_a[0] <= 0;
            in_a[1] <= 0;
            in_a[2] <= 0;
        end else begin
            if (bank_index_rd_shift_2 == 0) begin
                in_a[0] <= rd_dout[0][13 : 0];
                in_a[1] <= rd_dout[0][27 : 14];
                in_a[2] <= rd_dout[0][41 : 28];
            end else begin
                in_a[0] <= rd_dout[1][13 : 0];
                in_a[1] <= rd_dout[1][27 : 14];
                in_a[2] <= rd_dout[1][41 : 28];
            end
        end
    end

    // w_addr_in, w
    always @(posedge clk ) begin
        if (state == ntt) begin
            w_addr_in <= {1'b0, w_addr};
        end else begin
            w_addr_in <= 512 - w_addr;
        end

        if (state == point_mul) begin
            if (!part) begin
                w[0] <= {{ 5{wr_dout[0][13]} }, wr_dout[0][13 : 0]};
                w[1] <= {{ 5{wr_dout[0][27]} }, wr_dout[0][27 : 14]};
                w[2] <= {{ 5{wr_dout[0][41]} }, wr_dout[0][41 : 28]};
            end else begin
                w[0] <= {{ 5{wr_dout[1][13]} }, wr_dout[1][13 : 0]};
                w[1] <= {{ 5{wr_dout[1][27]} }, wr_dout[1][27 : 14]};
                w[2] <= {{ 5{wr_dout[1][41]} }, wr_dout[1][41 : 28]};
            end
        end else if (state == crt) begin
            if (count_f_shift_2 == 0) begin
                w[0] <= Q23inv;
                w[1] <= Q31inv;
                w[2] <= Q12inv;
            end else begin
                w[0] <= Q2Q3PREFIX;
                w[1] <= Q3Q1PREFIX;
                w[2] <= Q1Q2PREFIX;
            end
        end else begin
            w[0] <= w_dout[0];
            w[1] <= w_dout[1];
            w[2] <= w_dout[2];
        end
    end

    // ctr, ctr_shift_7
    always @(posedge clk ) begin
        if (state == ntt || state == intt || state == point_mul || state == crt) begin
            if (ntt_end || point_mul_end) begin
                ctr <= 0;
            end else begin
                ctr <= ctr + 1;
            end
        end else if (state == reload) begin
            if (reload_end) begin
                ctr <= 0;
            end else begin
                ctr <= ctr + 1;
            end
        end else begin
            ctr <= 0;
        end

        //change ctr_shift_7 <= ctr - 5;
        ctr_shift_7 <= ctr - 7;
        ctr_shift_8 <= ctr_shift_7;
        ctr_shift_1 <= ctr;
        ctr_shift_2 <= ctr_shift_1;
    end

    // stage, stage_wr
    always @(posedge clk ) begin
        if (state == ntt || state == intt) begin
            if (ntt_end) begin
                stage <= 0;
            end else if (ctr_end) begin
                stage <= stage + 1;
            end else begin
                stage <= stage;
            end
        end else begin
            stage <= 0;
        end

        if (state == ntt || state == intt) begin
            if (ntt_end) begin
                stage_wr <= 0;
            end else if (ctr_shift_7[7 : 0] == 0 && stage != 0) begin
               stage_wr <= stage_wr + 1;
            end else begin
                stage_wr <= stage_wr;
            end
        end else begin
            stage_wr <= 0;
        end        
    end

    // stage_bit
    always @(posedge clk ) begin
        if (state == ntt || state == intt) begin
            if (ntt_end) begin
                stage_bit <= 0;
            end else if (ctr_end) begin
                stage_bit[0] <= 1'b1;
                stage_bit[7 : 1] <= stage_bit[6 : 0];
            end else begin
                stage_bit <= stage_bit;
            end
        end else begin
            stage_bit <= 8'b0;
        end
    end

    // valid
    always @(* ) begin
        if (state == finish) begin
            valid = 1;
        end else begin
            valid = 0;
        end
    end

    // state
	always @(posedge clk ) begin
		if(rst) begin
            state <= 0;
        end else begin
            state <= next_state;
        end
	end
	always @(*) begin
		case(state)
		idle: begin
			if(start)
				next_state = ntt;
			else
				next_state = idle;
		end
		ntt: begin
			if(ntt_end && ctr_ntt == 5)
				next_state = point_mul;
			else
				next_state = ntt;
		end
    point_mul: begin
      if (point_mul_end)
        next_state = reload;
      else
        next_state = point_mul;
    end
    reload: begin
      if (reload_end) begin
        next_state = intt;
      end else begin
        next_state = reload;
      end
    end
    intt: begin
      if(ntt_end && ctr_ntt == 2)
				next_state = crt;
			else
				next_state = intt;
      end
    crt: begin
      if(count_f == 2 && ctr == 8)
				next_state = finish;
			else
				next_state = crt;
    end
		finish: begin
			if(!start)
				next_state = finish;
			else
				next_state = idle;
		end
		default: next_state = state;
		endcase
	end

endmodule

module mod_3 (clk, addr, fg, out);

    input               clk;
    input               fg;
    input      [10 : 0] addr;
    output reg [2  : 0] out;

    reg [2 : 0] even, odd;
    reg signed [2 : 0] even_minus_odd;
    reg fg_shift_1;
    reg [1 : 0] const;

    always @(posedge clk ) begin
        fg_shift_1 <= fg;

        if (fg_shift_1) begin
            const <= 3;
        end else begin
            const <= 0;
        end

        even <= addr[0] + addr[2] + addr[4] + addr[6] + addr[8] + addr[10];
        odd  <= addr[1] + addr[3] + addr[5] + addr[7] + addr[9];
        even_minus_odd <= even[2] - even[1] + even[0] - odd[2] + odd[1] - odd[0];

        if (even_minus_odd == 3) begin
            out <= 0 + const;
        end else begin
            out <= even_minus_odd[1 : 0] - even_minus_odd[2] + const;
        end
    end

endmodule

module w_addr_gen (clk, stage_bit, ctr, w_addr);

    input              clk;
    input      [7 : 0] stage_bit;  // 0 - 8
    input      [7 : 0] ctr;        // 0 - 255
    output reg [7 : 0] w_addr;

    wire [7 : 0] w;

    assign w[0] = (stage_bit[0]) ? ctr[0] : 0;
    assign w[1] = (stage_bit[1]) ? ctr[1] : 0;
    assign w[2] = (stage_bit[2]) ? ctr[2] : 0;
    assign w[3] = (stage_bit[3]) ? ctr[3] : 0;
    assign w[4] = (stage_bit[4]) ? ctr[4] : 0;
    assign w[5] = (stage_bit[5]) ? ctr[5] : 0;
    assign w[6] = (stage_bit[6]) ? ctr[6] : 0;
    assign w[7] = (stage_bit[7]) ? ctr[7] : 0;

    always @(posedge clk ) begin
        w_addr <= {w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7]};
    end
    
endmodule

module bfu_7681 (clk, state, in_a, in_b, w, bw, out_a, out_b);

    parameter P_WIDTH = 14;
    parameter PP_WIDTH = 25;
    parameter Q = 7681;

    input                      clk;
    input                      state;
    input      signed [13 : 0] in_a;
    input      signed [13 : 0] in_b;
    input      signed [18 : 0] w;
    output reg signed [32 : 0] bw;
    output reg signed [13 : 0] out_a;
    output reg signed [13 : 0] out_b;

    wire signed [12 : 0] mod_bw;
    reg signed [14 : 0] a, b;
    reg signed [13 : 0] in_a_s1, in_a_s2, in_a_s3, in_a_s4, in_a_s5;

    reg signed [28 : 0] bwQ_0, bwQ_1, bwQ_2;
    wire signed [14  : 0] a_add_q, a_sub_q, b_add_q, b_sub_q;

    //wire signed [12 : 0] mod_bw_test;

    modmul7681s mod7681 (clk, bw, mod_bw);

    //wire test;
    //assign test = (mod_bw == mod_bw_test) ? 0 : 1;

    //assign bwQ = bw % Q;
    assign a_add_q = a + Q;
    assign a_sub_q = a - Q;
    assign b_add_q = b + Q;
    assign b_sub_q = b - Q;
    
    
    // in_a shift
    always @(posedge clk ) begin
        in_a_s1 <= in_a;
        in_a_s2 <= in_a_s1;
        in_a_s3 <= in_a_s2;
        in_a_s4 <= in_a_s3;
        in_a_s5 <= in_a_s4;
    end

    // b * w
    always @(posedge clk ) begin
        bw <= in_b * w;
        
        /*
        bwQ_0 <= bw % Q;
        bwQ_1 <= bwQ_0;
        
        if (bwQ_1 > 3840) begin
            mod_bw <= bwQ_1 - Q;
        end else if (bwQ_1 < -3840) begin
            mod_bw <= bwQ_1 + Q;
        end else begin
            mod_bw <= bwQ_1;
        end    
        */
    end

    // out_a, out_b
    always @(posedge clk ) begin
        //a <= in_a_s2 + mod_bw;
        //b <= in_a_s2 - mod_bw;

        a <= in_a_s4 + mod_bw;
        b <= in_a_s4 - mod_bw;

        if (state == 0) begin
            if (a > 3840) begin
                out_a <= a_sub_q;
            end else if (a < -3840) begin
                out_a <= a_add_q;
            end else begin
                out_a <= a;
            end
        end else begin
            if (a[0] == 0) begin
                out_a <= a[P_WIDTH : 1];
            end else if (a[P_WIDTH] == 0) begin   // a > 0
                out_a <= a_sub_q[P_WIDTH : 1];
            end else begin                        // a < 0
                out_a <= a_add_q[P_WIDTH : 1];
            end
        end


        if (state == 0) begin
            if (b > 3840) begin
                out_b <= b_sub_q;
            end else if (b < -3840) begin
                out_b <= b_add_q;
            end else begin
                out_b <= b;
            end
        end else begin
            if (b[0] == 0) begin
                out_b <= b[P_WIDTH : 1];
            end else if (b[P_WIDTH] == 0) begin   // b > 0
                out_b <= b_sub_q[P_WIDTH : 1];
            end else begin                        // b < 0
                out_b <= b_add_q[P_WIDTH : 1];
            end
        end
    end

endmodule

module bfu_12289 (clk, state, in_a, in_b, w, bw, out_a, out_b);

    parameter P_WIDTH = 14;
    parameter PP_WIDTH = 26;
    parameter Q = 12289;

    localparam HALF_Q = (Q-1)/2;

    input                                clk;
    input                                state;
    input      signed [13 : 0] in_a;
    input      signed [13 : 0] in_b;
    input      signed [18 : 0] w;
    output reg signed [32 : 0] bw;
    output reg signed [13 : 0] out_a;
    output reg signed [13 : 0] out_b;

    wire signed [13 : 0] mod_bw;
    reg signed [14 : 0] a, b;
    reg signed [13 : 0] in_a_s1, in_a_s2, in_a_s3, in_a_s4, in_a_s5;

    reg signed [28 : 0] bwQ_0, bwQ_1, bwQ_2;
    wire signed [14  : 0] a_add_q, a_sub_q, b_add_q, b_sub_q;

    mod12289s mod12289_inst (clk, 1'b0, bw, mod_bw);

    //assign bwQ = bw % Q;
    assign a_add_q = a + Q;
    assign a_sub_q = a - Q;
    assign b_add_q = b + Q;
    assign b_sub_q = b - Q;
    
    
    // in_a shift
    always @(posedge clk ) begin
        in_a_s1 <= in_a;
        in_a_s2 <= in_a_s1;
        in_a_s3 <= in_a_s2;
        in_a_s4 <= in_a_s3;
        in_a_s5 <= in_a_s4;
    end

    // b * w
    always @(posedge clk ) begin
        bw <= in_b * w;
    end

    // out_a, out_b
    always @(posedge clk ) begin
        a <= in_a_s4 + mod_bw;
        b <= in_a_s4 - mod_bw;

        if (state == 0) begin
            if (a > HALF_Q) begin
                out_a <= a_sub_q;
            end else if (a < -HALF_Q) begin
                out_a <= a_add_q;
            end else begin
                out_a <= a;
            end
        end else begin
            if (a[0] == 0) begin
                out_a <= a[P_WIDTH : 1];
            end else if (a[P_WIDTH] == 0) begin   // a > 0
                out_a <= a_sub_q[P_WIDTH : 1];
            end else begin                        // a < 0
                out_a <= a_add_q[P_WIDTH : 1];
            end
        end


        if (state == 0) begin
            if (b > HALF_Q) begin
                out_b <= b_sub_q;
            end else if (b < -HALF_Q) begin
                out_b <= b_add_q;
            end else begin
                out_b <= b;
            end
        end else begin
            if (b[0] == 0) begin
                out_b <= b[P_WIDTH : 1];
            end else if (b[P_WIDTH] == 0) begin   // b > 0
                out_b <= b_sub_q[P_WIDTH : 1];
            end else begin                        // b < 0
                out_b <= b_add_q[P_WIDTH : 1];
            end
        end
    end

endmodule

module bfu_15361 (clk, state, in_a, in_b, w, bw, out_a, out_b);

    parameter P_WIDTH = 14;
    parameter PP_WIDTH = 26;
    parameter Q = 15361;

    localparam HALF_Q = (Q-1)/2;

    input                                clk;
    input                                state;
    input      signed [13 : 0] in_a;
    input      signed [13 : 0] in_b;
    input      signed [18 : 0] w;
    output reg signed [32 : 0] bw;
    output reg signed [13 : 0] out_a;
    output reg signed [13 : 0] out_b;

    wire signed [13 : 0] mod_bw;
    reg signed [14 : 0] a, b;
    reg signed [13 : 0] in_a_s1, in_a_s2, in_a_s3, in_a_s4, in_a_s5;

    reg signed [28 : 0] bwQ_0, bwQ_1, bwQ_2;
    wire signed [14  : 0] a_add_q, a_sub_q, b_add_q, b_sub_q;

    modmul15361s mod15361_inst (clk, 1'b0, bw, mod_bw);

    //assign bwQ = bw % Q;
    assign a_add_q = a + Q;
    assign a_sub_q = a - Q;
    assign b_add_q = b + Q;
    assign b_sub_q = b - Q;
    
    
    // in_a shift
    always @(posedge clk ) begin
        in_a_s1 <= in_a;
        in_a_s2 <= in_a_s1;
        in_a_s3 <= in_a_s2;
        in_a_s4 <= in_a_s3;
        in_a_s5 <= in_a_s4;
    end

    // b * w
    always @(posedge clk ) begin
        bw <= in_b * w;
    end

    // out_a, out_b
    always @(posedge clk ) begin
        a <= in_a_s4 + mod_bw;
        b <= in_a_s4 - mod_bw;

        if (state == 0) begin
            if (a > HALF_Q) begin
                out_a <= a_sub_q;
            end else if (a < -HALF_Q) begin
                out_a <= a_add_q;
            end else begin
                out_a <= a;
            end
        end else begin
            if (a[0] == 0) begin
                out_a <= a[P_WIDTH : 1];
            end else if (a[P_WIDTH] == 0) begin   // a > 0
                out_a <= a_sub_q[P_WIDTH : 1];
            end else begin                        // a < 0
                out_a <= a_add_q[P_WIDTH : 1];
            end
        end


        if (state == 0) begin
            if (b > HALF_Q) begin
                out_b <= b_sub_q;
            end else if (b < -HALF_Q) begin
                out_b <= b_add_q;
            end else begin
                out_b <= b;
            end
        end else begin
            if (b[0] == 0) begin
                out_b <= b[P_WIDTH : 1];
            end else if (b[P_WIDTH] == 0) begin   // b > 0
                out_b <= b_sub_q[P_WIDTH : 1];
            end else begin                        // b < 0
                out_b <= b_add_q[P_WIDTH : 1];
            end
        end
    end

endmodule

module addr_gen (clk, stage, ctr, bank_index, data_index);
    
    input              clk;
    input      [3 : 0] stage;  // 0 - 8
    input      [8 : 0] ctr;    // 0 - 511
    output reg         bank_index; // 0 - 1
    output reg [7 : 0] data_index; // 0 - 255

    wire [8 : 0] bs_out;

    barrel_shifter bs (clk, ctr, stage, bs_out);

    // bank_index
    always @(posedge clk ) begin
        bank_index <= ^bs_out;
    end

    // data_index
    always @(posedge clk ) begin
        data_index <= bs_out[8 : 1];
    end

endmodule

module barrel_shifter (clk, in, shift, out);
    
    input              clk;
    input      [8 : 0] in;
    input      [3 : 0] shift;
    output reg [8 : 0] out;

    reg [8 : 0] in_s0, in_s1, in_s2;

    // shift 4
    always @(* ) begin
        if (shift[2]) begin
            in_s2 = {in[3:0], in[8:4]};
        end else begin
            in_s2 = in;
        end
    end

    // shift 2
    always @(* ) begin
        if (shift[1]) begin
            in_s1 = {in_s2[1:0], in_s2[8:2]};
        end else begin
            in_s1 = in_s2;
        end
    end

    // shift 1
    always @(* ) begin
        if (shift[0]) begin
            in_s0 = {in_s1[0], in_s1[8:1]};
        end else begin
            in_s0 = in_s1;
        end
    end

    // out
    always @(posedge clk ) begin
        if (shift[3]) begin
            out <= {in[7:0], in[8]};
        end else begin
            out <= in_s0;
        end
    end
    
endmodule

module w_7681 ( clk, addr, dout);
    
    input  clk;
    input  [8 : 0] addr;
    output [13 : 0] dout;

    reg [8 : 0] a;
    (* rom_style = "block" *) reg [13 : 0] data [0 : 511];

    assign dout = data[a];

    always @(posedge clk) begin
        a <= addr;
    end

    always @(posedge clk) begin
        data[0] <= 1;
        data[1] <= 62;
        data[2] <= -3837;
        data[3] <= 217;
        data[4] <= -1908;
        data[5] <= -3081;
        data[6] <= 1003;
        data[7] <= 738;
        data[8] <= -330;
        data[9] <= 2583;
        data[10] <= -1155;
        data[11] <= -2481;
        data[12] <= -202;
        data[13] <= 2838;
        data[14] <= -707;
        data[15] <= 2252;
        data[16] <= 1366;
        data[17] <= 201;
        data[18] <= -2900;
        data[19] <= -3137;
        data[20] <= -2469;
        data[21] <= 542;
        data[22] <= 2880;
        data[23] <= 1897;
        data[24] <= 2399;
        data[25] <= 2799;
        data[26] <= -3125;
        data[27] <= -1725;
        data[28] <= 584;
        data[29] <= -2197;
        data[30] <= 2044;
        data[31] <= 3832;
        data[32] <= -527;
        data[33] <= -1950;
        data[34] <= 1996;
        data[35] <= 856;
        data[36] <= -695;
        data[37] <= 2996;
        data[38] <= 1408;
        data[39] <= 2805;
        data[40] <= -2753;
        data[41] <= -1704;
        data[42] <= 1886;
        data[43] <= 1717;
        data[44] <= -1080;
        data[45] <= 2169;
        data[46] <= -3780;
        data[47] <= 3751;
        data[48] <= 2132;
        data[49] <= 1607;
        data[50] <= -219;
        data[51] <= 1784;
        data[52] <= 3074;
        data[53] <= -1437;
        data[54] <= 3078;
        data[55] <= -1189;
        data[56] <= 3092;
        data[57] <= -321;
        data[58] <= 3141;
        data[59] <= 2717;
        data[60] <= -528;
        data[61] <= -2012;
        data[62] <= -1848;
        data[63] <= 639;
        data[64] <= 1213;
        data[65] <= -1604;
        data[66] <= 405;
        data[67] <= 2067;
        data[68] <= -2423;
        data[69] <= 3394;
        data[70] <= 3041;
        data[71] <= -3483;
        data[72] <= -878;
        data[73] <= -669;
        data[74] <= -3073;
        data[75] <= 1499;
        data[76] <= 766;
        data[77] <= 1406;
        data[78] <= 2681;
        data[79] <= -2760;
        data[80] <= -2138;
        data[81] <= -1979;
        data[82] <= 198;
        data[83] <= -3086;
        data[84] <= 693;
        data[85] <= -3120;
        data[86] <= -1415;
        data[87] <= -3239;
        data[88] <= -1112;
        data[89] <= 185;
        data[90] <= 3789;
        data[91] <= -3193;
        data[92] <= 1740;
        data[93] <= 346;
        data[94] <= -1591;
        data[95] <= 1211;
        data[96] <= -1728;
        data[97] <= 398;
        data[98] <= 1633;
        data[99] <= 1393;
        data[100] <= 1875;
        data[101] <= 1035;
        data[102] <= 2722;
        data[103] <= -218;
        data[104] <= 1846;
        data[105] <= -763;
        data[106] <= -1220;
        data[107] <= 1170;
        data[108] <= 3411;
        data[109] <= -3586;
        data[110] <= 417;
        data[111] <= 2811;
        data[112] <= -2381;
        data[113] <= -1683;
        data[114] <= 3188;
        data[115] <= -2050;
        data[116] <= 3477;
        data[117] <= 506;
        data[118] <= 648;
        data[119] <= 1771;
        data[120] <= 2268;
        data[121] <= 2358;
        data[122] <= 257;
        data[123] <= 572;
        data[124] <= -2941;
        data[125] <= 2002;
        data[126] <= 1228;
        data[127] <= -674;
        data[128] <= -3383;
        data[129] <= -2359;
        data[130] <= -319;
        data[131] <= 3265;
        data[132] <= 2724;
        data[133] <= -94;
        data[134] <= 1853;
        data[135] <= -329;
        data[136] <= 2645;
        data[137] <= 2689;
        data[138] <= -2264;
        data[139] <= -2110;
        data[140] <= -243;
        data[141] <= 296;
        data[142] <= 2990;
        data[143] <= 1036;
        data[144] <= 2784;
        data[145] <= 3626;
        data[146] <= 2063;
        data[147] <= -2671;
        data[148] <= 3380;
        data[149] <= 2173;
        data[150] <= -3532;
        data[151] <= 3765;
        data[152] <= 3000;
        data[153] <= 1656;
        data[154] <= 2819;
        data[155] <= -1885;
        data[156] <= -1655;
        data[157] <= -2757;
        data[158] <= -1952;
        data[159] <= 1872;
        data[160] <= 849;
        data[161] <= -1129;
        data[162] <= -869;
        data[163] <= -111;
        data[164] <= 799;
        data[165] <= 3452;
        data[166] <= -1044;
        data[167] <= -3280;
        data[168] <= -3654;
        data[169] <= -3799;
        data[170] <= 2573;
        data[171] <= -1775;
        data[172] <= -2516;
        data[173] <= -2372;
        data[174] <= -1125;
        data[175] <= -621;
        data[176] <= -97;
        data[177] <= 1667;
        data[178] <= 3501;
        data[179] <= 1994;
        data[180] <= 732;
        data[181] <= -702;
        data[182] <= 2562;
        data[183] <= -2457;
        data[184] <= 1286;
        data[185] <= 2922;
        data[186] <= -3180;
        data[187] <= 2546;
        data[188] <= -3449;
        data[189] <= 1230;
        data[190] <= -550;
        data[191] <= -3376;
        data[192] <= -1925;
        data[193] <= 3546;
        data[194] <= -2897;
        data[195] <= -2951;
        data[196] <= 1382;
        data[197] <= 1193;
        data[198] <= -2844;
        data[199] <= 335;
        data[200] <= -2273;
        data[201] <= -2668;
        data[202] <= 3566;
        data[203] <= -1657;
        data[204] <= -2881;
        data[205] <= -1959;
        data[206] <= 1438;
        data[207] <= -3016;
        data[208] <= -2648;
        data[209] <= -2875;
        data[210] <= -1587;
        data[211] <= 1459;
        data[212] <= -1714;
        data[213] <= 1266;
        data[214] <= 1682;
        data[215] <= -3250;
        data[216] <= -1794;
        data[217] <= -3694;
        data[218] <= 1402;
        data[219] <= 2433;
        data[220] <= -2774;
        data[221] <= -3006;
        data[222] <= -2028;
        data[223] <= -2840;
        data[224] <= 583;
        data[225] <= -2259;
        data[226] <= -1800;
        data[227] <= 3615;
        data[228] <= 1381;
        data[229] <= 1131;
        data[230] <= 993;
        data[231] <= 118;
        data[232] <= -365;
        data[233] <= 413;
        data[234] <= 2563;
        data[235] <= -2395;
        data[236] <= -2551;
        data[237] <= 3139;
        data[238] <= 2593;
        data[239] <= -535;
        data[240] <= -2446;
        data[241] <= 1968;
        data[242] <= -880;
        data[243] <= -793;
        data[244] <= -3080;
        data[245] <= 1065;
        data[246] <= -3099;
        data[247] <= -113;
        data[248] <= 675;
        data[249] <= 3445;
        data[250] <= -1478;
        data[251] <= 536;
        data[252] <= 2508;
        data[253] <= 1876;
        data[254] <= 1097;
        data[255] <= -1115;
        data[256] <= -1;
        data[257] <= -62;
        data[258] <= 3837;
        data[259] <= -217;
        data[260] <= 1908;
        data[261] <= 3081;
        data[262] <= -1003;
        data[263] <= -738;
        data[264] <= 330;
        data[265] <= -2583;
        data[266] <= 1155;
        data[267] <= 2481;
        data[268] <= 202;
        data[269] <= -2838;
        data[270] <= 707;
        data[271] <= -2252;
        data[272] <= -1366;
        data[273] <= -201;
        data[274] <= 2900;
        data[275] <= 3137;
        data[276] <= 2469;
        data[277] <= -542;
        data[278] <= -2880;
        data[279] <= -1897;
        data[280] <= -2399;
        data[281] <= -2799;
        data[282] <= 3125;
        data[283] <= 1725;
        data[284] <= -584;
        data[285] <= 2197;
        data[286] <= -2044;
        data[287] <= -3832;
        data[288] <= 527;
        data[289] <= 1950;
        data[290] <= -1996;
        data[291] <= -856;
        data[292] <= 695;
        data[293] <= -2996;
        data[294] <= -1408;
        data[295] <= -2805;
        data[296] <= 2753;
        data[297] <= 1704;
        data[298] <= -1886;
        data[299] <= -1717;
        data[300] <= 1080;
        data[301] <= -2169;
        data[302] <= 3780;
        data[303] <= -3751;
        data[304] <= -2132;
        data[305] <= -1607;
        data[306] <= 219;
        data[307] <= -1784;
        data[308] <= -3074;
        data[309] <= 1437;
        data[310] <= -3078;
        data[311] <= 1189;
        data[312] <= -3092;
        data[313] <= 321;
        data[314] <= -3141;
        data[315] <= -2717;
        data[316] <= 528;
        data[317] <= 2012;
        data[318] <= 1848;
        data[319] <= -639;
        data[320] <= -1213;
        data[321] <= 1604;
        data[322] <= -405;
        data[323] <= -2067;
        data[324] <= 2423;
        data[325] <= -3394;
        data[326] <= -3041;
        data[327] <= 3483;
        data[328] <= 878;
        data[329] <= 669;
        data[330] <= 3073;
        data[331] <= -1499;
        data[332] <= -766;
        data[333] <= -1406;
        data[334] <= -2681;
        data[335] <= 2760;
        data[336] <= 2138;
        data[337] <= 1979;
        data[338] <= -198;
        data[339] <= 3086;
        data[340] <= -693;
        data[341] <= 3120;
        data[342] <= 1415;
        data[343] <= 3239;
        data[344] <= 1112;
        data[345] <= -185;
        data[346] <= -3789;
        data[347] <= 3193;
        data[348] <= -1740;
        data[349] <= -346;
        data[350] <= 1591;
        data[351] <= -1211;
        data[352] <= 1728;
        data[353] <= -398;
        data[354] <= -1633;
        data[355] <= -1393;
        data[356] <= -1875;
        data[357] <= -1035;
        data[358] <= -2722;
        data[359] <= 218;
        data[360] <= -1846;
        data[361] <= 763;
        data[362] <= 1220;
        data[363] <= -1170;
        data[364] <= -3411;
        data[365] <= 3586;
        data[366] <= -417;
        data[367] <= -2811;
        data[368] <= 2381;
        data[369] <= 1683;
        data[370] <= -3188;
        data[371] <= 2050;
        data[372] <= -3477;
        data[373] <= -506;
        data[374] <= -648;
        data[375] <= -1771;
        data[376] <= -2268;
        data[377] <= -2358;
        data[378] <= -257;
        data[379] <= -572;
        data[380] <= 2941;
        data[381] <= -2002;
        data[382] <= -1228;
        data[383] <= 674;
        data[384] <= 3383;
        data[385] <= 2359;
        data[386] <= 319;
        data[387] <= -3265;
        data[388] <= -2724;
        data[389] <= 94;
        data[390] <= -1853;
        data[391] <= 329;
        data[392] <= -2645;
        data[393] <= -2689;
        data[394] <= 2264;
        data[395] <= 2110;
        data[396] <= 243;
        data[397] <= -296;
        data[398] <= -2990;
        data[399] <= -1036;
        data[400] <= -2784;
        data[401] <= -3626;
        data[402] <= -2063;
        data[403] <= 2671;
        data[404] <= -3380;
        data[405] <= -2173;
        data[406] <= 3532;
        data[407] <= -3765;
        data[408] <= -3000;
        data[409] <= -1656;
        data[410] <= -2819;
        data[411] <= 1885;
        data[412] <= 1655;
        data[413] <= 2757;
        data[414] <= 1952;
        data[415] <= -1872;
        data[416] <= -849;
        data[417] <= 1129;
        data[418] <= 869;
        data[419] <= 111;
        data[420] <= -799;
        data[421] <= -3452;
        data[422] <= 1044;
        data[423] <= 3280;
        data[424] <= 3654;
        data[425] <= 3799;
        data[426] <= -2573;
        data[427] <= 1775;
        data[428] <= 2516;
        data[429] <= 2372;
        data[430] <= 1125;
        data[431] <= 621;
        data[432] <= 97;
        data[433] <= -1667;
        data[434] <= -3501;
        data[435] <= -1994;
        data[436] <= -732;
        data[437] <= 702;
        data[438] <= -2562;
        data[439] <= 2457;
        data[440] <= -1286;
        data[441] <= -2922;
        data[442] <= 3180;
        data[443] <= -2546;
        data[444] <= 3449;
        data[445] <= -1230;
        data[446] <= 550;
        data[447] <= 3376;
        data[448] <= 1925;
        data[449] <= -3546;
        data[450] <= 2897;
        data[451] <= 2951;
        data[452] <= -1382;
        data[453] <= -1193;
        data[454] <= 2844;
        data[455] <= -335;
        data[456] <= 2273;
        data[457] <= 2668;
        data[458] <= -3566;
        data[459] <= 1657;
        data[460] <= 2881;
        data[461] <= 1959;
        data[462] <= -1438;
        data[463] <= 3016;
        data[464] <= 2648;
        data[465] <= 2875;
        data[466] <= 1587;
        data[467] <= -1459;
        data[468] <= 1714;
        data[469] <= -1266;
        data[470] <= -1682;
        data[471] <= 3250;
        data[472] <= 1794;
        data[473] <= 3694;
        data[474] <= -1402;
        data[475] <= -2433;
        data[476] <= 2774;
        data[477] <= 3006;
        data[478] <= 2028;
        data[479] <= 2840;
        data[480] <= -583;
        data[481] <= 2259;
        data[482] <= 1800;
        data[483] <= -3615;
        data[484] <= -1381;
        data[485] <= -1131;
        data[486] <= -993;
        data[487] <= -118;
        data[488] <= 365;
        data[489] <= -413;
        data[490] <= -2563;
        data[491] <= 2395;
        data[492] <= 2551;
        data[493] <= -3139;
        data[494] <= -2593;
        data[495] <= 535;
        data[496] <= 2446;
        data[497] <= -1968;
        data[498] <= 880;
        data[499] <= 793;
        data[500] <= 3080;
        data[501] <= -1065;
        data[502] <= 3099;
        data[503] <= 113;
        data[504] <= -675;
        data[505] <= -3445;
        data[506] <= 1478;
        data[507] <= -536;
        data[508] <= -2508;
        data[509] <= -1876;
        data[510] <= -1097;
        data[511] <= 1115;
    end

endmodule

module w_12289 ( clk, addr, dout);
    
    input  clk;
    input  [8 : 0] addr;
    output [13 : 0] dout;

    reg [8 : 0] a;
    (* rom_style = "block" *) reg [13 : 0] data [0 : 511];

    assign dout = data[a];

    always @(posedge clk) begin
        a <= addr;
    end

    always @(posedge clk) begin
        data[0] <= 1;
        data[1] <= 3;
        data[2] <= 9;
        data[3] <= 27;
        data[4] <= 81;
        data[5] <= 243;
        data[6] <= 729;
        data[7] <= 2187;
        data[8] <= -5728;
        data[9] <= -4895;
        data[10] <= -2396;
        data[11] <= 5101;
        data[12] <= 3014;
        data[13] <= -3247;
        data[14] <= 2548;
        data[15] <= -4645;
        data[16] <= -1646;
        data[17] <= -4938;
        data[18] <= -2525;
        data[19] <= 4714;
        data[20] <= 1853;
        data[21] <= 5559;
        data[22] <= 4388;
        data[23] <= 875;
        data[24] <= 2625;
        data[25] <= -4414;
        data[26] <= -953;
        data[27] <= -2859;
        data[28] <= 3712;
        data[29] <= -1153;
        data[30] <= -3459;
        data[31] <= 1912;
        data[32] <= 5736;
        data[33] <= 4919;
        data[34] <= 2468;
        data[35] <= -4885;
        data[36] <= -2366;
        data[37] <= 5191;
        data[38] <= 3284;
        data[39] <= -2437;
        data[40] <= 4978;
        data[41] <= 2645;
        data[42] <= -4354;
        data[43] <= -773;
        data[44] <= -2319;
        data[45] <= 5332;
        data[46] <= 3707;
        data[47] <= -1168;
        data[48] <= -3504;
        data[49] <= 1777;
        data[50] <= 5331;
        data[51] <= 3704;
        data[52] <= -1177;
        data[53] <= -3531;
        data[54] <= 1696;
        data[55] <= 5088;
        data[56] <= 2975;
        data[57] <= -3364;
        data[58] <= 2197;
        data[59] <= -5698;
        data[60] <= -4805;
        data[61] <= -2126;
        data[62] <= 5911;
        data[63] <= 5444;
        data[64] <= 4043;
        data[65] <= -160;
        data[66] <= -480;
        data[67] <= -1440;
        data[68] <= -4320;
        data[69] <= -671;
        data[70] <= -2013;
        data[71] <= -6039;
        data[72] <= -5828;
        data[73] <= -5195;
        data[74] <= -3296;
        data[75] <= 2401;
        data[76] <= -5086;
        data[77] <= -2969;
        data[78] <= 3382;
        data[79] <= -2143;
        data[80] <= 5860;
        data[81] <= 5291;
        data[82] <= 3584;
        data[83] <= -1537;
        data[84] <= -4611;
        data[85] <= -1544;
        data[86] <= -4632;
        data[87] <= -1607;
        data[88] <= -4821;
        data[89] <= -2174;
        data[90] <= 5767;
        data[91] <= 5012;
        data[92] <= 2747;
        data[93] <= -4048;
        data[94] <= 145;
        data[95] <= 435;
        data[96] <= 1305;
        data[97] <= 3915;
        data[98] <= -544;
        data[99] <= -1632;
        data[100] <= -4896;
        data[101] <= -2399;
        data[102] <= 5092;
        data[103] <= 2987;
        data[104] <= -3328;
        data[105] <= 2305;
        data[106] <= -5374;
        data[107] <= -3833;
        data[108] <= 790;
        data[109] <= 2370;
        data[110] <= -5179;
        data[111] <= -3248;
        data[112] <= 2545;
        data[113] <= -4654;
        data[114] <= -1673;
        data[115] <= -5019;
        data[116] <= -2768;
        data[117] <= 3985;
        data[118] <= -334;
        data[119] <= -1002;
        data[120] <= -3006;
        data[121] <= 3271;
        data[122] <= -2476;
        data[123] <= 4861;
        data[124] <= 2294;
        data[125] <= -5407;
        data[126] <= -3932;
        data[127] <= 493;
        data[128] <= 1479;
        data[129] <= 4437;
        data[130] <= 1022;
        data[131] <= 3066;
        data[132] <= -3091;
        data[133] <= 3016;
        data[134] <= -3241;
        data[135] <= 2566;
        data[136] <= -4591;
        data[137] <= -1484;
        data[138] <= -4452;
        data[139] <= -1067;
        data[140] <= -3201;
        data[141] <= 2686;
        data[142] <= -4231;
        data[143] <= -404;
        data[144] <= -1212;
        data[145] <= -3636;
        data[146] <= 1381;
        data[147] <= 4143;
        data[148] <= 140;
        data[149] <= 420;
        data[150] <= 1260;
        data[151] <= 3780;
        data[152] <= -949;
        data[153] <= -2847;
        data[154] <= 3748;
        data[155] <= -1045;
        data[156] <= -3135;
        data[157] <= 2884;
        data[158] <= -3637;
        data[159] <= 1378;
        data[160] <= 4134;
        data[161] <= 113;
        data[162] <= 339;
        data[163] <= 1017;
        data[164] <= 3051;
        data[165] <= -3136;
        data[166] <= 2881;
        data[167] <= -3646;
        data[168] <= 1351;
        data[169] <= 4053;
        data[170] <= -130;
        data[171] <= -390;
        data[172] <= -1170;
        data[173] <= -3510;
        data[174] <= 1759;
        data[175] <= 5277;
        data[176] <= 3542;
        data[177] <= -1663;
        data[178] <= -4989;
        data[179] <= -2678;
        data[180] <= 4255;
        data[181] <= 476;
        data[182] <= 1428;
        data[183] <= 4284;
        data[184] <= 563;
        data[185] <= 1689;
        data[186] <= 5067;
        data[187] <= 2912;
        data[188] <= -3553;
        data[189] <= 1630;
        data[190] <= 4890;
        data[191] <= 2381;
        data[192] <= -5146;
        data[193] <= -3149;
        data[194] <= 2842;
        data[195] <= -3763;
        data[196] <= 1000;
        data[197] <= 3000;
        data[198] <= -3289;
        data[199] <= 2422;
        data[200] <= -5023;
        data[201] <= -2780;
        data[202] <= 3949;
        data[203] <= -442;
        data[204] <= -1326;
        data[205] <= -3978;
        data[206] <= 355;
        data[207] <= 1065;
        data[208] <= 3195;
        data[209] <= -2704;
        data[210] <= 4177;
        data[211] <= 242;
        data[212] <= 726;
        data[213] <= 2178;
        data[214] <= -5755;
        data[215] <= -4976;
        data[216] <= -2639;
        data[217] <= 4372;
        data[218] <= 827;
        data[219] <= 2481;
        data[220] <= -4846;
        data[221] <= -2249;
        data[222] <= 5542;
        data[223] <= 4337;
        data[224] <= 722;
        data[225] <= 2166;
        data[226] <= -5791;
        data[227] <= -5084;
        data[228] <= -2963;
        data[229] <= 3400;
        data[230] <= -2089;
        data[231] <= 6022;
        data[232] <= 5777;
        data[233] <= 5042;
        data[234] <= 2837;
        data[235] <= -3778;
        data[236] <= 955;
        data[237] <= 2865;
        data[238] <= -3694;
        data[239] <= 1207;
        data[240] <= 3621;
        data[241] <= -1426;
        data[242] <= -4278;
        data[243] <= -545;
        data[244] <= -1635;
        data[245] <= -4905;
        data[246] <= -2426;
        data[247] <= 5011;
        data[248] <= 2744;
        data[249] <= -4057;
        data[250] <= 118;
        data[251] <= 354;
        data[252] <= 1062;
        data[253] <= 3186;
        data[254] <= -2731;
        data[255] <= 4096;
        data[256] <= -1;
        data[257] <= -3;
        data[258] <= -9;
        data[259] <= -27;
        data[260] <= -81;
        data[261] <= -243;
        data[262] <= -729;
        data[263] <= -2187;
        data[264] <= 5728;
        data[265] <= 4895;
        data[266] <= 2396;
        data[267] <= -5101;
        data[268] <= -3014;
        data[269] <= 3247;
        data[270] <= -2548;
        data[271] <= 4645;
        data[272] <= 1646;
        data[273] <= 4938;
        data[274] <= 2525;
        data[275] <= -4714;
        data[276] <= -1853;
        data[277] <= -5559;
        data[278] <= -4388;
        data[279] <= -875;
        data[280] <= -2625;
        data[281] <= 4414;
        data[282] <= 953;
        data[283] <= 2859;
        data[284] <= -3712;
        data[285] <= 1153;
        data[286] <= 3459;
        data[287] <= -1912;
        data[288] <= -5736;
        data[289] <= -4919;
        data[290] <= -2468;
        data[291] <= 4885;
        data[292] <= 2366;
        data[293] <= -5191;
        data[294] <= -3284;
        data[295] <= 2437;
        data[296] <= -4978;
        data[297] <= -2645;
        data[298] <= 4354;
        data[299] <= 773;
        data[300] <= 2319;
        data[301] <= -5332;
        data[302] <= -3707;
        data[303] <= 1168;
        data[304] <= 3504;
        data[305] <= -1777;
        data[306] <= -5331;
        data[307] <= -3704;
        data[308] <= 1177;
        data[309] <= 3531;
        data[310] <= -1696;
        data[311] <= -5088;
        data[312] <= -2975;
        data[313] <= 3364;
        data[314] <= -2197;
        data[315] <= 5698;
        data[316] <= 4805;
        data[317] <= 2126;
        data[318] <= -5911;
        data[319] <= -5444;
        data[320] <= -4043;
        data[321] <= 160;
        data[322] <= 480;
        data[323] <= 1440;
        data[324] <= 4320;
        data[325] <= 671;
        data[326] <= 2013;
        data[327] <= 6039;
        data[328] <= 5828;
        data[329] <= 5195;
        data[330] <= 3296;
        data[331] <= -2401;
        data[332] <= 5086;
        data[333] <= 2969;
        data[334] <= -3382;
        data[335] <= 2143;
        data[336] <= -5860;
        data[337] <= -5291;
        data[338] <= -3584;
        data[339] <= 1537;
        data[340] <= 4611;
        data[341] <= 1544;
        data[342] <= 4632;
        data[343] <= 1607;
        data[344] <= 4821;
        data[345] <= 2174;
        data[346] <= -5767;
        data[347] <= -5012;
        data[348] <= -2747;
        data[349] <= 4048;
        data[350] <= -145;
        data[351] <= -435;
        data[352] <= -1305;
        data[353] <= -3915;
        data[354] <= 544;
        data[355] <= 1632;
        data[356] <= 4896;
        data[357] <= 2399;
        data[358] <= -5092;
        data[359] <= -2987;
        data[360] <= 3328;
        data[361] <= -2305;
        data[362] <= 5374;
        data[363] <= 3833;
        data[364] <= -790;
        data[365] <= -2370;
        data[366] <= 5179;
        data[367] <= 3248;
        data[368] <= -2545;
        data[369] <= 4654;
        data[370] <= 1673;
        data[371] <= 5019;
        data[372] <= 2768;
        data[373] <= -3985;
        data[374] <= 334;
        data[375] <= 1002;
        data[376] <= 3006;
        data[377] <= -3271;
        data[378] <= 2476;
        data[379] <= -4861;
        data[380] <= -2294;
        data[381] <= 5407;
        data[382] <= 3932;
        data[383] <= -493;
        data[384] <= -1479;
        data[385] <= -4437;
        data[386] <= -1022;
        data[387] <= -3066;
        data[388] <= 3091;
        data[389] <= -3016;
        data[390] <= 3241;
        data[391] <= -2566;
        data[392] <= 4591;
        data[393] <= 1484;
        data[394] <= 4452;
        data[395] <= 1067;
        data[396] <= 3201;
        data[397] <= -2686;
        data[398] <= 4231;
        data[399] <= 404;
        data[400] <= 1212;
        data[401] <= 3636;
        data[402] <= -1381;
        data[403] <= -4143;
        data[404] <= -140;
        data[405] <= -420;
        data[406] <= -1260;
        data[407] <= -3780;
        data[408] <= 949;
        data[409] <= 2847;
        data[410] <= -3748;
        data[411] <= 1045;
        data[412] <= 3135;
        data[413] <= -2884;
        data[414] <= 3637;
        data[415] <= -1378;
        data[416] <= -4134;
        data[417] <= -113;
        data[418] <= -339;
        data[419] <= -1017;
        data[420] <= -3051;
        data[421] <= 3136;
        data[422] <= -2881;
        data[423] <= 3646;
        data[424] <= -1351;
        data[425] <= -4053;
        data[426] <= 130;
        data[427] <= 390;
        data[428] <= 1170;
        data[429] <= 3510;
        data[430] <= -1759;
        data[431] <= -5277;
        data[432] <= -3542;
        data[433] <= 1663;
        data[434] <= 4989;
        data[435] <= 2678;
        data[436] <= -4255;
        data[437] <= -476;
        data[438] <= -1428;
        data[439] <= -4284;
        data[440] <= -563;
        data[441] <= -1689;
        data[442] <= -5067;
        data[443] <= -2912;
        data[444] <= 3553;
        data[445] <= -1630;
        data[446] <= -4890;
        data[447] <= -2381;
        data[448] <= 5146;
        data[449] <= 3149;
        data[450] <= -2842;
        data[451] <= 3763;
        data[452] <= -1000;
        data[453] <= -3000;
        data[454] <= 3289;
        data[455] <= -2422;
        data[456] <= 5023;
        data[457] <= 2780;
        data[458] <= -3949;
        data[459] <= 442;
        data[460] <= 1326;
        data[461] <= 3978;
        data[462] <= -355;
        data[463] <= -1065;
        data[464] <= -3195;
        data[465] <= 2704;
        data[466] <= -4177;
        data[467] <= -242;
        data[468] <= -726;
        data[469] <= -2178;
        data[470] <= 5755;
        data[471] <= 4976;
        data[472] <= 2639;
        data[473] <= -4372;
        data[474] <= -827;
        data[475] <= -2481;
        data[476] <= 4846;
        data[477] <= 2249;
        data[478] <= -5542;
        data[479] <= -4337;
        data[480] <= -722;
        data[481] <= -2166;
        data[482] <= 5791;
        data[483] <= 5084;
        data[484] <= 2963;
        data[485] <= -3400;
        data[486] <= 2089;
        data[487] <= -6022;
        data[488] <= -5777;
        data[489] <= -5042;
        data[490] <= -2837;
        data[491] <= 3778;
        data[492] <= -955;
        data[493] <= -2865;
        data[494] <= 3694;
        data[495] <= -1207;
        data[496] <= -3621;
        data[497] <= 1426;
        data[498] <= 4278;
        data[499] <= 545;
        data[500] <= 1635;
        data[501] <= 4905;
        data[502] <= 2426;
        data[503] <= -5011;
        data[504] <= -2744;
        data[505] <= 4057;
        data[506] <= -118;
        data[507] <= -354;
        data[508] <= -1062;
        data[509] <= -3186;
        data[510] <= 2731;
        data[511] <= -4096;
    end

endmodule

module w_15361 ( clk, addr, dout);
    
    input  clk;
    input  [8 : 0] addr;
    output [13 : 0] dout;

    reg [8 : 0] a;
    (* rom_style = "block" *) reg [13 : 0] data [0 : 511];

    assign dout = data[a];

    always @(posedge clk) begin
        a <= addr;
    end

    always @(posedge clk) begin
        data[0] <= 1;
        data[1] <= 98;
        data[2] <= -5757;
        data[3] <= 4171;
        data[4] <= -5989;
        data[5] <= -3204;
        data[6] <= -6772;
        data[7] <= -3133;
        data[8] <= 186;
        data[9] <= 2867;
        data[10] <= 4468;
        data[11] <= -7605;
        data[12] <= 7399;
        data[13] <= 3135;
        data[14] <= 10;
        data[15] <= 980;
        data[16] <= 3874;
        data[17] <= -4373;
        data[18] <= 1554;
        data[19] <= -1318;
        data[20] <= -6276;
        data[21] <= -608;
        data[22] <= 1860;
        data[23] <= -2052;
        data[24] <= -1403;
        data[25] <= 755;
        data[26] <= -2815;
        data[27] <= 628;
        data[28] <= 100;
        data[29] <= -5561;
        data[30] <= -7343;
        data[31] <= 2353;
        data[32] <= 179;
        data[33] <= 2181;
        data[34] <= -1316;
        data[35] <= -6080;
        data[36] <= 3239;
        data[37] <= -5159;
        data[38] <= 1331;
        data[39] <= 7550;
        data[40] <= 2572;
        data[41] <= 6280;
        data[42] <= 1000;
        data[43] <= 5834;
        data[44] <= 3375;
        data[45] <= -7192;
        data[46] <= 1790;
        data[47] <= 6449;
        data[48] <= 2201;
        data[49] <= 644;
        data[50] <= 1668;
        data[51] <= -5507;
        data[52] <= -2051;
        data[53] <= -1305;
        data[54] <= -5002;
        data[55] <= 1356;
        data[56] <= -5361;
        data[57] <= -3104;
        data[58] <= 3028;
        data[59] <= 4885;
        data[60] <= 2539;
        data[61] <= 3046;
        data[62] <= 6649;
        data[63] <= 6440;
        data[64] <= 1319;
        data[65] <= 6374;
        data[66] <= -5149;
        data[67] <= 2311;
        data[68] <= -3937;
        data[69] <= -1801;
        data[70] <= -7527;
        data[71] <= -318;
        data[72] <= -442;
        data[73] <= 2767;
        data[74] <= -5332;
        data[75] <= -262;
        data[76] <= 5046;
        data[77] <= 2956;
        data[78] <= -2171;
        data[79] <= 2296;
        data[80] <= -5407;
        data[81] <= -7612;
        data[82] <= 6713;
        data[83] <= -2649;
        data[84] <= 1535;
        data[85] <= -3180;
        data[86] <= -4420;
        data[87] <= -3052;
        data[88] <= -7237;
        data[89] <= -2620;
        data[90] <= 4377;
        data[91] <= -1162;
        data[92] <= -6349;
        data[93] <= 7599;
        data[94] <= 7374;
        data[95] <= 685;
        data[96] <= 5686;
        data[97] <= 4232;
        data[98] <= -11;
        data[99] <= -1078;
        data[100] <= 1883;
        data[101] <= 202;
        data[102] <= 4435;
        data[103] <= 4522;
        data[104] <= -2313;
        data[105] <= 3741;
        data[106] <= -2046;
        data[107] <= -815;
        data[108] <= -3065;
        data[109] <= 6850;
        data[110] <= -4584;
        data[111] <= -3763;
        data[112] <= -110;
        data[113] <= 4581;
        data[114] <= 3469;
        data[115] <= 2020;
        data[116] <= -1733;
        data[117] <= -863;
        data[118] <= 7592;
        data[119] <= 6688;
        data[120] <= -5099;
        data[121] <= 7211;
        data[122] <= 72;
        data[123] <= 7056;
        data[124] <= 243;
        data[125] <= -6908;
        data[126] <= -1100;
        data[127] <= -273;
        data[128] <= 3968;
        data[129] <= 4839;
        data[130] <= -1969;
        data[131] <= 6731;
        data[132] <= -885;
        data[133] <= 5436;
        data[134] <= -4907;
        data[135] <= -4695;
        data[136] <= 720;
        data[137] <= -6245;
        data[138] <= 2430;
        data[139] <= -7636;
        data[140] <= 4361;
        data[141] <= -2730;
        data[142] <= -6403;
        data[143] <= 2307;
        data[144] <= -4329;
        data[145] <= 5866;
        data[146] <= 6511;
        data[147] <= -7084;
        data[148] <= -2987;
        data[149] <= -867;
        data[150] <= 7200;
        data[151] <= -1006;
        data[152] <= -6422;
        data[153] <= 445;
        data[154] <= -2473;
        data[155] <= 3422;
        data[156] <= -2586;
        data[157] <= -7652;
        data[158] <= 2793;
        data[159] <= -2784;
        data[160] <= 3666;
        data[161] <= 5965;
        data[162] <= 852;
        data[163] <= 6691;
        data[164] <= -4805;
        data[165] <= 5301;
        data[166] <= -2776;
        data[167] <= 4450;
        data[168] <= 5992;
        data[169] <= 3498;
        data[170] <= 4862;
        data[171] <= 285;
        data[172] <= -2792;
        data[173] <= 2882;
        data[174] <= 5938;
        data[175] <= -1794;
        data[176] <= -6841;
        data[177] <= 5466;
        data[178] <= -1967;
        data[179] <= 6927;
        data[180] <= 2962;
        data[181] <= -1583;
        data[182] <= -1524;
        data[183] <= 4258;
        data[184] <= 2537;
        data[185] <= 2850;
        data[186] <= 2802;
        data[187] <= -1902;
        data[188] <= -2064;
        data[189] <= -2579;
        data[190] <= -6966;
        data[191] <= -6784;
        data[192] <= -4309;
        data[193] <= -7535;
        data[194] <= -1102;
        data[195] <= -469;
        data[196] <= 121;
        data[197] <= -3503;
        data[198] <= -5352;
        data[199] <= -2222;
        data[200] <= -2702;
        data[201] <= -3659;
        data[202] <= -5279;
        data[203] <= 4932;
        data[204] <= 7145;
        data[205] <= -6396;
        data[206] <= 2993;
        data[207] <= 1455;
        data[208] <= 4341;
        data[209] <= -4690;
        data[210] <= 1210;
        data[211] <= -4308;
        data[212] <= -7437;
        data[213] <= -6859;
        data[214] <= 3702;
        data[215] <= -5868;
        data[216] <= -6707;
        data[217] <= 3237;
        data[218] <= -5355;
        data[219] <= -2516;
        data[220] <= -792;
        data[221] <= -811;
        data[222] <= -2673;
        data[223] <= -817;
        data[224] <= -3261;
        data[225] <= 3003;
        data[226] <= 2435;
        data[227] <= -7146;
        data[228] <= 6298;
        data[229] <= 2764;
        data[230] <= -5626;
        data[231] <= 1648;
        data[232] <= -7467;
        data[233] <= 5562;
        data[234] <= 7441;
        data[235] <= 7251;
        data[236] <= 3992;
        data[237] <= 7191;
        data[238] <= -1888;
        data[239] <= -692;
        data[240] <= -6372;
        data[241] <= 5345;
        data[242] <= 1536;
        data[243] <= -3082;
        data[244] <= 5184;
        data[245] <= 1119;
        data[246] <= 2135;
        data[247] <= -5824;
        data[248] <= -2395;
        data[249] <= -4295;
        data[250] <= -6163;
        data[251] <= -4895;
        data[252] <= -3519;
        data[253] <= -6920;
        data[254] <= -2276;
        data[255] <= 7367;
        data[256] <= -1;
        data[257] <= -98;
        data[258] <= 5757;
        data[259] <= -4171;
        data[260] <= 5989;
        data[261] <= 3204;
        data[262] <= 6772;
        data[263] <= 3133;
        data[264] <= -186;
        data[265] <= -2867;
        data[266] <= -4468;
        data[267] <= 7605;
        data[268] <= -7399;
        data[269] <= -3135;
        data[270] <= -10;
        data[271] <= -980;
        data[272] <= -3874;
        data[273] <= 4373;
        data[274] <= -1554;
        data[275] <= 1318;
        data[276] <= 6276;
        data[277] <= 608;
        data[278] <= -1860;
        data[279] <= 2052;
        data[280] <= 1403;
        data[281] <= -755;
        data[282] <= 2815;
        data[283] <= -628;
        data[284] <= -100;
        data[285] <= 5561;
        data[286] <= 7343;
        data[287] <= -2353;
        data[288] <= -179;
        data[289] <= -2181;
        data[290] <= 1316;
        data[291] <= 6080;
        data[292] <= -3239;
        data[293] <= 5159;
        data[294] <= -1331;
        data[295] <= -7550;
        data[296] <= -2572;
        data[297] <= -6280;
        data[298] <= -1000;
        data[299] <= -5834;
        data[300] <= -3375;
        data[301] <= 7192;
        data[302] <= -1790;
        data[303] <= -6449;
        data[304] <= -2201;
        data[305] <= -644;
        data[306] <= -1668;
        data[307] <= 5507;
        data[308] <= 2051;
        data[309] <= 1305;
        data[310] <= 5002;
        data[311] <= -1356;
        data[312] <= 5361;
        data[313] <= 3104;
        data[314] <= -3028;
        data[315] <= -4885;
        data[316] <= -2539;
        data[317] <= -3046;
        data[318] <= -6649;
        data[319] <= -6440;
        data[320] <= -1319;
        data[321] <= -6374;
        data[322] <= 5149;
        data[323] <= -2311;
        data[324] <= 3937;
        data[325] <= 1801;
        data[326] <= 7527;
        data[327] <= 318;
        data[328] <= 442;
        data[329] <= -2767;
        data[330] <= 5332;
        data[331] <= 262;
        data[332] <= -5046;
        data[333] <= -2956;
        data[334] <= 2171;
        data[335] <= -2296;
        data[336] <= 5407;
        data[337] <= 7612;
        data[338] <= -6713;
        data[339] <= 2649;
        data[340] <= -1535;
        data[341] <= 3180;
        data[342] <= 4420;
        data[343] <= 3052;
        data[344] <= 7237;
        data[345] <= 2620;
        data[346] <= -4377;
        data[347] <= 1162;
        data[348] <= 6349;
        data[349] <= -7599;
        data[350] <= -7374;
        data[351] <= -685;
        data[352] <= -5686;
        data[353] <= -4232;
        data[354] <= 11;
        data[355] <= 1078;
        data[356] <= -1883;
        data[357] <= -202;
        data[358] <= -4435;
        data[359] <= -4522;
        data[360] <= 2313;
        data[361] <= -3741;
        data[362] <= 2046;
        data[363] <= 815;
        data[364] <= 3065;
        data[365] <= -6850;
        data[366] <= 4584;
        data[367] <= 3763;
        data[368] <= 110;
        data[369] <= -4581;
        data[370] <= -3469;
        data[371] <= -2020;
        data[372] <= 1733;
        data[373] <= 863;
        data[374] <= -7592;
        data[375] <= -6688;
        data[376] <= 5099;
        data[377] <= -7211;
        data[378] <= -72;
        data[379] <= -7056;
        data[380] <= -243;
        data[381] <= 6908;
        data[382] <= 1100;
        data[383] <= 273;
        data[384] <= -3968;
        data[385] <= -4839;
        data[386] <= 1969;
        data[387] <= -6731;
        data[388] <= 885;
        data[389] <= -5436;
        data[390] <= 4907;
        data[391] <= 4695;
        data[392] <= -720;
        data[393] <= 6245;
        data[394] <= -2430;
        data[395] <= 7636;
        data[396] <= -4361;
        data[397] <= 2730;
        data[398] <= 6403;
        data[399] <= -2307;
        data[400] <= 4329;
        data[401] <= -5866;
        data[402] <= -6511;
        data[403] <= 7084;
        data[404] <= 2987;
        data[405] <= 867;
        data[406] <= -7200;
        data[407] <= 1006;
        data[408] <= 6422;
        data[409] <= -445;
        data[410] <= 2473;
        data[411] <= -3422;
        data[412] <= 2586;
        data[413] <= 7652;
        data[414] <= -2793;
        data[415] <= 2784;
        data[416] <= -3666;
        data[417] <= -5965;
        data[418] <= -852;
        data[419] <= -6691;
        data[420] <= 4805;
        data[421] <= -5301;
        data[422] <= 2776;
        data[423] <= -4450;
        data[424] <= -5992;
        data[425] <= -3498;
        data[426] <= -4862;
        data[427] <= -285;
        data[428] <= 2792;
        data[429] <= -2882;
        data[430] <= -5938;
        data[431] <= 1794;
        data[432] <= 6841;
        data[433] <= -5466;
        data[434] <= 1967;
        data[435] <= -6927;
        data[436] <= -2962;
        data[437] <= 1583;
        data[438] <= 1524;
        data[439] <= -4258;
        data[440] <= -2537;
        data[441] <= -2850;
        data[442] <= -2802;
        data[443] <= 1902;
        data[444] <= 2064;
        data[445] <= 2579;
        data[446] <= 6966;
        data[447] <= 6784;
        data[448] <= 4309;
        data[449] <= 7535;
        data[450] <= 1102;
        data[451] <= 469;
        data[452] <= -121;
        data[453] <= 3503;
        data[454] <= 5352;
        data[455] <= 2222;
        data[456] <= 2702;
        data[457] <= 3659;
        data[458] <= 5279;
        data[459] <= -4932;
        data[460] <= -7145;
        data[461] <= 6396;
        data[462] <= -2993;
        data[463] <= -1455;
        data[464] <= -4341;
        data[465] <= 4690;
        data[466] <= -1210;
        data[467] <= 4308;
        data[468] <= 7437;
        data[469] <= 6859;
        data[470] <= -3702;
        data[471] <= 5868;
        data[472] <= 6707;
        data[473] <= -3237;
        data[474] <= 5355;
        data[475] <= 2516;
        data[476] <= 792;
        data[477] <= 811;
        data[478] <= 2673;
        data[479] <= 817;
        data[480] <= 3261;
        data[481] <= -3003;
        data[482] <= -2435;
        data[483] <= 7146;
        data[484] <= -6298;
        data[485] <= -2764;
        data[486] <= 5626;
        data[487] <= -1648;
        data[488] <= 7467;
        data[489] <= -5562;
        data[490] <= -7441;
        data[491] <= -7251;
        data[492] <= -3992;
        data[493] <= -7191;
        data[494] <= 1888;
        data[495] <= 692;
        data[496] <= 6372;
        data[497] <= -5345;
        data[498] <= -1536;
        data[499] <= 3082;
        data[500] <= -5184;
        data[501] <= -1119;
        data[502] <= -2135;
        data[503] <= 5824;
        data[504] <= 2395;
        data[505] <= 4295;
        data[506] <= 6163;
        data[507] <= 4895;
        data[508] <= 3519;
        data[509] <= 6920;
        data[510] <= 2276;
        data[511] <= -7367;
    end

endmodule

