`ifndef PARAMS_V
`define PARAMS_V

`define RP_D_SIZE   (14)
`define RP_D_SIZE2  (`RP_D_SIZE * 2)
`define RP_INV_SIZE (27)
`define RP_DEPTH    (10) /* 1024 at most */
`define RP_DEPTH_2  (`RP_DEPTH - 1)
`define RP_SIZE     (1 << `RP_DEPTH)
`define RP_SIZE_2   (1 << `RP_DEPTH_2)
`define OUT_D_SIZE  (8)
`define OUT_DEPTH   (11) /* 2048 at most */
`define OUT_SIZE    (1 << `OUT_DEPTH)

`endif

