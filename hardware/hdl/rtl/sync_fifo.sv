`timescale 1ns / 1ps

module sync_fifo #
(
    parameter RAM_TYPE   = "distributed", // "distributed", "block"
    parameter DATA_WIDTH = 8
)
(
    input  logic                      clk,
    input  logic                      s_rst_n,
    
    input  logic [DATA_WIDTH - 1 : 0] wr_data,
    input  logic                      wr_en,
    
    output logic                      full,
    output logic                      empty,

    input  logic                      rd_en,

    output logic [DATA_WIDTH - 1 :0 ] rd_data,
    output logic                      rd_data_vld
);




















endmodule
