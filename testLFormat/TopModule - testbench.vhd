 

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
		z, n, o: out std_logic;
		output_port: out std_logic
	);
    end component;   
    signal rst, clk, z, n, o, output_port: std_logic;  
    signal in1, in2, result : std_logic_vector(15 downto 0);  
    signal btn, num: std_logic_vector(3 downto 0);
    signal input_port: std_logic_vector(9 downto 0);
    signal digit: std_logic_vector(15 downto 0);
    
    begin
    u0 : CONTROLLER_file port map(rst, clk, btn, num, input_port, digit, z, n, o, output_port); 

    process begin 
        clk <= '0'; wait for 5 us; 
        clk <= '1'; wait for 5 us;  
    end process;      

    process begin 
        rst <= '1'; btn <= "0011"; num <= "0101"; input_port <= "0000000000"; wait until (falling_edge(clk)); 
        rst <= '0'; wait until (falling_edge(clk)); 
        wait; 
    end process; 
end behavioural; 

 