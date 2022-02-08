/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : piso.sv (parallel in serial out)
|
| testbench: piso_tb.sv
| 
| brief    :
|
| todo     :
| 
| 13.12.21 : created
|
*/

`include "platform.vh"

`timescale 1ns / 1ps

module piso_tb;
//-------------------------------------------------- setting
    localparam                      DO_MSB_FIRST = "true";
    localparam                      DO_FAST      = "true";
    localparam integer              DATA_WIDTH   = 8;
    localparam [DATA_WIDTH - 1 : 0] MAX_VALUE    = ((2 << DATA_WIDTH) - 1);
    localparam integer              CLOCK_PERIOD = 100;
    localparam integer              REPEATS      = 1000;
//-------------------------------------------------- end of settings

    bit                      serl_data ;  
    bit                      data_valid; 

    bit                      clk        = '0;                
    bit                      s_rst_n    = '1; 

    bit                      wr_en      = '0; 
    bit [DATA_WIDTH - 1 : 0] parl_data  = '0;
    bit [DATA_WIDTH - 1 : 0] comp_data  = '0;

    integer errors = 0;
    integer i      = 0;

    piso #
    (
        .DATA_WIDTH   (DATA_WIDTH  ),
        .DO_MSB_FIRST (DO_MSB_FIRST),
        .DO_FAST      (DO_FAST     )
    )
    piso_dut
    (
        .i_clk        (clk       ), 
        .i_s_rst_n    (s_rst_n   ),

        .i_wr_en      (wr_en     ),
        .i_data       (parl_data ),

        .o_data_valid (data_valid),            
        .o_data       (serl_data )
    );

    task check_piso; begin
        repeat(REPEATS) begin
            comp_data = $urandom % MAX_VALUE;

            wr_en     <= '1;
            parl_data <= comp_data;
            @(posedge clk);

            wr_en     <= '0;
            i         = (DO_MSB_FIRST == "true") ? DATA_WIDTH - 1 : 0;
            wait(data_valid) @(posedge clk);

            if (DO_FAST != "true") begin
                @(posedge clk);
            end

            repeat(DATA_WIDTH) begin 
            
                if (serl_data != comp_data[i]) begin
                    errors++;
                    $display($time, "An error ocurred. A data bit is: %b, but have to be %b\n", serl_data, comp_data[i]);
                end 

                i = (DO_MSB_FIRST == "true") ? --i : ++i;
                @(posedge clk);
            end
        end
    end
    endtask

    always begin
        #(CLOCK_PERIOD / 2) clk = !clk;
    end   

    initial begin
        $display($time, " piso_tb: started");
        s_rst_n   <= '0;

        wr_en     <= '0;
        parl_data <= '0;
        @(posedge clk);

        s_rst_n   <= '1;
        @(posedge clk);

        check_piso;

        if (errors == 0) begin
            $display($time, " piso_tb: test passed");
        end 
        else begin
            $display($time, " piso_tb: test failed with %d errors", errors);
        end
        
        $display($time, " piso_tb: finished");

        $stop();
    end 
endmodule