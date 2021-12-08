`timescale 1ns/100ps

module tb_ntt;

    parameter RUNS = 1;
    parameter HALFCLK = 5;
    localparam FULLCLK = 2 * HALFCLK;

    /* clock setting */
    reg clk;
        initial begin
        clk=0;
    end
    always #(HALFCLK) clk<=~clk;

    /* vcd file setting */
    initial begin
        //$fsdbDumpfile("tb_ntt.fsdb");
        //$fsdbDumpvars;
        #(65536*FULLCLK);
        $finish;
    end

    reg           rst;

    reg   [10:0]  addr [9:0];
    wire  [10:0]  addr1;
    wire  [10:0]  addr3;
    wire  [10:0]  addr4;
    wire  [10:0]  addr5;

    reg   [3:0]   start;
    wire          start3;
    reg   [3:0]   input_fg;
    wire          input_fg3;

    reg         [12:0]  din;
    wire        [13:0]  dout;
    wire                valid;

    wire  [13:0]  f_dout;
    wire  [13:0]  g_dout;
    wire  [13:0]  h_dref;
    wire  [13:0]  hp_dref;

    wire          equal;
    wire          equal_p;

    assign addr1 = addr[1];
    assign addr3 = addr[3];
    assign addr4 = addr[4];
    assign addr5 = addr[5];

    assign start3 = start[3];
    assign input_fg3 = input_fg[3];

    ntt ntt0 ( .clk(clk), .rst(rst), .start(start3), .input_fg(input_fg3),
               .addr(addr3), .din(din), .dout(dout), .valid(valid) );

    f_rom  f_r0  ( .clk(clk), .rst(rst), .addr(addr1), .dout(f_dout)  );
    g_rom  g_r0  ( .clk(clk), .rst(rst), .addr(addr1), .dout(g_dout)  );
    h_rom  h_r0  ( .clk(clk), .rst(rst), .addr(addr4), .dout(h_dref)  );
    hp_rom hp_r0 ( .clk(clk), .rst(rst), .addr(addr4), .dout(hp_dref) );

    integer index;
    always @ (posedge clk) begin
      if(rst) begin
        start[3:1] <= 0; input_fg[3:1] <= 0;
        for(index = 1; index <= 9; index = index + 1) begin
          addr[index] <= 'd0;
        end
      end else begin
        start[3:1] <= start[2:0]; input_fg[3:1] <= input_fg[2:0];
        for(index = 1; index <= 9; index = index + 1) begin
          addr[index] <= addr[index-1];
        end
      end
    end

    always @ (posedge clk) begin
      if(rst) begin
        din <= 'sd0;
      end else begin
        if(valid) begin
          din <= 'sd0;
        end else begin
          if(!input_fg) begin
            din <= f_dout;
          end else begin
            din <= g_dout;
          end
        end
      end
    end

    assign equal = (dout == h_dref);
    assign equal_p = (dout == hp_dref);

    integer runs;
    initial begin
      for(runs = 'd0; runs < RUNS; runs = runs + 'd1) begin
        rst = 0; start[0] = 0; input_fg[0] = 0;
        addr[0] = 0;

        #(FULLCLK) rst = 1;
        #(FULLCLK) rst = 0;
        #(FULLCLK);

        input_fg[0] = 0;
        for(addr[0] = 'd0; addr[0] < 'd1535; addr[0] = addr[0] + 'd1) begin
          #(FULLCLK);
        end
        #(8*FULLCLK);

        input_fg[0] = 1;
        for(addr[0] = 'd0; addr[0] < 'd1535; addr[0] = addr[0] + 'd1) begin
          #(FULLCLK);
        end
        #(8*FULLCLK);

        start[0] = 1;
        #(FULLCLK) start[0] = 0;

        wait(valid);
        #(FULLCLK);
        input_fg[0] = 0;
        #(FULLCLK);

        for(addr[0] = 'd0; addr[0] < 'd1535; addr[0] = addr[0] + 'd1) begin
          #(FULLCLK);
          //#(8*FULLCLK);
        end
        #(FULLCLK);
        //#(8*FULLCLK);

        #(128*FULLCLK);

      end
      $finish;
    end

endmodule

