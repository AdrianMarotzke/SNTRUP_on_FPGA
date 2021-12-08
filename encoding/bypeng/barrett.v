module barrett ( clk, dividend, m0, m0_inverse, quotient, remainder ) ;

    parameter M0LEN = 14;
    parameter SHIFT = 27;

    localparam M0LEN2 = M0LEN * 2;

    input  wire                     clk;
    input  wire [M0LEN2-1:0]        dividend;
    input  wire [M0LEN-1:0]         m0;
    input  wire [SHIFT-1:0]         m0_inverse;
    output wire [M0LEN-1:0]         quotient;
    output wire [M0LEN-1:0]         remainder;

    reg         [M0LEN2-1:0]        dividend_relay;

    wire        [M0LEN2+SHIFT-1:0]  quo2;
    reg         [M0LEN-1:0]         q0;
    reg         [M0LEN-1:0]         q0_relay;
    reg         [M0LEN-1:0]         r0;

    reg         [M0LEN-1:0]         m0_relay0;
    reg         [M0LEN-1:0]         m0_relay1;

    wire        [M0LEN-1:0]         q1;
    wire        [M0LEN:0]           r1;
    
    assign quo2 = { { SHIFT {1'b0} }, dividend } * { { M0LEN2 {1'b0} }, m0_inverse };

    always @ (posedge clk) begin
        q0 <= quo2[SHIFT +: M0LEN];
        dividend_relay <= dividend;
        m0_relay0 <= m0;
    end

    always @ (posedge clk) begin
        r0 <= dividend_relay - { { M0LEN {1'b0} }, q0 } * { { M0LEN {1'b0} }, m0_relay0 };
        m0_relay1 <= m0_relay0;
        q0_relay <= q0;
    end

    assign q1 = q0_relay + { { (M0LEN - 1) {1'b0} }, {1'b1} };
    assign r1 = { 1'b0, r0 } - { 1'b0, m0_relay1 };

    assign quotient = r1[M0LEN] ? q0_relay : q1;
    assign remainder = r1[M0LEN] ? r0 : r1[M0LEN-1:0];

endmodule

