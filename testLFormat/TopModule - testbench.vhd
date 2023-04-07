 

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
		btn,num: in std_logic_vector(3 downto 0);
		input_port: in std_logic_vector(9 downto 0);
		-- output signals
        digit: out std_logic_vector(15 downto 0);
		z, n, o_led: out std_logic;
		output_port: out std_logic
	);
    end component;   
    signal rst, clk, z, n, o_led, output_port: std_logic;  
    signal in1, in2, result : std_logic_vector(15 downto 0);  
    signal btn, num: std_logic_vector(3 downto 0);
    signal input_port: std_logic_vector(9 downto 0);
    signal digit: std_logic_vector(15 downto 0);
    
    begin
    u0 : CONTROLLER_file port map(rst, clk, btn, num, input_port, digit, z, n, o_led, output_port); 

    process begin 
        clk <= '0'; wait for 5 us; 
        clk <= '1'; wait for 5 us;  
    end process;      

    process begin 
        btn <= X"3"; input_port <= "0000000000"; 
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"0"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"1"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"2"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"3"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"4"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"5"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"6"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"7"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"8"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"9"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"A"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"B"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"C"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"D"; wait for 2ms;
        rst <= '1'; wait for 1ms; rst <= '0';  num <= X"E"; wait for 2ms;
        wait; 
    end process; 
end behavioural; 

 