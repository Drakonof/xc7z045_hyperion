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
    .wr_clk        (),
    .wr_en         (),

    .wr_data       (), // width: DATA_WIDTH
    .wr_byte_valid (), // width: BYTE_VALID_WIDTH width

    .wr_addr       (), // width: ADDR_WIDTH

    .rd_clk        (),
    .rd_en         (),

    .rd_data       (), // width: DATA_WIDTH
    .rd_data_valid (),
    .rd_addr       ()  // width: DATA_WIDTH
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
    input logic                            wr_clk,
    input logic                            wr_en,

    input logic [DATA_WIDTH - 1 : 0]       wr_data,
    input logic [BYTE_VALID_WIDTH - 1 : 0] wr_byte_valid,

    input logic [ADDR_WIDTH - 1 : 0]       wr_addr,

    input logic                            rd_clk,
    input logic                            rd_en,

    output logic [DATA_WIDTH - 1 : 0]      rd_data,
    output logic                           rd_data_valid,
    input logic [ADDR_WIDTH - 1 : 0]       rd_addr
);
    localparam integer MEM_DEPTH = 2 ** ADDR_WIDTH;

    (*ram_style = RAM_TYPE*) 
    bit [DATA_WIDTH - 1 : 0] mem[0 : MEM_DEPTH - 1];

    initial begin
        if (INIT_FILE_NAME == "" ) begin
            for (int i = 0; i < MEM_DEPTH; i++) begin
                mem[i] = {DATA_WIDTH{1'h0}};
            end
        end
        else begin
            $readmemh(INIT_FILE_NAME, mem);
        end
    end

    always_ff @(posedge wr_clk) begin  
        if (wr_en == 1'h1) begin 
            for (int i = 0; i < BYTE_VALID_WIDTH; i++) begin
                if (wr_byte_valid[i] == 1'h1) begin
                    mem[wr_addr][(i * 8) +: 8] <= wr_data[(i * 8) +: 8];
                end
            end
        end
    end

generate 
    if (IS_OUT_LATENCY == "true") begin
        always_ff @(posedge rd_clk) begin  
            if (rd_en == 1'h1) begin 
                rd_data <= mem[rd_addr];
            end

            rd_data_valid <= rd_en;
        end
    end
    else begin
        always_comb begin  
            if (rd_en == 1'h1) begin 
                rd_data = mem[rd_addr];
            end
            else begin
                rd_data = {DATA_WIDTH{1'h0}};
            end

            rd_data_valid = rd_en;
        end
    end
endgenerate

endmodule
