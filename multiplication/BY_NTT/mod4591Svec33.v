module mod4591Svec33 (
    input               clk,
    input               rst,
    input       [32:0]  z_in,
    output reg  [11:0]  p0,
    output reg  [11:0]  p1,
    output reg  [11:0]  p2,
    output reg  [11:0]  n0,
    output reg  [11:0]  n1,
    output reg  [11:0]  n2
) ;

    // z_in[11:0]: 0 ~ 4095
    always @ (posedge clk) begin
        if(rst)
            p0 <= 12'd0;
        else
            p0 <= z_in[11:0];
    end

    // z_in[30, 22, 17, 14]: 0 ~ 4076 <= 4095
    always @ (posedge clk) begin
        if(rst) begin
            p1 <= 12'd0;
        end else begin
            case({ z_in[30], z_in[22], z_in[17], z_in[14] })
                4'h0: p1 <= 12'd0;
                4'h1: p1 <= 12'd2611;
                4'h2: p1 <= 12'd2524;
                4'h3: p1 <= 12'd544;
                4'h4: p1 <= 12'd2721;
                4'h5: p1 <= 12'd741;
                4'h6: p1 <= 12'd654;
                4'h7: p1 <= 12'd3265;
                4'h8: p1 <= 12'd3335;
                4'h9: p1 <= 12'd1355;
                4'ha: p1 <= 12'd1268;
                4'hb: p1 <= 12'd3879;
                4'hc: p1 <= 12'd1465;
                4'hd: p1 <= 12'd4076;
                4'he: p1 <= 12'd3989;
                4'hf: p1 <= 12'd2009;
            endcase
        end
    end

    // z_in[-32, 23, 19, 18, 15]: 0 ~ 3286 <= 3601, +4590 <= 8191
    always @ (posedge clk) begin
        if(rst) begin
            p2 <= 12'd0;
        end else begin
            case({ z_in[32], z_in[23], z_in[19], z_in[18], z_in[15] })
                5'h00: p2 <= 12'd0;
                5'h01: p2 <= 12'd631;
                5'h02: p2 <= 12'd457;
                5'h03: p2 <= 12'd1088;
                5'h04: p2 <= 12'd914;
                5'h05: p2 <= 12'd1545;
                5'h06: p2 <= 12'd1371;
                5'h07: p2 <= 12'd2002;
                5'h08: p2 <= 12'd851;
                5'h09: p2 <= 12'd1482;
                5'h0a: p2 <= 12'd1308;
                5'h0b: p2 <= 12'd1939;
                5'h0c: p2 <= 12'd1765;
                5'h0d: p2 <= 12'd2396;
                5'h0e: p2 <= 12'd2222;
                5'h0f: p2 <= 12'd2853;
                5'h10: p2 <= 12'd433;
                5'h11: p2 <= 12'd1064;
                5'h12: p2 <= 12'd890;
                5'h13: p2 <= 12'd1521;
                5'h14: p2 <= 12'd1347;
                5'h15: p2 <= 12'd1978;
                5'h16: p2 <= 12'd1804;
                5'h17: p2 <= 12'd2435;
                5'h18: p2 <= 12'd1284;
                5'h19: p2 <= 12'd1915;
                5'h1a: p2 <= 12'd1741;
                5'h1b: p2 <= 12'd2372;
                5'h1c: p2 <= 12'd2198;
                5'h1d: p2 <= 12'd2829;
                5'h1e: p2 <= 12'd2655;
                5'h1f: p2 <= 12'd3286;
            endcase
        end
    end

    // -z_in[29, 28, 25, 21, 13]: 0 ~ 4054 <= 4095
    always @ (posedge clk) begin
        if(rst) begin
            n0 <= 12'd0;
        end else begin    
            case({ z_in[29], z_in[28], z_in[25], z_in[21], z_in[13] })
                5'h00: n0 <= 12'd0;
                5'h01: n0 <= 12'd990;
                5'h02: n0 <= 12'd935;
                5'h03: n0 <= 12'd1925;
                5'h04: n0 <= 12'd1187;
                5'h05: n0 <= 12'd2177;
                5'h06: n0 <= 12'd2122;
                5'h07: n0 <= 12'd3112;
                5'h08: n0 <= 12'd314;
                5'h09: n0 <= 12'd1304;
                5'h0a: n0 <= 12'd1249;
                5'h0b: n0 <= 12'd2239;
                5'h0c: n0 <= 12'd1501;
                5'h0d: n0 <= 12'd2491;
                5'h0e: n0 <= 12'd2436;
                5'h0f: n0 <= 12'd3426;
                5'h10: n0 <= 12'd628;
                5'h11: n0 <= 12'd1618;
                5'h12: n0 <= 12'd1563;
                5'h13: n0 <= 12'd2553;
                5'h14: n0 <= 12'd1815;
                5'h15: n0 <= 12'd2805;
                5'h16: n0 <= 12'd2750;
                5'h17: n0 <= 12'd3740;
                5'h18: n0 <= 12'd942;
                5'h19: n0 <= 12'd1932;
                5'h1a: n0 <= 12'd1877;
                5'h1b: n0 <= 12'd2867;
                5'h1c: n0 <= 12'd2129;
                5'h1d: n0 <= 12'd3119;
                5'h1e: n0 <= 12'd3064;
                5'h1f: n0 <= 12'd4054;
            endcase
        end
    end

    // -z_in[27, 16, 12]: 0 ~ 3981 <= 4095
    always @ (posedge clk) begin
        if(rst) begin
            n1 <= 12'd0;
        end else begin    
            case({ z_in[27], z_in[16], z_in[12] })
                3'h0: n1 <= 12'd0;
                3'h1: n1 <= 12'd495;
                3'h2: n1 <= 12'd3329;
                3'h3: n1 <= 12'd3824;
                3'h4: n1 <= 12'd157;
                3'h5: n1 <= 12'd652;
                3'h6: n1 <= 12'd3486;
                3'h7: n1 <= 12'd3981;
            endcase
        end
    end

    // -z_in[31, 26, 24, 20]: 0 ~ 3573 <= 3601, +4590 <= 8191
    always @ (posedge clk) begin
        if(rst) begin
            n2 <= 12'd0;
        end else begin    
            case({ z_in[31], z_in[26], z_in[24], z_in[20] })
                4'h0: n2 <= 12'd0;
                4'h1: n2 <= 12'd2763;
                4'h2: n2 <= 12'd2889;
                4'h3: n2 <= 12'd1061;
                4'h4: n2 <= 12'd2374;
                4'h5: n2 <= 12'd546;
                4'h6: n2 <= 12'd672;
                4'h7: n2 <= 12'd3435;
                4'h8: n2 <= 12'd2512;
                4'h9: n2 <= 12'd684;
                4'ha: n2 <= 12'd810;
                4'hb: n2 <= 12'd3573;
                4'hc: n2 <= 12'd295;
                4'hd: n2 <= 12'd3058;
                4'he: n2 <= 12'd3184;
                4'hf: n2 <= 12'd1356;
            endcase
        end
    end

endmodule
