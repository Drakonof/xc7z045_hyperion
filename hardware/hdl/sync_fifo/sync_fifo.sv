/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : sync_fifo.sv
| testbench: sync_fifo_tb.sv
| 21.11.21 : created
*/

`timescale 1ns / 1ps

module sync_fifo #
(
    parameter integer DATA_WIDTH         = 8,
    
    parameter integer FIFO_DEPTH         = 32,
    
    parameter integer ALMOST_FULL_VALUE  = 2,
    parameter integer ALMOST_EMPTY_VALUE = 2,
    
    parameter         RAM_TYPE           = "block" // "distributed", "block"
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
    localparam integer A_FULL        = FIFO_DEPTH - ALMOST_FULL_VALUE; 
    localparam integer A_EMPTY       = ALMOST_EMPTY_VALUE;
    
    localparam integer POINTER_WIDTH = $clog2(FIFO_DEPTH);  
    
    logic                         full;
    logic                         empty;
    
    logic [POINTER_WIDTH - 1 : 0] wr_pointer;
    logic [POINTER_WIDTH - 1 : 0] rd_pointer;
 
    logic [POINTER_WIDTH : 0]     word_counter;
    
    (*ram_style = RAM_TYPE*) 
    logic [FIFO_DEPTH - 1 : 0] mem;
    
    initial begin
        wr_pointer   = '0;
        rd_pointer   = '0;
        word_counter = '0;
    
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            mem[i] = '0;
        end
    end

    always_comb begin
        o_almost_full  = (word_counter == A_FULL) && (i_rd_en == '0);
        o_almost_empty = (word_counter == A_EMPTY) && (i_wr_en == '0);
        
        o_full         = full; 
        o_empty        = empty;
   
        o_rd_data      = mem[rd_pointer];
   
        full           = word_counter == FIFO_DEPTH;
        empty          = word_counter == '0;
    end
    
    always_ff @ (posedge i_clk) begin : control
        if (i_s_rst_n == '0) begin
            word_counter <= '0;
            wr_pointer   <= '0;
            rd_pointer   <= '0;
        end
        else begin
            if ((i_wr_en == '1) && (i_rd_en == '0) && (full == '0)) begin
                word_counter <= word_counter + 1'h1;
            end
            else if ((i_wr_en == '0) && (i_rd_en == '1) && (empty == '0)) begin
                word_counter <= word_counter - 1'h1;
            end

            if ((i_wr_en == '1) && (full == '0)) begin
                if (wr_pointer == FIFO_DEPTH - 1) begin
                    wr_pointer <= '0;
                end
                else begin
                    wr_pointer <= wr_pointer + 1'h1;
                end
            end

            if ((i_rd_en == '1) && (empty == '0)) begin
                if (rd_pointer == FIFO_DEPTH - 1) begin
                    rd_pointer <= '0;
                end
                else begin
                    rd_pointer <= rd_pointer + 1'h1;
                end
            end
              
            if (i_wr_en == '1) begin
                mem[wr_pointer] <= i_wr_data;
            end;
            
            o_rd_valid <= (i_rd_en == '1) && (empty == '0);
        end                         
    end                          
 
    always @ (*) begin : assertion
        if ((i_wr_en == '1) && (full == '1)) begin
            $error("full fifo is being written ");
        end

        if ((i_rd_en == '1) && (empty = '1)) begin
            $error("empty fifo is being read");
        end
    end

endmodule
