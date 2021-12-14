library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

entity sync_fifo_tb is
end sync_fifo_tb; 

architecture testbench of sync_fifo_tb is 
    constant DATA_WIDTH   : natural := 16;

    constant FIFO_DEPTH   : natural := 1024;

    constant A_FULL       : natural := 2;
    constant A_EMPTY      : natural := 2;

    --constant INIT_FILE    : string  := "fifo.mem"; 

    constant CLK_PERIOD   : time := 10 ns;
    constant TEST_TIME    : time := 20000 ns;
    constant FILE_INITIAL : time := CLK_PERIOD * FIFO_DEPTH;

    subtype data_t is std_logic_vector(DATA_WIDTH - 1 downto 0);
    type mem_arr_t is array (0 to FIFO_DEPTH - 1) of data_t;

    signal clk           : std_logic := '0';
    signal s_rst_n       : std_logic := '0';

    signal wr_en         : std_logic := '0';
    signal wr_data       : std_logic_vector (DATA_WIDTH - 1 downto 0) := (others => '0');

    signal almost_full   : std_logic := '0'; --
    signal full          : std_logic := '0';

    signal rd_en         : std_logic := '0';
    signal rd_valid      : std_logic := '0';
    signal rd_data       : std_logic_vector (DATA_WIDTH - 1 downto 0) := (others => '0');

    signal rd_data_d     : std_logic_vector (DATA_WIDTH - 1 downto 0) := (others => '0');

    signal almost_empty  : std_logic := '0'; --
    signal empty         : std_logic := '0';

    signal wr_slow_state : std_logic := '0';
    signal wr_fast_state : std_logic := '0';

    signal rd_slow_state : std_logic := '0';
    signal rd_fast_state : std_logic := '0';

    signal wr_activity   : std_logic := '0';
    signal rd_activity   : std_logic := '0';

    signal en            : std_logic := '0';

    signal errors        : natural   := 0;
    signal wr_mem_addr   : natural   := 0;
    signal rd_mem_addr   : natural   := 0;

    impure function mem_arr_init(filename : string) return mem_arr_t is
        file file_ptr      : text open read_mode is filename;

        variable ram_arr   : mem_arr_t;
        variable line_text : std_logic_vector (DATA_WIDTH - 1 downto 0);
        variable line_num  : line;

        variable i         : natural := 0 ;

        begin
            file_open(file_ptr, filename, read_mode);

            for i in 0 to FIFO_DEPTH - 1 loop
                readline(file_ptr, line_num);
                hread(line_num, ram_arr(i));
            end loop;

            file_close(file_ptr);
            return ram_arr;
    end function;  

    signal mem_arr      : mem_arr_t;-- := mem_arr_init(INIT_FILE);
begin

    wr_activity <= wr_slow_state and wr_fast_state and en and not full; 
    rd_activity <= rd_slow_state and rd_fast_state and en and not empty; 

    ring_buffer : entity work.sync_fifo
    generic map                
    (                          
        FIFO_DEPTH         => FIFO_DEPTH,   
        DATA_WIDTH         => DATA_WIDTH,   

        ALMOST_FULL_VALUE  => A_FULL,   
        ALMOST_EMPTY_VALUE => A_EMPTY
    )                          
    port map                   
    (                          
        clk          => clk,    
        s_rst_n      =>  s_rst_n,    

        wr_en        => wr_en,    
        wr_data      => wr_data,    

        almost_full  => almost_full,    
        full         => full,    

        rd_en        => rd_en,    
        rd_valid     => rd_valid,    
        rd_data      => rd_data,     
               
        almost_empty => almost_empty,     
        empty        => empty  
    );                        

    wr_slow_state_generator : entity work.random_state_generator 
    generic map 
    (
        STATE_0_MIN_VALUE => 1000, 
        STATE_0_MAX_VALUE => 3500, 
        STATE_1_MIN_VALUE => 800, 
        STATE_1_MAX_VALUE => 2000
    )
    port map 
    (
        clk     => clk, 
        s_rst_n => s_rst_n,
        state   => wr_slow_state
    );

    wr_fast_state_generator: entity work.random_state_generator 
    generic map 
    (
        STATE_0_MIN_VALUE => 2000, 
        STATE_0_MAX_VALUE => 3000, 
        STATE_1_MIN_VALUE => 1000, 
        STATE_1_MAX_VALUE => 2000
    )
    port map 
    (
        clk     => clk, 
        s_rst_n => s_rst_n,
        state   => wr_fast_state
    );

    rd_slow_state_generator : entity work.random_state_generator 
    generic map 
    (
        STATE_0_MIN_VALUE => 8, 
        STATE_0_MAX_VALUE => 110, 
        STATE_1_MIN_VALUE => 18, 
        STATE_1_MAX_VALUE => 58
    )
    port map 
    (
        clk     => clk, 
        s_rst_n => s_rst_n,
        state   => rd_slow_state
    );

    rd_fast_state_generator: entity work.random_state_generator 
    generic map 
    (
        STATE_0_MIN_VALUE => 18, 
        STATE_0_MAX_VALUE => 88, 
        STATE_1_MIN_VALUE => 18, 
        STATE_1_MAX_VALUE => 38
    )
    port map 
    (
        clk     => clk, 
        s_rst_n => s_rst_n,
        state   => rd_fast_state
    );
wr_en <= wr_activity;
    writing: process (clk) begin
    if rising_edge(clk) then
        if wr_activity = '1' then
            wr_data <= mem_arr(wr_mem_addr);
            

            if wr_mem_addr = mem_arr'length - 1 then
                wr_mem_addr <= 0;
            else 
                wr_mem_addr <= wr_mem_addr + 1;
            end if;
     --   else
           -- wr_en <= '0';
        end if;
    end if;
    end process;
rd_en <= rd_activity;
    reading: process (clk) begin
    if rising_edge(clk) then
     --   if rd_activity = '1' and empty = '0' then
     --       rd_en <= '1';
    --    else
    --        rd_en <= '0';
    --    end if;

        if rd_valid = '1' then
            if rd_mem_addr = mem_arr'length - 1 then
                rd_mem_addr <= 0;
            else 
                rd_mem_addr <= rd_mem_addr + 1;
            end if;

            if (rd_data /= mem_arr(rd_mem_addr)) then
                report "Data Error!" severity error;
                errors <= errors + 1; 
            end if;
        end if;
    end if;
    end process;

    clk_process :process begin    
        wait for CLK_PERIOD / 2; 
        clk <= not clk;
    end process;

    stimulus : process begin
        s_rst_n <= '0';
        en      <= '0';
        wait for 10 ns;

        s_rst_n <='1';
        wait for 10 ns;
        wait for FILE_INITIAL;

        en      <= '1';
        wait for TEST_TIME;

        std.env.finish;
    end process; 

end testbench;