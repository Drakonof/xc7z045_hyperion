/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : sync_fifo.sv
|
| testbench: sync_fifo_tb.sv
| 
| 15.12.21 : created
|
|
|
*/

/*
sync_fifo # 
(
    .DATA_WIDTH       (),
    .ADDR_WIDTH       (),
    
`ifdef XILINX_PLATFORM
    .RAM_TYPE         (), // "distributed", "block"
`endif   

    .ALMOST_FULL_VAL  (),
    .ALMOST_EMPTY_VAL (),
)
sync_fifo_inst                         
(
    .i_clk          (),
    .i_s_rst_n      (),
    
    .i_wr_en        (),
    .i_wr_data      (), // DATA_WIDTH width
    .o_almost_full  (),
    .o_full         (),
    
    .i_rd_en        (),
    .o_rd_data      (), // DATA_WIDTH width
    .o_almost_empty (),
    .o_empty        (),
    .o_rd_valid     ()
);
*/

`include "platform.vh"

`timescale 1ns / 1ps

module sync_fifo #
(
    parameter integer DATA_WIDTH         = 8,
    
    parameter integer ADDR_WIDTH         = 8,
    
`ifdef XILINX_PLATFORM
    parameter         RAM_TYPE           = "block", // "distributed", "block"
`endif    

    parameter integer ALMOST_FULL_VAL  = 2, // hom much of words to an full state
    parameter integer ALMOST_EMPTY_VAL = 2,  // hom much of words to an empty state
    
    localparam integer FIFO_DEPTH = (2 ** ADDR_WIDTH)
)
(
    input  logic                      i_clk,
    input  logic                      i_s_rst_n,
    
    input  logic                      i_wr_en,
    input  logic [DATA_WIDTH - 1 : 0] i_wr_data,
    output logic                      o_almost_full,
    output logic                      o_full,
    
    input  logic                      i_rd_en,
    output logic [DATA_WIDTH - 1 : 0] o_rd_data,
    output logic                      o_almost_empty,
    output logic                      o_empty,
    output logic                      o_rd_valid
);
    localparam integer A_FULL        = FIFO_DEPTH - ALMOST_FULL_VAL; 
    localparam integer A_EMPTY       = ALMOST_EMPTY_VAL;
    
    localparam integer POINTER_WIDTH = ADDR_WIDTH;  
    
    logic [POINTER_WIDTH - 1 : 0] wr_pointer;
    logic [POINTER_WIDTH - 1 : 0] rd_pointer;
 
    logic [POINTER_WIDTH : 0]     word_counter;
    
`ifdef XILINX_PLATFORM    
    (*ram_style = RAM_TYPE*) 
`endif
    logic [DATA_WIDTH - 1 : 0] mem [0 : FIFO_DEPTH - 1] ;
    
    initial begin
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            mem[i] = '0;
        end
    end
    
    always_comb begin
        o_full         = (word_counter == FIFO_DEPTH);
        o_empty        = word_counter == '0;

        o_almost_full  = (word_counter == A_FULL - 1);
        o_almost_empty = (word_counter == A_EMPTY);
    end
  
    always @ (posedge i_clk) begin : wr_pointer_control
        if (i_s_rst_n == '0) begin
            wr_pointer <= '0;
        end 
        else if ((i_wr_en == '1)  && (o_full == '0)) begin
            wr_pointer <= wr_pointer + 1'h1;
        end
    end
    
    always @ (posedge i_clk) begin  : rd_pointer_control
        if (i_s_rst_n == '0) begin
            rd_pointer <= '0;
        end 
        else if ((i_rd_en == '1) && (o_empty == '0)) begin
            rd_pointer <= rd_pointer + 1'h1;
        end
    end
    
    always @ (posedge i_clk) begin  : rd_data
        if (i_s_rst_n == '0) begin
            o_rd_data  <= '0;
            o_rd_valid <= '0;
        end 
        else begin
            if ((i_rd_en == '1) && (o_empty == '0)) begin
                o_rd_data <= mem[rd_pointer];
            end
            
            o_rd_valid <= (i_rd_en == '1) && (o_empty == '0);
        end
    end
    
    always @ (posedge i_clk) begin  : wr_data
        if ((i_wr_en == '1) && (o_full == '0)) begin
            mem[wr_pointer] <= i_wr_data;
        end
    end
    
    always @ (posedge i_clk) begin  : word_counter_control
        if (i_s_rst_n == '0) begin
            word_counter <= '0;
        end 
        else if ((i_rd_en == '1) && (i_wr_en == '0) && (word_counter != 0)) begin
            word_counter <= word_counter - 1'h1;
        end 
        else if ((i_rd_en == '0) && (i_wr_en == '1) && (word_counter != FIFO_DEPTH)) begin
            word_counter <= word_counter + 1'h1;
        end
    end

    // Not synthesized
    always @ (posedge i_clk) begin
        if ((i_wr_en == '1) && (o_full == '1)) begin
            $display("full fifo is being written ");
        end

        if ((i_rd_en == '1) && (o_empty == '1)) begin
            $display("empty fifo is being read");
        end
    end

endmodule
