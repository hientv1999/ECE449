-----------------------------------------------------------
--
-- ECE241 Lab 2
--
-- First example - a simple 2-input NAND gate
--
-- (c)2018 Dr. D. Capson   Dept. of ECE
--                         University of Victoria
--
-----------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity register is
port (
        input_reg    : in STD_LOGIC_VECTOR(15 downto 0);
        action_reg   : in STD_LOGIC;   -- 0: store; 1: load
        addr_reg     : in STD_LOGIC_VECTOR(2 downto 0);
        output_reg   : out STD_LOGIC_VECTOR(15 downto 0)
      );
	
end register;

architecture Behavioural of register is

type REGISTER_TYPE is array (0 to 7) of std_logic_vector(15 downto 0);
signal registers : REGISTER_TYPE;

begin
    if action == '0' then
        registers(addr_reg) <= input;
    else
	   output <= registers(addr_reg);

end Behavioural;

