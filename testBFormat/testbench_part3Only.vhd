library ieee;  
use ieee.std_logic_1164.all;  
use ieee.std_logic_unsigned.all;  
use work.all; 

entity test_controller_sub is end test_controller_sub; 

architecture behavioural of test_controller_sub is 
    component CONTROLLER_file port( 
        --input signals 
		rst: in std_logic;   
		clk: in std_logic; 
		IR: in std_logic_vector(15 downto 0);   
		--output signal 
		z, n, o: out std_logic;
		PC: out std_logic_vector(15 downto 0); 
		out_val: out std_logic_vector(15 downto 0) 
    ); 
    end component;  

    signal rst, clk, z, n, o : std_logic;  
    signal IR, PC, out_val : std_logic_vector(15 downto 0);  

    begin 
    u0 : CONTROLLER_file port map(rst, clk, IR, z, n, o, PC, out_val); 

    process begin 
        clk <= '0'; wait for 10 us; 
        clk <= '1'; wait for 10 us;  
    end process; 

    process begin 
        rst <= '1'; IR <= X"4200"; wait until (rising_edge(clk));  
        rst <= '0'; wait until (rising_edge(clk));     -- IN R0             -- R0 = -02 
        IR <= X"4240"; wait until (rising_edge(clk));  -- IN R1             -- R1 = 03 
        IR <= X"4280"; wait until (rising_edge(clk));  -- IN R2			    -- R2 = 01 
        IR <= X"42C0"; wait until (rising_edge(clk));  -- IN R3			    -- R3 = 05 
        IR <= X"0783"; wait until (rising_edge(clk));  -- stall until updated new value of register
        wait until (rising_edge(clk));                 -- stall until updated new value of register 
        wait until (rising_edge(clk));                 -- stall until updated new value of register 
        wait until (rising_edge(clk));                 -- MUL R6, R0, R3 	-- R6 = R0 * R3 = -2 * 5 = - 10
        IR <= X"4180"; wait until (rising_edge(clk));  -- OUT r6
	    
        wait; 
    end process; 
end behavioural; 

 