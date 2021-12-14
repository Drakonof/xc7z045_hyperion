library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_fifo is

    generic (
        DATA_WIDTH         : natural := 8;
        FIFO_DEPTH         : integer := 32;
        ALMOST_FULL_VALUE  : natural := 2;
        ALMOST_EMPTY_VALUE : natural := 2
    );
    port (
        clk          : in std_logic;
        s_rst_n      : in std_logic;
     
        wr_en        : in  std_logic;
        wr_data      : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        almost_full  : out std_logic;
        full         : out std_logic;

        rd_en        : in  std_logic;
        rd_data      : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        almost_empty : out std_logic;
        empty        : out std_logic;
        rd_valid     : out std_logic
    );
end sync_fifo;
 
architecture behavioral of sync_fifo is

    constant AFULL  : natural := FIFO_DEPTH - ALMOST_FULL_VALUE; 
    constant AEMPTY : natural := ALMOST_EMPTY_VALUE;
 
    type mem_arr_t is array (0 to FIFO_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    signal mem_arr      : mem_arr_t := (others => (others => '0'));
 
    signal wr_index     : natural range 0 to FIFO_DEPTH - 1 := 0;
    signal rd_index     : natural range 0 to FIFO_DEPTH - 1 := 0;
 
    signal word_counter : integer range 0 to FIFO_DEPTH := 0;
 
    signal full_w       : std_logic;
    signal empty_w      : std_logic;
  
begin

    almost_full  <= '1' when word_counter = AFULL and rd_en = '0' else '0';
    almost_empty <= '1' when word_counter = AEMPTY and wr_en = '0' else '0';  
 
    control : process (clk) is begin
        if rising_edge(clk) then
            if s_rst_n = '0' then
                word_counter <= 0;
                wr_index     <= 0;
                rd_index     <= 0;
            else
                if (wr_en = '1' and rd_en = '0') then
                    word_counter <= word_counter + 1;
                elsif (wr_en = '0' and rd_en = '1') then
                    word_counter <= word_counter - 1;
                end if;
 
                if (wr_en = '1' and full_w = '0') then
                    if wr_index = FIFO_DEPTH - 1 then
                        wr_index <= 0;
                    else
                        wr_index <= wr_index + 1;
                    end if;
                end if;
    
                if (rd_en = '1' and empty_w = '0') then
                    if rd_index = FIFO_DEPTH - 1 then
                        rd_index <= 0;
                    else
                        rd_index <= rd_index + 1;
                    end if;
                end if;
                  
                if wr_en = '1' then
                    mem_arr(wr_index) <= wr_data;
                end if;
                
                rd_valid <= rd_en and not empty_w;
            end if;                           
        end if;                            
    end process control;
    
    rd_data <= mem_arr(rd_index);
 
    full_w  <= '1' when word_counter = FIFO_DEPTH else '0';
    empty_w <= '1' when word_counter = 0       else '0';
 
    full    <= full_w;
    empty   <= empty_w;

-- synthesis translate_off
    assertion : process (clk) is
    begin
        if rising_edge(clk) then
            if wr_en = '1' and full_w = '1' then
                report "full fifo is being written " severity failure;
            end if;
 
            if rd_en = '1' and empty_w = '1' then
                report "empty fifo is being read" severity failure;
            end if;
        end if;
    end process assertion;
-- synthesis translate_on
  
end behavioral;
