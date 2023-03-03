 
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use work.all;

entity test_memory is end test_memory;

architecture behavioural of test_memory is

   component MEMORY_file port(
       --input signals       
       addr_dt: in std_logic_vector(15 downto 0); 
       addr_ins: in std_logic_vector(15 downto 0);  

       din_dt: in std_logic_vector(15 downto 0); 
       
       rd_en: in std_logic;
       rst: in std_logic;  
       clk: in std_logic;  
       regcea: in std_logic;  
       regceb: in std_logic;  
       wea: in std_logic;

       --output signal
       dout_dt: in std_logic_vector(15 downto 0);  
       dout_ins: in std_logic_vector(15 downto 0));
   end component;
   
   signal rst, clk, rd_en, regcea, regceb, wea : std_logic; 
   signal addr_dt, addr_ins, din_dt, dout_dt, dout_ins: std_logic_vector(15 downto 0);
   
   begin
   u0 : MEMORY_file port map(addr_dt, addr_ins, din_dt, rd_en, rst, clk, regcea, regceb, wea, dout_dt, dout_ins);

   process begin
       clk <= '0'; wait for 10 us;
       clk<= '1'; wait for 10 us; 
   end process;
   
   process  begin
       --set int = 10, set in2 = 20
       rst <= '1'; addr_dt <= X"0100"; addr_ins <= X"0000"; din_dt <= X"0001"; rd_en <= '0';            -- write X"0001" to addr X"0100"
       regcea <= '1'; regceb <= '1'; wea <= '1';
       wait until (rising_edge(clk));
       rst <= '0';
       wait until (rising_edge(clk)); addr_dt <= X"0200"; addr_ins <= X"0004"; din_dt <= X"0002";       -- write X"0002" to addr X"0200"
       wait until (rising_edge(clk)); addr_dt <= X"0100"; addr_ins <= X"0008"; rd_en <='1';             -- read from addr X"0100" should get X"0001"
       wait until (rising_edge(clk)); addr_dt <= X"0200"; addr_ins <= X"000C";                          -- read from addr X"0200" should get X"0002"
       wait;
   end process;
end behavioural;