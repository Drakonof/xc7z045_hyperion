library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all; 

entity random_state_generator is

   generic 
   (
		STATE_0_MIN_VALUE : natural := 3;
		STATE_0_MAX_VALUE : natural := 10;
		STATE_1_MIN_VALUE : natural := 20;
		STATE_1_MAX_VALUE : natural := 30
   );
   port  
   (
		clk     : in  std_logic;
		s_rst_n : in  std_logic;
		state   : out std_logic
    );
    
end random_state_generator;

architecture testbench_component of random_state_generator is

    signal value_switch : boolean := false;
    signal counter      : natural := 0;
    signal limit        : natural := 0;
    
begin
    process(clk) 
        variable seed_1 : integer := 999;
        variable seed_2 : integer := 999;
        
        impure function get_random_int
        (
            min_val : natural; 
            max_val : natural
        ) return natural is 
          variable real_v : real;     
        begin        
            uniform(seed_1, seed_2, real_v);  
            return natural(real_v * real(max_val - min_val)) + min_val;
        end function;
    begin
    	if rising_edge(clk) then
    	    if (s_rst_n = '0') then
    			state   <= '0';
    			counter <= 0;
    			limit   <= get_random_int(STATE_0_MIN_VALUE , STATE_0_MAX_VALUE );
    		else
    		    if (value_switch = false ) then
    		    	if (counter = limit ) then
    		    	    counter      <= 0;
    		    	    value_switch <= true;
    		    	    limit        <= get_random_int(STATE_1_MIN_VALUE , STATE_1_MAX_VALUE );
    		    	    state        <= '1';
    		    	else
    		    		counter <= counter + 1;
    		    		state   <= '0';
    		    	end if;
    		    else
    		    	if (counter = limit ) then
    		    	    counter      <= 0;
    		    	    value_switch <= false;
    		    	    limit        <= get_random_int(STATE_0_MIN_VALUE , STATE_0_MAX_VALUE );
    		    	    state        <= '0';
    		    	else
    		    		counter <= counter + 1;
    		    		state   <= '1';
    		    	end if;
    	
    		    end if;
    		end if;
    	end if;
    end process;
    
end testbench_component;