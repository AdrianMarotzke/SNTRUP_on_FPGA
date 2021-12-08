/*******************************************************************
 * R_4591 signed reduction directly without using more DSP Slice.
 *
 * Author: Bo-Yuan Peng       bypeng@crypto.tw
 *
 * Description:
 * Main module. Use with Table Looking Up Part.
 *
 * Version Info:
 *    Nov.20,2019: 0.1.0 Design ready.
 *    Dec. 3,2019: 0.2.0 Support for 28-bit signed value.
 *******************************************************************/


module modmul4591S ( Clk, Reset, Input, Output );

    input                       Clk;
	input						Reset;
    input signed        [27:0]  Input;
    output reg          [12:0]  Output;

    reg signed  [27:0]  regZ;

    wire        [11:0]  intP0;
    wire        [11:0]  intP1;
    wire        [11:0]  intN0;
    wire        [11:0]  intN1;

    wire        [12:0]  intP;
    wire        [12:0]  intN;

    reg         [13:0]  regD;
    reg         [13:0]  intMODQ;

    wire        [13:0]  intAB;
	
/*
	wire in_out_of_range;
	wire out_out_of_range;
	
	assign in_out_of_range = (In > 5267025 || In < -5267025) ? 1 : 0;
	assign out_out_of_range = ($signed(Out) > 2295 || $signed(Out) < -2295) ? 1 : 0;
*/
    always @ ( posedge Clk ) begin
        if(Reset)
			regZ <= 0;
		else 
			regZ <= Input[27:0];
    end

    mod4591Svec28 m4591Sv0 ( .z_in(regZ), .p0(intP0), .p1(intP1), .n0(intN0), .n1(intN1) );

    //always @ ( posedge clk ) begin
    //    regP <= intP0 + intP1;
    //    regN <= intN0 + intN1;
    //end
    assign intP = intP0 + intP1;
    assign intN = intN0 + intN1;

    always @ ( posedge Clk ) begin
        //regD <= { 1'b0, regP } - { 1'b0, regN };
        regD <= { 1'b0, intP } - { 1'b0, intN };
    end

    always @ (*) begin
        case(regD[13:10])
            4'h7:                           intMODQ = 15'h5c22; // -9182 if  7168 <= regD
            4'h2, 4'h3, 4'h4, 4'h5, 4'h6:   intMODQ = 15'h6e11; // -4591 if  2048 <= regD <=  7167
            4'he, 4'hf, 4'h0, 4'h1:         intMODQ = 15'h0000; //     0 if -2048 <= regD <=  2047
            4'h9, 4'ha, 4'hb, 4'hc, 4'hd:   intMODQ = 15'h11ef; //  4591 if -7168 <= regD <= -2049
            4'h8:                           intMODQ = 15'h23de; //  9182 if          regD <= -7169
        endcase
    end

    assign intAB = { regD[13], regD } + intMODQ;

    always @ ( posedge Clk ) begin
        if(Reset)
			Output <= 0;
			
		
		else if($signed(intAB[12:0])>2295)
			Output <= $signed(intAB[12:0]) - 4591;
		else if($signed(intAB[12:0])< -2295)
			Output <= $signed(intAB[12:0]) + 4591;
		
		else 
			Output <= $signed(intAB[12:0]);
			
    end

endmodule

