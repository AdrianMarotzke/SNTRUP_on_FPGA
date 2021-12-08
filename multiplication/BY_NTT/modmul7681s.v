/*******************************************************************
 * Signed Modular Multiplication with Prime Q = 7681
 *
 * Author: Bo-Yuan Peng
 *
 * Description:
 * This is a verilog module doing signed modular multiplication
 *                 outC == inA * inB (mod^{+-} 7681)
 * 
 *                                      Diligent          Lazy
 * -- inA:  signed 13-bit integer in [-3840, 3840] or [-3584, 4095].
 * -- inB:  signed 13-bit integer in [-3840, 3840] or [-3584, 4095].
 * -- outC: signed 13-bit integer in [-3840, 3840] or [-3584, 4095].
 *
 * Version Info:
 *    Mar.19,2021: 0.0.1 creation of the module.
 *    Mar.31.2021: 0.1.0 module design complete without critical
 *                       path length control.
 *    May 31.2021: 0.2.0 revision for critical paths balancing and
 *                       dataflow control.
 *******************************************************************/

module modmul7681s (
  input                     clk,
  //input signed      [12:0]  inA,
  //input signed      [12:0]  inB,
  input signed      [24:0]  inZ,
  output reg signed [12:0]  outC
) ;

  reg signed        [24:0]  mZ;
  reg               [8:0]   mZlow;

  wire              [4:0]   mZpu_p0;
  wire              [4:0]   mZpu_p1;

  reg               [5:0]   mZpu;
  reg               [1:0]   mZpC;
  reg               [3:0]   mZp3u;
  reg               [12:0]  mZp0;

  reg               [11:0]  mZn_p0;
  wire              [11:0]  mZn_p0a;
  reg               [11:0]  mZn_p1;
  wire              [12:0]  mZn2;

  reg               [12:0]  mZn0;

  wire signed       [13:0]  mZpn;
  wire signed       [13:0]  mQ;

  //always @ ( posedge clk ) begin
  always @ (*) begin
    //mZ <= inA * inB;
    //mZ = inA * inB;
    //mZ <= inZ;
    mZ = inZ;
  end

  assign mZpu_p0 = mZ[20:17] + { 1'b0, mZ[23:21] };
  assign mZpu_p1 = mZ[12:9] + mZ[16:13];
  always @ ( posedge clk ) begin
  //always @ (*) begin
    mZpu <= mZpu_p0 + mZpu_p1; 
    //mZpu = mZpu_p0 + mZpu_p1;
    mZlow <= mZ[8:0];
    //mZlow = mZ[8:0];
  end

  always @ (*) begin
    case(mZpu)
      6'd0: begin mZpC = 2'd0; mZp3u = 4'd0; end
      6'd1: begin mZpC = 2'd0; mZp3u = 4'd1; end
      6'd2: begin mZpC = 2'd0; mZp3u = 4'd2; end
      6'd3: begin mZpC = 2'd0; mZp3u = 4'd3; end
      6'd4: begin mZpC = 2'd0; mZp3u = 4'd4; end
      6'd5: begin mZpC = 2'd0; mZp3u = 4'd5; end
      6'd6: begin mZpC = 2'd0; mZp3u = 4'd6; end
      6'd7: begin mZpC = 2'd0; mZp3u = 4'd7; end
      6'd8: begin mZpC = 2'd0; mZp3u = 4'd8; end
      6'd9: begin mZpC = 2'd0; mZp3u = 4'd9; end
      6'd10: begin mZpC = 2'd0; mZp3u = 4'd10; end
      6'd11: begin mZpC = 2'd0; mZp3u = 4'd11; end
      6'd12: begin mZpC = 2'd0; mZp3u = 4'd12; end
      6'd13: begin mZpC = 2'd0; mZp3u = 4'd13; end
      6'd14: begin mZpC = 2'd0; mZp3u = 4'd14; end
      6'd15: begin mZpC = 2'd0; mZp3u = 4'd15; end
      6'd16: begin mZpC = 2'd1; mZp3u = 4'd1; end
      6'd17: begin mZpC = 2'd1; mZp3u = 4'd2; end
      6'd18: begin mZpC = 2'd1; mZp3u = 4'd3; end
      6'd19: begin mZpC = 2'd1; mZp3u = 4'd4; end
      6'd20: begin mZpC = 2'd1; mZp3u = 4'd5; end
      6'd21: begin mZpC = 2'd1; mZp3u = 4'd6; end
      6'd22: begin mZpC = 2'd1; mZp3u = 4'd7; end
      6'd23: begin mZpC = 2'd1; mZp3u = 4'd8; end
      6'd24: begin mZpC = 2'd1; mZp3u = 4'd9; end
      6'd25: begin mZpC = 2'd1; mZp3u = 4'd10; end
      6'd26: begin mZpC = 2'd1; mZp3u = 4'd11; end
      6'd27: begin mZpC = 2'd1; mZp3u = 4'd12; end
      6'd28: begin mZpC = 2'd1; mZp3u = 4'd13; end
      6'd29: begin mZpC = 2'd1; mZp3u = 4'd14; end
      6'd30: begin mZpC = 2'd1; mZp3u = 4'd15; end
      6'd31: begin mZpC = 2'd2; mZp3u = 4'd1; end
      6'd32: begin mZpC = 2'd2; mZp3u = 4'd2; end
      6'd33: begin mZpC = 2'd2; mZp3u = 4'd3; end
      6'd34: begin mZpC = 2'd2; mZp3u = 4'd4; end
      6'd35: begin mZpC = 2'd2; mZp3u = 4'd5; end
      6'd36: begin mZpC = 2'd2; mZp3u = 4'd6; end
      6'd37: begin mZpC = 2'd2; mZp3u = 4'd7; end
      6'd38: begin mZpC = 2'd2; mZp3u = 4'd8; end
      6'd39: begin mZpC = 2'd2; mZp3u = 4'd9; end
      6'd40: begin mZpC = 2'd2; mZp3u = 4'd10; end
      6'd41: begin mZpC = 2'd2; mZp3u = 4'd11; end
      6'd42: begin mZpC = 2'd2; mZp3u = 4'd12; end
      6'd43: begin mZpC = 2'd2; mZp3u = 4'd13; end
      6'd44: begin mZpC = 2'd2; mZp3u = 4'd14; end
      6'd45: begin mZpC = 2'd2; mZp3u = 4'd15; end
      6'd46: begin mZpC = 2'd3; mZp3u = 4'd1; end
      6'd47: begin mZpC = 2'd3; mZp3u = 4'd2; end
      6'd48: begin mZpC = 2'd3; mZp3u = 4'd3; end
      6'd49: begin mZpC = 2'd3; mZp3u = 4'd4; end
      6'd50: begin mZpC = 2'd3; mZp3u = 4'd5; end
      6'd51: begin mZpC = 2'd3; mZp3u = 4'd6; end
      6'd52: begin mZpC = 2'd3; mZp3u = 4'd7; end
      default: begin mZpC = 2'd0; mZp3u = 4'd0; end
    endcase
  end

  always @ ( posedge clk ) begin
  //always @ (*) begin
    mZp0 <= { mZp3u, mZlow };
    //mZp0 = { mZp3u, mZlow };
  end

  always @ ( posedge clk ) begin
  //always @ (*) begin
    mZn_p0 <= { 1'b0, {3{mZ[24]}}, mZ[24] & mZ[16], {3{mZ[24] & ~mZ[16]}}, mZ[24] ^ mZ[16], mZ[15:13] };
              // 1912 + mZ[16:13] = (011100000000)_2 | (((01111)_2 + mZ[16]) << 3) | mZ[15:13]
    mZn_p1[11:8] <= mZ[23:21] + { 2'b0, mZpu_p0[4] };
    mZn_p1[7:4]  <= mZpu_p0[3:0] + { 3'b0, mZpu_p0[4] };
    mZn_p1[3:0]  <= mZpu_p0[3:0];
    //mZn_p0 = { 1'b0, {3{mZ[24]}}, mZ[24] & mZ[16], {3{mZ[24] & ~mZ[16]}}, mZ[24] ^ mZ[16], mZ[15:13] };
    //         // 1912 + mZ[16:13] = (011100000000)_2 | (((01111)_2 + mZ[16]) << 3) | mZ[15:13]
    //mZn_p1[11:8] = mZ[23:21] + { 2'b0, mZpu_p0[4] };
    //mZn_p1[7:4]  = mZpu_p0[3:0] + { 3'b0, mZpu_p0[4] };
    //mZn_p1[3:0]  = mZpu_p0[3:0];
  end

  assign mZn_p0a[11:8] = mZn_p0[11:8];
  assign mZn_p0a[7:0]  = mZn_p0[7:0] + { 6'b0, mZpC };

  always @ ( posedge clk ) begin
  //always @ (*) begin
    mZn0 <= mZn_p0a + mZn_p1;
    //mZn0 = mZn_p0a + mZn_p1;
  end

  assign mZpn = mZp0 - mZn0;
  
  /********** Deligent reduction to [-3840, 3840] **********/
  assign mQ = (mZpn > 3840) ? ('sd7681) : ('sd0);
  /************ Lazy Reduction to [-3584, 4095] ************/
  //assign mQ = (mZpn[13:12] == 2'b01) ? ('sd7681) : ('sd0);

  always @ ( posedge clk ) begin
    outC <= mZpn - mQ;
  end

endmodule

