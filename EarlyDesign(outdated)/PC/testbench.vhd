 
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use work.all;

entity test_pc is end test_pc;

architecture behavioural of test_pc is

   component PC_file port(
       --input signals
       brch_addr: in std_logic_vector(15 downto 0);  
       brch_en: in std_logic;
       rst: in std_logic;  
       clk: in std_logic;  
       --output signal
       NPC: out std_logic_vector(15 downto 0);
       CPC: out std_logic_vector(15 downto 0));
   end component; 
   
   signal rst, clk, brch_en : std_logic; 
   signal brch_addr, NPC, CPC: std_logic_vector(15 downto 0);
   
   begin
   u0 : PC_file port map(brch_addr, brch_en, rst, clk, NPC, CPC);

   process begin
       clk <= '0'; wait for 10 us;
       clk<= '1'; wait for 10 us; 
   end process;
   
   process  begin
       --set int = 10, set in2 = 20
       rst <= '1'; brch_addr <= X"0FF0"; brch_en <= '0'; wait until (rising_edge(clk));  wait until (rising_edge(clk));
       rst <= '0'; wait until (rising_edge(clk));                                   -- CPC = X"0000"; NPC = X"0004"
       wait until (rising_edge(clk));                                               -- CPC = X"0004"; NPC = X"0008"
       brch_en <= '1'; wait until (rising_edge(clk));                               -- CPC = X"0008"; NPC = X"0FF0"
       brch_en <= '0';
       wait until (rising_edge(clk));                                               -- CPC = X"0FF0"; NPC = X"0FF4"
       wait;
   end process;
end behavioural;