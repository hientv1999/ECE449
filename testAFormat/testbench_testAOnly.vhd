 
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
		PC: out std_logic_vector(15 downto 0);
		out_val: out std_logic_vector(15 downto 0)
    );
    end component; 
    
    signal rst, clk : std_logic; 
    signal IR, PC, out_val : std_logic_vector(15 downto 0); 
    
    begin
    u0 : CONTROLLER_file port map(rst, clk, IR, PC, out_val);

    process begin
        clk <= '0'; wait for 10 us;
        clk <= '1'; wait for 10 us; 
    end process;
    
    process begin
        rst <= '1'; IR <= X"4240"; wait until (rising_edge(clk)); 
        rst <= '0'; wait until (rising_edge(clk));     -- IN r1             -- r1 = 03
        IR <= X"4280"; wait until (rising_edge(clk));  -- IN r2             -- r2 = 05
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"02D1"; wait until (rising_edge(clk));  -- ADD r3, r2, r1    -- r3 = 08
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0AC2"; wait until (rising_edge(clk));  -- SHL r3, 2         -- r3 = 32
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"068B"; wait until (rising_edge(clk));  -- MUL r2, r1, r3    -- r2 = 96
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"4080"; wait until (rising_edge(clk));  -- OUT r2            -- r2 = 96
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        IR <= X"0000"; wait until (rising_edge(clk));  -- NOP
        rst <= '1';
        wait;
    end process;
end behavioural;