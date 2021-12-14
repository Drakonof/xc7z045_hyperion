library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity random_state_generator_tb is
end random_state_generator_tb;

architecture testbench of random_state_generator_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal clk     : std_logic := '0';
    signal s_rst_n : std_logic := '0';
    signal state   : std_logic := '0';
begin
    random_state_generator_dut : entity work.random_state_generator
    generic map                
    (                          
        STATE_0_MIN_VALUE => 10,
		STATE_0_MAX_VALUE => 20,
		STATE_1_MIN_VALUE => 30,
		STATE_1_MAX_VALUE => 40
    )                          
    port map                   
    (
        clk     => clk,
		s_rst_n => s_rst_n,
		state   => state
    );
    
    clk_process :process
    begin    
        wait for CLK_PERIOD / 2; 
        clk <= not clk;
    end process;
    
     reset : process begin
	    s_rst_n <= '0';
	    wait for 10 ns;
	    
	    s_rst_n <='1';
	    wait for CLK_PERIOD;    
	    wait for 10000000 ns;
	    
	    std.env.finish;
    end process;

end testbench;
