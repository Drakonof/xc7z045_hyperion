/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : true_dual_ram.sv
|
| testbench: true_dual_ram_tb.sv
| 
| 23.12.21 : created
| 
|
|
*/

/*
true_dual_ram # 
(
    .DATA_WIDTH (),
    .ADDR_WIDTH (),
    
    .MODE       (), // "h_per", "l_lat"
    .INIT_FILE  ()
)
true_dual_ram_inst                         
(
    .i_clk_a     (),
    .i_a_rst_n_a (),
    .i_wr_en_a   (),
    
    .i_addr_a    (), // ADDR_WIDTH width
    .i_data_a    (), // DATA_WIDTH width
    
    .o_data_en_a (),
    .o_data_a    (), // DATA_WIDTH width
    
    .i_clk_b     (),
    .i_a_rst_n_b (),
    .i_wr_en_b   (),
    
    .i_addr_b    () ,   
    .i_data_b    () , // DATA_WIDTH width   
                 
    .o_data_en_b (),  // ADDR_WIDTH width
    .o_data_b    ()   // DATA_WIDTH width
);
*/

`timescale 1ns / 1ps

module true_dual_ram #
(
    parameter integer DATA_WIDTH   = 8,
    parameter integer ADDR_WIDTH   = 8,
    parameter         MODE         = "h_per", // "h_per", "l_lat"
    parameter         INIT_FILE    = "",
 
    localparam integer LATENCY_NUM  = (MODE == "h_per") ? 2 : 1,
    localparam integer MSB          = LATENCY_NUM - 1,
    localparam integer LSB          = 0,
    
    localparam integer RAM_DEPTH    = 2 ** ADDR_WIDTH
)
(
    input  logic                      i_clk_a,
    input  logic                      i_a_rst_n_a,
    input  logic                      i_wr_en_a,
    
    input  logic [ADDR_WIDTH - 1 : 0] i_addr_a,
    input  logic [DATA_WIDTH - 1 : 0] i_data_a,
    
    output logic                      o_data_valid_a,
    output logic [DATA_WIDTH - 1 : 0] o_data_a,
    
    input  logic                      i_clk_b,
    input  logic                      i_a_rst_n_b,
    input  logic                      i_wr_en_b,
    
    input  logic [ADDR_WIDTH - 1 : 0] i_addr_b,
    input  logic [DATA_WIDTH - 1 : 0] i_data_b,
    
    output logic                      o_data_valid_b,
    output logic [DATA_WIDTH - 1 : 0] o_data_b
    
);

    logic [DATA_WIDTH-1:0]   ram_data_a;
    logic [DATA_WIDTH-1:0]   ram_data_b;
    
    logic [DATA_WIDTH-1:0]   data_valid_a;
    logic [DATA_WIDTH-1:0]   data_valid_b;
    
    logic [DATA_WIDTH - 1:0] ram [RAM_DEPTH - 1 : 0];
    
    integer i = 0;

    generate
        if (INIT_FILE != "") begin: ram_init_from_file
            initial begin
                $readmemh(INIT_FILE, ram, 0, RAM_DEPTH - 1);
            end
        end 
        else begin: ram_init_to_zero
            initial begin
                for (i = 0; i < RAM_DEPTH; i++) begin
                    ram[i] = '0;
                end
            end
        end
        
        initial begin
            for (i = 0; i < LATENCY_NUM; i++) begin
                ram_data_a[i] = '0;
                ram_data_b[i] = '0;
                data_valid_a[i]  = '0;
                data_valid_b[i]  = '0;
            end
        end
    endgenerate

    always_ff @ (posedge i_clk_a) begin
        if (i_wr_en_a == '1) begin
            ram[i_addr_a] <= i_data_a;
        end
        else begin
            ram_data_a <= ram[i_addr_a];
        end
        
        data_valid_a <= ~i_wr_en_a;
    end

    always_ff @ (posedge i_clk_b) begin
        if (i_wr_en_b == '1) begin
            ram[i_addr_b] <= i_data_b;
        end
        else begin
            ram_data_b[LSB] <= ram[i_addr_b];
        end
        
        data_valid_b[LSB] <= ~i_wr_en_b;
    end
    
    generate
        if (MODE == "h_per") begin: high_perfomance_mode
            always_ff @ (posedge i_clk_a) begin
                if (i_a_rst_n_b == '0) begin
                    for (i = 0; i < LATENCY_NUM; i++) begin
                        ram_data_a[i] <= '0;
                        data_valid_a[i]  <= '0;
                    end
                end
                else begin
                    ram_data_a[LSB] <= ram_data_a[MSB];
                    data_valid_a[LSB]  <= data_valid_a[MSB];
                end        
            end

            always_ff @ (posedge i_clk_a) begin
                if (i_a_rst_n_b == '0) begin
                    for (i = 0; i < LATENCY_NUM; i++) begin
                        ram_data_b[i] <= '0;
                        data_valid_b[i]  <= '0;
                    end
                end
                else begin
                    ram_data_b[LSB]   <= ram_data_b[MSB];
                    data_valid_b[LSB] <= data_valid_b[MSB];
                end        
            end
        end
    endgenerate
    
    always_comb begin
        o_data_a    = ram_data_a;
        o_data_b    = ram_data_b[LSB];
        o_data_valid_a = data_valid_a[LSB];
        o_data_valid_b = data_valid_b[LSB];
    end

endmodule
