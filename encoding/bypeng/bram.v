module bram_n ( clk, wr_en, wr_addr, rd_addr, wr_din, wr_dout, rd_dout );

    parameter D_SIZE = 64;
    parameter Q_DEPTH = 8;

    localparam Q_SIZE = 1 << Q_DEPTH;

    input   clk;
    input   wr_en;
    input   [Q_DEPTH-1:0]   wr_addr;
    input   [Q_DEPTH-1:0]   rd_addr;
    input   [D_SIZE-1:0]    wr_din;
    output  [D_SIZE-1:0]    wr_dout;
    output  [D_SIZE-1:0]    rd_dout;

    reg     [D_SIZE-1:0]    ram [Q_SIZE-1:0];
    reg     [Q_DEPTH-1:0]   reg_wra;
    reg     [Q_DEPTH-1:0]   reg_rda;

    always @ (negedge clk) begin
        if(wr_en) begin
            ram[wr_addr] <= wr_din;
        end
        reg_wra <= wr_addr;
        reg_rda <= rd_addr;
    end

    assign wr_dout = ram[reg_wra];
    assign rd_dout = ram[reg_rda];

endmodule

module bram_p ( clk, wr_en, wr_addr, rd_addr, wr_din, wr_dout, rd_dout );

    parameter D_SIZE = 64;
    parameter Q_DEPTH = 8;

    localparam Q_SIZE = 1 << Q_DEPTH;

    input   clk;
    input   wr_en;
    input   [Q_DEPTH-1:0]   wr_addr;
    input   [Q_DEPTH-1:0]   rd_addr;
    input   [D_SIZE-1:0]    wr_din;
    output  [D_SIZE-1:0]    wr_dout;
    output  [D_SIZE-1:0]    rd_dout;

    reg     [D_SIZE-1:0]    ram [Q_SIZE-1:0];
    reg     [Q_DEPTH-1:0]   reg_wra;
    reg     [Q_DEPTH-1:0]   reg_rda;

    always @ (posedge clk) begin
        if(wr_en) begin
            ram[wr_addr] <= wr_din;
        end
        reg_wra <= wr_addr;
        reg_rda <= rd_addr;
    end

    assign wr_dout = ram[reg_wra];
    assign rd_dout = ram[reg_rda];

endmodule

