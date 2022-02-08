/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : piso.sv (parallel in serial out)
|
| testbench: piso_tb.sv
| 
| brief    :
|
| todo     :
|
| 13.12.21 : created
|
*/

/*
piso # 
(
    .DATA_WIDTH   (), // default: 8
    .DO_MSB_FIRST (), // default: "true", cases: "true", "false"
    .DO_FAST      ()  // default: "true", cases: "true", "false"
)
piso_inst                         
(
    .i_clk        (),
    .i_s_rst_n    (),

    .i_wr_en      (),
    .i_data       (), // width: DATA_WIDTH

    .o_data_valid (),
    .o_data       ()
);
*/

`include "platform.vh"

`timescale 1ns / 1ps

module piso # 
(
    parameter integer DATA_WIDTH   = 8,
    parameter         DO_MSB_FIRST = "true",
    parameter         DO_FAST      = "true"      
)
(
    input  logic                     i_clk,
    input  logic                     i_s_rst_n,

    input  logic                     i_wr_en,
    input  logic  [DATA_WIDTH - 1:0] i_data,

    output logic                     o_data_valid,
    output logic                     o_data
);
    localparam integer MSB    = DATA_WIDTH - 1;
    localparam integer LSB    = 0;
    localparam integer SH_BIT = (DO_MSB_FIRST == "true") ? MSB : LSB;

    logic [DATA_WIDTH - 1 : 0] buff;

generate
    if (DO_MSB_FIRST == "true") begin : msb_mode
        always_ff @ (posedge i_clk) begin
            if (i_s_rst_n == '0) begin
                buff <= '0;
            end
            else begin
                buff <= (i_wr_en == '1) ? i_data : {buff[MSB - 1 : LSB], 1'h0};
            end
        end
    end
    else begin  : lsb_mode 
        always_ff @ (posedge i_clk) begin 
            if (i_s_rst_n == '0) begin
                buff <= '0;
            end
            else begin
                buff <= (i_wr_en == '1) ?  i_data :  {1'h0, buff[MSB : LSB + 1]}; 
            end 
        end
    end
endgenerate

generate 
    if (DO_FAST == "true") begin : fast_mode 
        assign o_data       = (i_wr_en == '1) ? i_data[SH_BIT] : buff[SH_BIT];
        assign o_data_valid = '1;
    end
    else begin : std_mode 
        always_ff @ (posedge i_clk) begin 
            if (i_s_rst_n == '0) begin
                o_data       <= '0;
                o_data_valid <= '0;
            end
            else begin
                o_data       <= buff[SH_BIT]; 
                o_data_valid <= !i_wr_en;
            end 
        end
    end
endgenerate  
endmodule