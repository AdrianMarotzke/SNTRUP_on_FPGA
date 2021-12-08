/*******************************************************************
 * Signed Modular Multiplication with Prime Q = 15361
 *
 * Author: Bo-Yuan Peng
 *
 * Description:
 * This is a verilog module doing signed modular multiplication
 *                 outC == inA * inB (mod^{+-} 15361)
 * 
 *                                      Diligent          Lazy
 * -- inA:  signed 13-bit integer in [-7680, 7680] or [].
 * -- inB:  signed 13-bit integer in [-7680, 7680] or [].
 * -- outC: signed 13-bit integer in [-7680, 7680] or [].
 *
 * Version Info:
 *    Sep.17,2021: 0.1.0 reation of the module.
 *                       module design complete without critical
 *                       path length control.
 *******************************************************************/

module modmul15361s (
  input                     clk,
  input                     rst,
  //input signed      [13:0]  inA,
  //input signed      [13:0]  inB,
  input signed      [26:0]  inZ,
  output reg signed [13:0]  outZ
) ;

  //reg signed        [26:0]  mZ;
  wire signed       [26:0]  mZ;

  reg               [9:0]   mZlow;
  reg                       mZsign;

  wire              [4:0]   mZpu_p0;
  wire              [4:0]   mZpu_p1;

  reg               [5:0]   mZpu;

  wire              [4:0]   mZp2u;

  wire              [2:0]   mZpC;
  wire              [3:0]   mZp3u;
  reg               [13:0]  mZp0;

  reg               [11:0]  mZn_p0;
  wire              [11:0]  mZn_p0a;
  reg               [12:0]  mZn_p1;

  reg               [12:0]  mZn0;

  wire signed       [15:0]  mZpn;
  wire signed       [14:0]  mQ;

  assign mZ = inZ;
  //always @ ( posedge clk ) begin
  //  if(rst) begin
  //    mZ <= 'sd0;
  //  end else begin
  //    //mZ <= inA * inB;
  //    mZ <= inZ;
  //  end
  //end

  assign mZpu_p0 = mZ[21:18] + mZ[25:22];
  assign mZpu_p1 = mZ[13:10] + mZ[17:14];
  always @ ( posedge clk ) begin
    if(rst) begin
      mZpu <= 'd0;
      mZlow <= 'd0;
      mZsign <= 'b0;
    end else begin
      mZpu <= mZpu_p0 + mZpu_p1; 
      mZlow <= mZ[9:0];
      mZsign <= mZ[26];
    end
  end

  assign mZp2u = { 1'b0, mZsign, mZpu[5:4] } + mZpu[3:0];
  assign mZp3u = { 3'b0, mZp2u[4] } + mZp2u[3:0];
  assign mZpC  = mZpu[5:4] + { 1'b0, mZp2u[4] };

  always @ ( posedge clk ) begin
    if(rst) begin
      mZp0 <= 'd0;
    end else begin
      mZp0 <= { mZp3u, mZlow };
    end
  end

  always @ ( posedge clk ) begin
    if(rst) begin
      mZn_p0 <= 'd0;
      mZn_p1 <= 'd0;
    end else begin
      mZn_p0 <= { 2'b0, mZ[26], 1'b0, { 3 { mZ[26] } }, ( mZ[26] ? 5'b01111 : 5'b0 ) + { 1'b0, mZ[17:14] } };
                // 751 + mZ[17:14] = 736 + 15 + mZ[17:14]
                //     = (001011100000)_2 | ((01111)_2 + { 1'b0, mZ[17:14] })
      mZn_p1[12:8] <= mZ[25:22] + { 3'b0, mZpu_p0[4] };
      mZn_p1[7:4]  <= mZpu_p0[3:0] + { 3'b0, mZpu_p0[4] };
      mZn_p1[3:0]  <= mZpu_p0[3:0];
    end
  end

  assign mZn_p0a[11:9] = mZn_p0[11:9];
  assign mZn_p0a[8:0]  = mZn_p0[8:0] + { 6'b0, mZpC };

  always @ ( posedge clk ) begin
  //always @ (*) begin
    mZn0 <= mZn_p0a + mZn_p1;
    //mZn0 = mZn_p0a + mZn_p1;
  end

  assign mZpn = mZp0 - mZn0;
  
  /********** Deligent reduction to [-3840, 3840] **********/
  assign mQ = (mZpn > 7680) ? ('sd15361) : ('sd0);
  /************ Lazy Reduction to [] ************/
  //assign mQ = (??????) ? ('sd7681) : ('sd0);

  always @ ( posedge clk ) begin
    outZ <= mZpn - mQ;
  end

endmodule

