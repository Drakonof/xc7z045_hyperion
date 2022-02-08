/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : sync_fifo.sv
|
| testbench: sync_fifo_tb.sv
| 
| brief    :
|
| todo     :
| 
| 15.12.21 : created
|
*/

`include "platform.vh"

`timescale 1ns / 1ps

module sync_fifo_tb;
    //-------------------------------------------------- settings
    localparam integer DATA_WIDTH            = 8;
    localparam integer ADDR_WIDTH            = 8;
    localparam integer ALMOST_FULL_VAL       = 2;
    localparam integer ALMOST_EMPTY_VAL      = 2;
    
`ifdef XILINX_PLATFORM
    localparam         RAM_TYPE              = "distributed"; // "distributed", "block"
`endif
    
    localparam integer WR_SL_STATE_0_MIN_VAL = 100;
    localparam integer WR_SL_STATE_0_MAX_VAL = 350;
    localparam integer WR_SL_STATE_1_MIN_VAL = 80;
    localparam integer WR_SL_STATE_1_MAX_VAL = 500;
  
    localparam integer WR_FS_STATE_0_MIN_VAL = 50;
    localparam integer WR_FS_STATE_0_MAX_VAL = 100;
    localparam integer WR_FS_STATE_1_MIN_VAL = 20;
    localparam integer WR_FS_STATE_1_MAX_VAL = 80;
  
    localparam integer RD_SL_STATE_0_MIN_VAL = 100;
    localparam integer RD_SL_STATE_0_MAX_VAL = 350;
    localparam integer RD_SL_STATE_1_MIN_VAL = 80;
    localparam integer RD_SL_STATE_1_MAX_VAL = 500;
  
    localparam integer RD_FS_STATE_0_MIN_VAL = 50;
    localparam integer RD_FS_STATE_0_MAX_VAL = 100;
    localparam integer RD_FS_STATE_1_MIN_VAL = 20;
    localparam integer RD_FS_STATE_1_MAX_VAL = 80;
    
    localparam integer CLOCK_PERIOD          = 100;
    localparam integer TEST_ITER_NUM         = 1000000;
    //-------------------------------------------------- end of settings

    localparam integer FIFO_DEPTH            = 2 ** ADDR_WIDTH;  
    localparam integer FILE_INITIAL          = CLOCK_PERIOD * FIFO_DEPTH;
    
    bit                      clk          = '0;
    bit                      s_rst_n      = '0;
    bit                      wr_en ;
    bit                      rd_en;
    bit [DATA_WIDTH - 1 : 0] wr_data      = '0;
    
    bit                      almost_full;
    bit                      full;
    bit                      almost_empty;
    bit                      empty;
    bit                      rd_valid;
    bit [DATA_WIDTH - 1 : 0] rd_data;
    
    
    bit wr_slow_state;
    bit wr_fast_state;

    bit rd_slow_state;
    bit rd_fast_state;
    
    bit en;
    
    always_comb begin
        wr_en = wr_slow_state && wr_fast_state && en && (full == 1'h0); 
        rd_en = rd_slow_state && rd_fast_state && en && (empty == 1'h0);
    end 
    
    sync_fifo #
    (
        .DATA_WIDTH       (DATA_WIDTH      ),
                           
        .ADDR_WIDTH       (ADDR_WIDTH      ),
        
`ifdef XILINX_PLATFORM                           
        .RAM_TYPE         (RAM_TYPE        ), 
`endif        
                  
        .ALMOST_FULL_VAL  (ALMOST_FULL_VAL ),
        .ALMOST_EMPTY_VAL (ALMOST_EMPTY_VAL)
    )
    sync_fifo_dut
    ( 
        .i_clk          (clk         ),
        .i_s_rst_n      (s_rst_n     ),
                        
        .i_wr_en        (wr_en       ),
        .i_wr_data      (wr_data     ),
        .o_almost_full  (almost_full ),
        .o_full         (full        ),
                        
        .i_rd_en        (rd_en       ),
        .o_rd_data      (rd_data     ),
        .o_almost_empty (almost_empty),
        .o_empty        (empty       ),
        .o_rd_valid     (rd_valid    )
    );
    
    random_state_generator #
    (
        .STATE_0_MIN_VAL (WR_SL_STATE_0_MIN_VAL), 
        .STATE_0_MAX_VAL (WR_SL_STATE_0_MAX_VAL), 
        .STATE_1_MIN_VAL (WR_SL_STATE_1_MIN_VAL), 
        .STATE_1_MAX_VAL (WR_SL_STATE_1_MAX_VAL)
    )
    wr_slow_state_generator
    (
        .i_clk     (clk          ), 
        .i_s_rst_n (s_rst_n      ),
        .o_state   (wr_slow_state)
    );
    
    random_state_generator #
    (
        .STATE_0_MIN_VAL (WR_FS_STATE_0_MIN_VAL), 
        .STATE_0_MAX_VAL (WR_FS_STATE_0_MAX_VAL), 
        .STATE_1_MIN_VAL (WR_FS_STATE_1_MIN_VAL), 
        .STATE_1_MAX_VAL (WR_FS_STATE_1_MAX_VAL)
    )
    wr_fast_state_generator
    (
        .i_clk     (clk          ), 
        .i_s_rst_n (s_rst_n      ),
        .o_state   (wr_fast_state)
    );
   
    random_state_generator #
    (
        .STATE_0_MIN_VAL (RD_SL_STATE_0_MIN_VAL), 
        .STATE_0_MAX_VAL (RD_SL_STATE_0_MAX_VAL), 
        .STATE_1_MIN_VAL (RD_SL_STATE_1_MIN_VAL), 
        .STATE_1_MAX_VAL (RD_SL_STATE_1_MAX_VAL)
    )
    rd_slow_state_generator
    (
        .i_clk     (clk          ), 
        .i_s_rst_n (s_rst_n      ),
        .o_state   (rd_slow_state)
    );
   
    random_state_generator #
    (
        .STATE_0_MIN_VAL (RD_FS_STATE_0_MIN_VAL), 
        .STATE_0_MAX_VAL (RD_FS_STATE_0_MAX_VAL), 
        .STATE_1_MIN_VAL (RD_FS_STATE_1_MIN_VAL), 
        .STATE_1_MAX_VAL (RD_FS_STATE_1_MAX_VAL)
    )
    rd_fast_state_generator
    (
        .i_clk     (clk          ), 
        .i_s_rst_n (s_rst_n      ),
        .o_state   (rd_fast_state)
    );
    
    bit [DATA_WIDTH - 1 : 0] rd_counter = '0;
    integer errors = 0;
    
    always_ff @ (posedge clk) begin
        if(wr_en == '1) begin
            wr_data <= wr_data + 1'h1;
        end
    end
    
    always_ff @ (posedge clk) begin
        if(rd_valid == '1) begin
            if (rd_counter != rd_data) begin
                errors++;
            end
             
            rd_counter <= rd_counter + 1'h1;
        end
    end
  
    always begin
        #(CLOCK_PERIOD / 2) clk = !clk;
    end
    
    initial begin
       $display($time, " sync_fifo_tb: started");
       s_rst_n <= '0;
       en      <= '0;
       @(posedge clk);
       
       s_rst_n <= '1;
       en      <= '1;
       repeat (TEST_ITER_NUM) begin
            @(posedge clk);
       end
       
       if (errors == 0) begin
            $display($time, " sync_fifo_tb: test passed");
        end 
        else begin
            $display($time, " sync_fifo_tb: test failed with %d errors", errors);
        end
        
        $display($time, " sync_fifo_tb: finished");

       $stop();
   end
endmodule
