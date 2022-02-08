/*--------------------------------------------------
| engineer : A. Shimko
|
| module   : simple_dual_port_ram.sv
|
| testbench: simple_dual_port_ram_tb.sv
| 
| brief    :
|
| todo     :
|
| 08.12.21 : created
|
*/

`timescale 1ns / 1ps

module simple_dual_port_ram_tb;

    localparam integer                    DATA_WIDTH       = 32;
    localparam integer                    ADDR_WIDTH       = 5; 
    localparam                            RAM_TYPE         = "block";
    localparam                            INIT_FILE_NAME   = "/media/shimko/CEF0BAC0F0BAADD9/workspace/xc7z010_hyperion/fpga/hdl/tb/simple_dual_port_ram_tb.mem";
    localparam                            IS_OUT_LATENCY   = "false";

    localparam integer                    BYTE_VALID_WIDTH = DATA_WIDTH / 8;
    localparam integer                    MEM_DEPTH        = 2 ** ADDR_WIDTH;

    localparam integer                    CLOCK_PERIOD     = 100;

    localparam [DATA_WIDTH - 1 : 0]       MAX_RAND_VALUE   = {DATA_WIDTH{1'h1}};
    localparam [BYTE_VALID_WIDTH - 1 : 0] MAX_VALID_VALUE  = {BYTE_VALID_WIDTH{1'h1}};
    localparam integer                    ITER_TEST_NUM    = 10000;

    logic                            clk             = 1'h0;

    logic                            wr_en           = 1'h0;
    logic [DATA_WIDTH - 1 : 0]       wr_data         = {DATA_WIDTH{1'h0}};
    logic [BYTE_VALID_WIDTH - 1 : 0] wr_byte_valid   = {BYTE_VALID_WIDTH{1'h0}};
    logic [ADDR_WIDTH - 1 : 0]       wr_addr         = {ADDR_WIDTH{1'h0}};

    logic                            rd_en           = 1'h0;
    logic [DATA_WIDTH - 1 : 0]       rd_data         = {DATA_WIDTH{1'h0}};
    logic [ADDR_WIDTH - 1 : 0]       rd_addr         = {ADDR_WIDTH{1'h0}};
    logic                            rd_data_valid   = 1'h0;

    logic [DATA_WIDTH - 1 : 0]       check_value     = {DATA_WIDTH{1'h0}};
    logic [DATA_WIDTH - 1 : 0]       byte_valid_mask = {DATA_WIDTH{1'h0}};
    logic [DATA_WIDTH - 1 : 0]       mask            = {DATA_WIDTH{1'h0}};

    integer errors = 0;

    simple_dual_port_ram #
    (
        .DATA_WIDTH     (DATA_WIDTH    ),
        .ADDR_WIDTH     (ADDR_WIDTH    ),

        .IS_OUT_LATENCY (IS_OUT_LATENCY),
        .RAM_TYPE       (RAM_TYPE      ),
        .INIT_FILE_NAME (INIT_FILE_NAME)
    )
    simple_dual_port_ram_dut
    (
        .wr_clk        (clk          ),
        .wr_en         (wr_en        ),
        .wr_data       (wr_data      ),      
        .wr_byte_valid (wr_byte_valid),
        .wr_addr       (wr_addr      ),

        .rd_clk        (clk          ),
        .rd_en         (rd_en        ),

        .rd_data       (rd_data      ),
        .rd_data_valid (rd_data_valid),
        .rd_addr       (rd_addr      )
    );

    initial begin
        clk = 1'h0;

        forever begin
            #( CLOCK_PERIOD / 2 ) clk = !clk;
        end 
    end

    task check_init_from_file; begin
        static int file = 0;

        rd_en   = 1'h1;
        rd_addr = {ADDR_WIDTH{1'h0}};
        @(posedge clk);

        file = $fopen(INIT_FILE_NAME,"r");

        if (file != 0) begin
            repeat(MEM_DEPTH) begin
                @(posedge clk);

                $fscanf(file, "%h", check_value);

                if ((check_value !== rd_data) && (rd_data_valid == 1'h1)) begin
                    $error("A value has to be %d, but is %d",rd_data, check_value);
                    errors = errors + 1;
                end

                rd_addr = rd_addr + 1;
            end
        end
        else begin
            $error("The file is not opened. Exit test");
            $stop();
        end

        rd_en = 1'h0;
        @(posedge clk);
    end
    endtask

    task check_write_reading; begin
        rd_addr       = {ADDR_WIDTH{1'h0}};
        wr_addr       = {ADDR_WIDTH{1'h0}};
        check_value   = {DATA_WIDTH{1'h0}};
        wr_byte_valid = $random % MAX_VALID_VALUE;
        wr_en         = 1'h1;
        @(posedge clk);

        rd_en         = 1'h1;

        repeat (MEM_DEPTH) begin
            @(posedge clk);

            if  (rd_data_valid == 1'h1) begin
                if ((wr_data  !== (rd_data & mask)) && 
                    (wr_byte_valid !== {BYTE_VALID_WIDTH{1'h0}})) begin
                    $error("A value has to be %d, but is %d",rd_data, check_value);
                    errors++;
                end
            end

            check_value = $random % MAX_RAND_VALUE;
            mask        = {DATA_WIDTH{1'h1}};

            for (int i = 0; i < BYTE_VALID_WIDTH; i++) begin
                if (wr_byte_valid[i] == 1'h0) begin
                    mask[(i * 8) +: 8] = mask[(i * 8) +: 8] & 1'h0;
                end
            end

            rd_addr     = rd_addr + 1'h1;
            wr_addr     = wr_addr + 1'h1;
            wr_data     = check_value & mask;
            @(posedge clk);
        end
    end
    endtask

    initial begin
        $display($time, " simple_dual_port_ram_tb: started");
        rd_en = 1'h0;
        wr_en = 1'h0;
        @(posedge clk);

        check_init_from_file;   

        repeat(ITER_TEST_NUM) begin
            check_write_reading;
        end

        @(posedge clk);

        if (errors == 0) begin
            $display($time, " simple_dual_port_ram_tb: test passed");
        end 
        else begin
            $display($time, " simple_dual_port_ram_tb: test failed with %d errors", errors);
        end
        
        $display($time, " simple_dual_port_ram_tb: finished");

        $stop();
    end
endmodule