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
    
    parameter integer ALMOST_FULL_VAL  = 2, // hom much of words to an full state
    parameter integer ALMOST_EMPTY_VAL = 2, // hom much of words to an empty state
    
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
    localparam integer A_FULL        = FIFO_DEPTH - ALMOST_FULL_VAL; 
    localparam integer A_EMPTY       = ALMOST_EMPTY_VAL;
    
    localparam integer POINTER_WIDTH = $clog2(FIFO_DEPTH);  
    
    logic [POINTER_WIDTH - 1 : 0] wr_pointer;
    logic [POINTER_WIDTH - 1 : 0] rd_pointer;
 
    logic [POINTER_WIDTH : 0]     word_counter;
    
    (*ram_style = RAM_TYPE*) 
    logic [DATA_WIDTH - 1 : 0] mem [0 : FIFO_DEPTH - 1] ;
    
    initial begin
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            mem[i] = '0;
        end
    end
    
    assign o_full         = (word_counter == (FIFO_DEPTH - 1));
    assign o_empty        = word_counter == '0;

    assign o_almost_full  = (word_counter >= A_FULL);
    assign o_almost_empty = (word_counter <= A_EMPTY);
  
    always @ (posedge i_clk) begin : wr_pointer_control
        if (i_s_rst_n == '0) begin
            wr_pointer   <= '0;
        end 
        else if ((i_wr_en == '1)  && (o_full == '0)) begin
            wr_pointer <= wr_pointer + 1'h1;
        end
    end
    
    always @ (posedge i_clk) begin  : rd_pointer_control
        if (i_s_rst_n == '0) begin
            rd_pointer   <= '0;
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

    always @ (*) begin
        if ((i_wr_en == '1) && (o_full == '1)) begin
            $error("full fifo is being written ");
        end

        if ((i_rd_en == '1) && (o_empty == '1)) begin
            $error("empty fifo is being read");
        end
    end

endmodule
