 

library ieee;  
use ieee.std_logic_1164.all;  
use ieee.std_logic_unsigned.all;  
use work.all; 


entity test_controller_sub is end test_controller_sub; 

architecture behavioural of test_controller_sub is 
    component ALU_file port( 
        --input signals
            in1: in std_logic_vector(15 downto 0); 
in2: in std_logic_vector(15 downto 0); 
                --alu mode signal
                alu_mode: in std_logic_vector(2 downto 0);
                shift_count: in std_logic_vector(3 downto 0);
                rst : in std_logic; --clock
                clk: in std_logic;  --reset
                hold_flag: in std_logic;
                --output signals
                result: out std_logic_vector(15 downto 0); 
                z_flag: out std_logic; 
                n_flag: out std_logic;
                o_flag: out std_logic
    );
    end component;   
    signal rst, clk, z, n, o, hold_flag: std_logic;
    signal in1, in2, result : std_logic_vector(15 downto 0);  
    signal alu_mode: std_logic_vector(2 downto 0);
    signal shift_count: std_logic_vector(3 downto 0);
    
    begin 
    u0 : ALU_file port map(in1, in2, alu_mode, shift_count, rst, clk, hold_flag, result, z, n, o); 

    process begin 
        clk <= '0'; wait for 10 us; 
        clk <= '1'; wait for 10 us;  
    end process;      

    process begin 
        rst <= '1'; in1 <= X"001e";in2 <= X"0002"; alu_mode <= "001"; shift_count <= "0000"; hold_flag <= '0'; wait until (falling_edge(clk));  
        rst <= '0'; wait until (falling_edge(clk));     
        wait; 
    end process; 
end behavioural; 

 