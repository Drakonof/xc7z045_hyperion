/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : simple_dual_port_ram.sv
|
| testbench: simple_dual_port_ram_tb.sv
| 
| brief    :
|
| todo     :
|
| 08.12.21 : created
| 12.03.21 : the wr_clk and the rd_clk was mremoved
|            the i_clk was add for the wr and the rd
|            i_ and o_ prefecs were added to input and output signals
|            1'h0 were replaced to just '0
|
*/

/*
simple_dual_port_ram #
(
    .DATA_WIDTH     (), // default: 8
    .ADDR_WIDTH     (), // default: 8

    .IS_OUT_LATENCY (), // default: "false", cases: "true", "false"
                    
    .RAM_TYPE       (), // default: "block", cases: "distributed", "block"
    .INIT_FILE_NAME (), // default: ""
)
simple_dual_port_ram_inst
(
    .i_clk           (),
    
    .i_wr_en         (),
    .i_wr_data       (), // width: DATA_WIDTH
    .i_wr_byte_valid (), // width: BYTE_VALID_WIDTH width
    .i_wr_addr       (), // width: ADDR_WIDTH

    .i_rd_en         (),
    .o_rd_data       (), // width: DATA_WIDTH
    .o_rd_data_valid (),
    .i_rd_addr       ()  // width: DATA_WIDTH
);
*/

`timescale 1ns / 1ps

module simple_dual_port_ram #
(
    parameter integer DATA_WIDTH     = 8,
    parameter integer ADDR_WIDTH     = 8,

    parameter         IS_OUT_LATENCY = "false",  //"true", "false"

    parameter         RAM_TYPE       = "block", // "distributed", "block"
    parameter         INIT_FILE_NAME = "", 

    localparam integer BYTE_VALID_WIDTH = DATA_WIDTH / 8  
)
(
    input logic                            i_clk,
    
    input logic                            i_wr_en,
    input logic [DATA_WIDTH - 1 : 0]       i_wr_data,
    input logic [BYTE_VALID_WIDTH - 1 : 0] i_wr_byte_valid,
    input logic [ADDR_WIDTH - 1 : 0]       i_wr_addr,

    input logic                            i_rd_en,
    output logic [DATA_WIDTH - 1 : 0]      o_rd_data,
    output logic                           o_rd_data_valid,
    input logic [ADDR_WIDTH - 1 : 0]       i_rd_addr
);
    localparam integer MEM_DEPTH = 2 ** ADDR_WIDTH;

    (*ram_style = RAM_TYPE*) 
    bit [DATA_WIDTH - 1 : 0] mem[0 : MEM_DEPTH - 1];

    initial begin
        if (INIT_FILE_NAME == "" ) begin
            for (int i = 0; i < MEM_DEPTH; i++) begin
                mem[i] = '0;
            end
        end
        else begin
            $readmemh(INIT_FILE_NAME, mem);
        end
    end

    always_ff @(posedge i_clk) begin  
        if (i_wr_en == 1'h1) begin 
            for (int i = 0; i < BYTE_VALID_WIDTH; i++) begin
                if (i_wr_byte_valid[i] == 1'h1) begin
                    mem[i_wr_addr][(i * 8) +: 8] <= i_wr_data[(i * 8) +: 8];
                end
            end
        end
    end

generate 
    if (IS_OUT_LATENCY == "true") begin
        always_ff @(posedge i_clk) begin  
            if (i_rd_en == 1'h1) begin 
                o_rd_data <= mem[i_rd_addr];
            end

            o_rd_data_valid <= i_rd_en;
        end
    end
    else begin
        always_comb begin  
            if (i_rd_en == 1'h1) begin 
                o_rd_data = mem[i_rd_addr];
            end
            else begin
                o_rd_data = {DATA_WIDTH{1'h0}};
            end

            o_rd_data_valid = i_rd_en;
        end
    end
endgenerate

endmodule
