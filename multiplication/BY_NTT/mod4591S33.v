module mod4591S33 ( clk, Reset, In, Out );

    parameter signed  NTRU_Q    = 'sd4591;

    input                       clk;
    input                       Reset;
    input               [32:0]  In;
    output reg          [15:0]  Out;

    wire        [11:0]  intP0;
    wire        [11:0]  intP1;
    wire        [11:0]  intP2;
    wire        [11:0]  intN0;
    wire        [11:0]  intN1;
    wire        [11:0]  intN2;

    wire        [12:0]  intP01;
    wire        [13:0]  intP01_m;
    reg         [12:0]  regP01;
    reg         [11:0]  regP2;
    wire        [12:0]  intP;

    wire        [12:0]  intN01;
    wire        [13:0]  intN01_m;
    reg         [12:0]  regN01;
    reg         [11:0]  regN2;
    wire        [12:0]  intN;

    wire        [13:0]  intD;
    reg         [13:0]  regD;

    wire        [3:0]   intD_f;
    reg         [14:0]  intMODQ;
    
    mod4591Svec33 m4591Sv0 ( .clk(clk), .rst(Reset),
                             .z_in(In),
                             .p0(intP0), .p1(intP1), .p2(intP2),
                             .n0(intN0), .n1(intN1), .n2(intN2) );

    assign intP01 = { 1'b0, intP0 } + { 1'b0, intP1 };
    assign intP01_m = { 1'b0, intP01 } + 14'h2e11; // -Q
    assign intN01 = { 1'b0, intN0 } + { 1'b0, intN1 };
    assign intN01_m = { 1'b0, intN01 } + 14'h2e11; // -Q

    // Approach one: 2nd addition in the last stage
    always @ ( posedge clk ) begin
        if(Reset) begin
            regP01 <= 13'd0;
            regN01 <= 13'd0;
            regP2 <= 12'd0;
            regN2 <= 12'd0;
        end else begin
            regP01 <= intP01_m[13] ? intP01 : intP01_m[12:0];
            regN01 <= intN01_m[13] ? intN01 : intN01_m[12:0];
            regP2 <= intP2;
            regN2 <= intN2;
        end
    end

    assign intP = regP01 + { 1'b0, regP2 };
    assign intN = regN01 + { 1'b0, regN2 };
    assign intD = { 1'b0, intP } - { 1'b0, intN };

    assign intD_f[3] = ($signed(intD) > 'sd6886);
    assign intD_f[2] = ($signed(intD) > 'sd2295);
    assign intD_f[1] = ($signed(intD) > -'sd2296);
    assign intD_f[0] = ($signed(intD) > -'sd6887);

    // Diligent Reduction
    always @ (*) begin
        casez(intD_f)
           4'b1???: intMODQ = 15'h5c22; // -9182 if  6887 <= intD
           4'b01??: intMODQ = 15'h6e11; // -4591 if  2296 <= intD <=  6886
           4'b001?: intMODQ = 15'h0000; //     0 if -2295 <= intD <=  2295
           4'b0001: intMODQ = 15'h11ef; //  4591 if -6886 <= intD <= -2296
           4'b0000: intMODQ = 15'h23de; //  9182 if          intD <= -6887
        endcase
    end
    // Lazy Reduction
    //always @ (*) begin
    //    case(intD[13:10])
    //        4'h7:                           intMODQ = 15'h5c22; // -9182 if  7168 <= intD
    //        4'h2, 4'h3, 4'h4, 4'h5, 4'h6:   intMODQ = 15'h6e11; // -4591 if  2048 <= intD <=  7167
    //        4'he, 4'hf, 4'h0, 4'h1:         intMODQ = 15'h0000; //     0 if -2048 <= intD <=  2047
    //        4'h9, 4'ha, 4'hb, 4'hc, 4'hd:   intMODQ = 15'h11ef; //  4591 if -7168 <= intD <= -2049
    //        4'h8:                           intMODQ = 15'h23de; //  9182 if          intD <= -7169
    //    endcase
    //end

    always @ ( posedge clk ) begin
        if(Reset) begin
            Out <= 13'sd0;
        end else begin
            Out <= { intD[13], intD } + intMODQ;
        end
    end
    
endmodule

