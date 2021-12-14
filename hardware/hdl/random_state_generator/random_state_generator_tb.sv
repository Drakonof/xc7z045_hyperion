/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : random_state_generator.sv
|
| testbench: random_state_generator_tb.sv
| 14.12.21 : created
|
|
| an unsyntezable module
|
*/

`timescale 1ns / 1ps

module random_state_generator_tb;
//-------------------------------------------------- settings
    localparam integer STATE_0_MIN_VALUE = 100;
    localparam integer STATE_0_MAX_VALUE = 600;
    localparam integer STATE_1_MIN_VALUE = 60;
    localparam integer STATE_1_MAX_VALUE = 500;
    
    localparam integer CLOCK_PERIOD      = 100;
    localparam integer TEST_ITER_NUM     = 1000000;
//-------------------------------------------------- end of settings
    
    bit clk     = '0;
    bit s_rst_n = '1;
    
    bit state;

    random_state_generator # 
    (
        .STATE_0_MIN_VALUE (STATE_0_MIN_VALUE),
		.STATE_0_MAX_VALUE (STATE_0_MAX_VALUE),
		.STATE_1_MIN_VALUE (STATE_1_MIN_VALUE),
		.STATE_1_MAX_VALUE (STATE_1_MAX_VALUE)
    )
    random_state_generator_dut                         
    (
        .i_clk     (clk    ),
		.i_s_rst_n (s_rst_n),
		
		.o_state   (state  )
    );
    
    always begin
        #(CLOCK_PERIOD / 2) clk = !clk;
    end
    
    initial begin
        s_rst_n <= '0;
        @(posedge clk);
        
        s_rst_n <='1;
        @(posedge clk);
        
	    repeat(TEST_ITER_NUM) begin
	        @(posedge clk);
	    end

	    $stop();
    end
endmodule
