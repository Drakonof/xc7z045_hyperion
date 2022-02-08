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

/*
counter # 
(
    .MAX_VALUE () // // default: 8
)
counter_inst                         
(
    .i_clk     (),
    .i_s_rst_n (),

    .i_en      (),

    .o_value   () // width: $clog2(MAX_VALUE)
);
*/

`timescale 1ns / 1ps

module counter #
(
    parameter integer MAX_VALUE = 8,
    
    localparam integer WIDTH = $clog2(MAX_VALUE)
)
(
    input  logic                 i_clk,
    input  logic                 i_s_rst_n,
    
    input  logic                 i_en,

    output logic [WIDTH - 1 : 0] o_value
);
    logic [WIDTH - 1 : 0] counter;

    always_comb begin
        o_value = counter;
    end

    always_ff @ (posedge i_clk) begin
        if (i_s_rst_n == '0) begin
            counter <= '0;
        end
        else if (i_en == '1) begin
            if (counter == MAX_VALUE) begin
                counter <= '0;
            end
            else begin
                counter <= counter + 1'h1;
            end   
        end
    end
endmodule
