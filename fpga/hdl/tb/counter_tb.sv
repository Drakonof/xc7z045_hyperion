/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : counter.sv
|
| testbench: counter_tb.sv
| 
| brief    :
|
| todo     :
|
| 08.02.22 : created
|
*/

`timescale 1ns / 1ps

module counter_tb;

    localparam integer MAX_VALUE     = 255;
    localparam integer CLOCK_PERIOD  = 100;
    localparam integer COUNTER_WIDTH = $clog2(MAX_VALUE);

    bit                         clk        = '0;
    bit                         s_rst_n    = '1;
    bit                         enable     = '0;
    bit [COUNTER_WIDTH - 1 : 0] cmpr_value = '0;
    
    bit [COUNTER_WIDTH - 1 : 0] value;
    
    integer errors = 0;

    counter #
    (
        .MAX_VALUE (MAX_VALUE)
    )
    counter_dut
    (
        .i_clk     (clk    ),    

        .i_en      (enable ), 
        .i_s_rst_n (s_rst_n),
                  
        .o_value   (value  ) 
    );
    
    initial begin
        clk = 1'h0;
 
        forever begin
            #( CLOCK_PERIOD / 2 ) clk = !clk;
        end 
    end

    task check_counter_value;
    begin
        repeat(MAX_VALUE - 1) begin
            @(posedge clk);
            
            cmpr_value <= cmpr_value + 1'h1;
            
            if (value !== cmpr_value) begin
               errors = errors + 1;
               $display($time, " counter_tb: a dut value: %h\n  a compared value: %h", value, cmpr_value);
            end
            
            
        end
    end
    endtask

    initial begin
        $display($time, " counter_tb: started");
    
        cmpr_value <= '0;
        s_rst_n    <= '0;
        @(posedge clk);
        
        s_rst_n    <= '1;
        enable     <= '1;
    
        repeat(MAX_VALUE - 1) begin
            check_counter_value;
        end
        
        if (errors == 0) begin
            $display($time, " counter_tb: test passed");
        end 
        else begin
            $display($time, " counter_tb: test failed with %d errors", errors);
        end
        
        $display($time, " counter_tb: finished");
        
        $stop();
    end

endmodule
