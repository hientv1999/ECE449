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
    u0 : CONTROLLER_file port map(rst, clk, IR, z, n , o, PC, out_val); 

    process begin 
        clk <= '0'; wait for 10 us; 
        clk <= '1'; wait for 10 us;  
    end process; 

    process begin 
        rst <= '1'; IR <= X"4200"; wait until (falling_edge(clk));  
        rst <= '0'; wait until (falling_edge(clk));     -- IN R0                                         -- R0 = 02 
        IR <= X"4240"; wait until (falling_edge(clk));  -- IN R1                                         -- R1 = 03 
        IR <= X"4280"; wait until (falling_edge(clk));  -- IN R2			                             -- R2 = 01 
        IR <= X"42C0"; wait until (falling_edge(clk));  -- IN R3			                             -- R3 = 05 
	    IR <= X"4300"; wait until (falling_edge(clk));  -- IN R4                                         -- R4 = 528 
        IR <= X"4340"; wait until (falling_edge(clk));  -- IN R5			                             -- R5 = 01 
        IR <= X"4380"; wait until (falling_edge(clk));  -- IN R6			                             -- R6 = 05 
	    IR <= X"43C0"; wait until (falling_edge(clk));  -- IN R7			                             -- R7 = 00 
	    IR <= X"8D0A"; wait until (falling_edge(clk));  -- stall until PC updated
	    wait until (falling_edge(clk));                 -- stall until PC updated
	    wait until (falling_edge(clk));                 -- BR.SUB R4, 10	                             -- R7 <- PC + 2 ; PC <- R4 + 2*(10)
--	    IR <= X"8000"; wait until (falling_edge(clk));  -- stall until PC updated
--	    wait until (falling_edge(clk));                 -- stall until PC updated
--	    wait until (falling_edge(clk));                 -- BRR 0 			                             -- PC <- PC' + 2*(0) a.k.a infinite loop
        IR <= X"028D"; wait until (falling_edge(clk));  -- ADD R2, R1, R5 	                             -- R2 <- R1 + 1 = 04 
        IR <= X"0642"; wait until (falling_edge(clk));  -- stall until updated new value of register             
	    wait until (falling_edge(clk));                 -- stall until updated new value of register
	    wait until (falling_edge(clk));                 -- stall until updated new value of register
	    wait until (falling_edge(clk));                 -- MUL R1, R0, R2 	                             -- R1 = R0 * R2 = 08
	    IR <= X"05B5"; wait until (falling_edge(clk));  -- SUB R6, R6, R5	                             -- R6 <- R6 - 1 = 04
	    IR <= X"0F80"; wait until (falling_edge(clk));  -- stall until updated new value of register
	    wait until (falling_edge(clk));                 -- stall until updated new value of register
	    wait until (falling_edge(clk));                 -- stall until updated new value of register
        wait until (falling_edge(clk));      		    -- TEST R6                                       -- set z flag for branch 
        IR <= X"8402"; wait until (falling_edge(clk));  -- stall until PC updated
        wait until (falling_edge(clk));                 -- stall until PC updated
	    wait until (falling_edge(clk));                 -- BRR.z 2                                       -- branch if r6 = 0 
        IR <= X"81FB"; wait until (falling_edge(clk));  -- stall until PC updated
        wait until (falling_edge(clk));                 -- stall until PC updated
        wait until (falling_edge(clk));                 -- BRR -5                                        -- PC <- PC + 2*(-5) 
--        IR <= X"8E00"; wait until (falling_edge(clk));  -- stall until PC updated
--        wait until (falling_edge(clk));                 -- stall until PC updated
--        wait until (falling_edge(clk));                 -- RETURN		                                 -- PC <- r7 a.k.a exit the subroutine
        IR <= X"4040"; wait until (falling_edge(clk));  -- OUT r1                                        -- R1 = 08
        IR <= X"4080"; wait until (falling_edge(clk));  -- OUT r2                                        -- R2 = 04
        IR <= X"4180"; wait until (falling_edge(clk));  -- OUT r6                                        -- R6 = 04
        IR <= X"41C0"; wait until (falling_edge(clk));  -- OUT r7                                        -- R7 = 16
        wait; 
    end process; 
end behavioural; 

 