module mod12289s (
    input                 clk,
    input                 rst,
    //input signed  [13:0]  inA,
    //input signed  [13:0]  inB,
    input signed  [26:0]  inZ,
    output reg    [13:0]  outZ
) ;

    reg signed    [26:0]  regZ;

    wire        [2:0]   intC00;
    wire        [2:0]   intC01;
    wire        [2:0]   intC02;
    wire        [2:0]   intC03;
    wire        [3:0]   intC10;
    wire        [3:0]   intC11;
    wire        [4:0]   intC;
    wire        [2:0]   intE;

    wire        [3:0]   intCE;
    wire        [1:0]   intE2;

    wire        [13:0]  intF;

    reg         [14:0]  regP;
    reg         [12:0]  regN;

    wire        [15:0]  intZ;

    always @ ( posedge clk ) begin
        if(rst) begin
            regZ <= 'sd0;
        end else begin
            //regZ <= regA * regB;
            regZ <= inZ;
        end
    end

    //assign intC = regZ[25:24] + regZ[23:22] + regZ[21:20] + regZ[19:18] + regZ[17:16] + regZ[15:14] + regZ[13:12];
    assign intC00 = regZ[15:14] + regZ[13:12];
    assign intC01 = regZ[19:18] + regZ[17:16];
    assign intC02 = regZ[23:22] + regZ[21:20];
    assign intC03 = { 1'b0, regZ[25:24] };
    assign intC10 = intC00 + intC01;
    assign intC11 = intC02 + intC03;
    assign intC = intC10 + intC11;

    assign intE = intC[4] + intC[3:2] + intC[1:0];
    assign intCE = intE[2] + intC[4] + intC[4:2];
    assign intE2 = intE[2] + intE[1:0];

    assign intF = { intE2, regZ[11:0] } - { 10'b0, intCE };

    always @ ( posedge clk ) begin
        if(rst) begin
            regP <= 'd0;
            regN <= 'd0;
        end else begin
            regP[10:0] <= intF[10:0];
            regP[14:11] <= { 1'b0, intF[13:11] } + { 3'b0, $unsigned(regZ[26]) };
            regN <= $unsigned(regZ[25:24]) +
                    $unsigned(regZ[25:22]) + 
                    $unsigned(regZ[25:20]) +
                    $unsigned(regZ[25:18]) +
                    $unsigned(regZ[25:16]) +
                    $unsigned(regZ[25:14]) +
                    (regZ[26] ? 'd683 : 'd0);
        end
    end

    assign intZ = { 1'b0, regP } - { 3'b0, regN };

    always @ ( posedge clk ) begin
        if(rst) begin
            outZ <= 'sd0;
        end else begin
            if(intZ[15] || $unsigned(intZ[14:0]) <= 'sd6144) begin
                outZ <= intZ[13:0];
            end else begin
                outZ <= intZ[14:0] - 'd12289;
            end
        end
    end

endmodule

