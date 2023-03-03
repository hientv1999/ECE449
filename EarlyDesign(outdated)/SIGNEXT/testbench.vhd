 
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use work.all;

entity test_alu is end test_alu;

architecture behavioural of test_alu is

  component SIGNEXT_file port(
	--input signals
	raw_addr: in std_logic_vector(8 downto 0); 
	rst : in std_logic; --clock
	clk: in std_logic;  --reset
	--output signals
	ext_addr: out std_logic_vector(15 downto 0));
  end component; 
  
  signal rst, clk: std_logic; 
  signal raw_addr : std_logic_vector(8 downto 0); 
  signal ext_addr : std_logic_vector(15 downto 0); 
  
  begin
  u0 : SIGNEXT_file port map(raw_addr, rst, clk, ext_addr);

  process begin
      clk <= '0'; wait for 10 us;
      clk<= '1'; wait for 10 us; 
  end process;
  
  process
  begin
      --set int = 10, set in2 = 20
      rst <= '1'; raw_addr <= "000000000";
      wait until (clk='1' and clk'event);
      rst <= '0';
      wait until (clk='1' and clk'event); raw_addr <= "000000011";        
      wait until (clk='1' and clk'event); raw_addr <= "110000011";    
      wait until (clk='1' and clk'event); raw_addr <= "111111100";     


      wait;
  end process;
end behavioural;