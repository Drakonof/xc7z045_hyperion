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

/*
random_state_generator # 
(
    .STATE_0_MIN_VALUE (),
    .STATE_0_MAX_VALUE (),
    .STATE_1_MIN_VALUE (),
    .STATE_1_MAX_VALUE ()
)
random_state_generator_inst                         
(
    .i_clk     (),
    .i_s_rst_n (),
    
    .o_state   ()
);
*/

`timescale 1ns / 1ps

module random_state_generator # 
(
    parameter integer STATE_0_MIN_VALUE = 10,
    parameter integer STATE_0_MAX_VALUE = 20,
    parameter integer STATE_1_MIN_VALUE = 30,
    parameter integer STATE_1_MAX_VALUE = 40
)
(
    input  logic i_clk,
    input  logic i_s_rst_n,
    
    output logic o_state
);

    bit value_switch = '0;
    
    int  counter = 0;
    int  limit   = 0;
    
    always_ff @ (posedge i_clk) begin
        if (i_s_rst_n == '0) begin
    	    counter = 0;
    	    limit   = $urandom_range(STATE_0_MIN_VALUE , STATE_0_MAX_VALUE );
    	    
    	    o_state <= '0;
        end
        else begin
            if (value_switch == '0) begin
                if (counter == limit ) begin
                    counter = 0;
                    limit   = $urandom_range(STATE_1_MIN_VALUE , STATE_1_MAX_VALUE );
                    
                    value_switch <= '1;
                    o_state      <= '1;
                end
                else begin
                    ++counter;
                    o_state <= '0;
                end
            end
    		else
                if (counter == limit ) begin
                    counter = 0;
                    limit   = $urandom_range(STATE_0_MIN_VALUE , STATE_0_MAX_VALUE );
                    
                    value_switch <= '0;
                    o_state      <= '0;
                end
                else begin
                    ++counter;
                    o_state <= '1;
                end
            end
        end
        
    always @ (*) begin
        if ((STATE_0_MIN_VALUE > STATE_0_MAX_VALUE) ||
            (STATE_1_MIN_VALUE > STATE_1_MAX_VALUE)) begin
            
            $error("The module parameters error.");
        end
    end
endmodule
