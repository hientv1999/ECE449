 
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all; 
use work.all;

entity test_alu is end test_alu;

architecture behavioural of test_alu is

  component ALU_file port(
      --input signals
      in1: in std_logic_vector(15 downto 0); 
      in2: in std_logic_vector(15 downto 0); 
      --alu mode signal
      alu_mode: in std_logic_vector(2 downto 0);
      shift_count: in std_logic_vector(3 downto 0);
      rst : in std_logic; --clock
      clk: in std_logic;  --reset
      --output signals
      result: out std_logic_vector(15 downto 0); 
      z_flag: out std_logic; 
      n_flag: out std_logic;
      o_flag: out std_logic);
  end component; 
  
  signal rst, clk, z_flag, n_flag, o_flag: std_logic; 
  signal alu_mode : std_logic_vector(2 downto 0); 
  signal shift_count: std_logic_vector(3 downto 0);
  signal in1, in2, result : std_logic_vector(15 downto 0); 
  
  begin
  u0 : ALU_file port map(in1, in2, alu_mode, shift_count, rst, clk, result, z_flag, n_flag, o_flag);

  process begin
      clk <= '0'; wait for 10 us;
      clk<= '1'; wait for 10 us; 
  end process;
  
  process
  begin
      --set int = 10, set in2 = 20
      rst <= '1'; in1 <= X"000A"; in2 <= X"0014"; alu_mode <= "000"; shift_count <= "0011";
      wait until (rising_edge(clk));
      rst <= '0';
      wait until (rising_edge(clk)); alu_mode <= "000";         --result = prev,    z_flag = prev,  n_falg = prev
      wait until (clk='1' and clk'event); alu_mode <= "001";    --result = 0x001E,  z_flag = 0,     n_flag = 0
      wait until (clk='1' and clk'event); alu_mode <= "010";    --result = 0xFFF6,  z_flag = 0,     n_flag = 1
      wait until (clk='1' and clk'event); alu_mode <= "011";    --result = 0X00C8,  z_flag = 0,     n_flag = 0
      wait until (clk='1' and clk'event); alu_mode <= "100";    --result = 0xFFFF,  z_flag = 0,     n_flag = 1
      wait until (clk='1' and clk'event); alu_mode <= "101";    --result = 0x0014,  z_flag = 0,     n_flag = 0
      wait until (clk='1' and clk'event); alu_mode <= "110";    --result = 0x0005,  z_flag = 0,     n_flag = 0
      wait until (clk='1' and clk'event); alu_mode <= "111";    --result = 0x000A,  z_flag = 0,     n_flag = 0

      --set int = -20, set in2 = 20
      wait until (clk='1' and clk'event); in1 <= X"FFEC"; in2 <= X"0014"; alu_mode <= "000";  --result = 0x000A,  z_flag = 0,     n_flag = 0
      wait until (clk='1' and clk'event); alu_mode <= "001";    --result = 0x0000,  z_flag = 1,     n_flag = 0
      wait until (clk='1' and clk'event); alu_mode <= "010";    --result = 0xFFD8,  z_flag = 0,     n_flag = 1
      wait until (clk='1' and clk'event); alu_mode <= "011";    --result = 0XFE70,  z_flag = 0,     n_flag = 1
      wait until (clk='1' and clk'event); alu_mode <= "100";    --result = 0xFFFB,  z_flag = 0,     n_flag = 1
      wait until (clk='1' and clk'event); alu_mode <= "101";    --result = 0xFFD8,  z_flag = 0,     n_flag = 1
      wait until (clk='1' and clk'event); alu_mode <= "110";    --result = 0xFFFB,  z_flag = 0,     n_flag = 1
      wait until (clk='1' and clk'event); alu_mode <= "111";    --result = 0xFFEC,  z_flag = 0,     n_flag = 1

      wait;
  end process;
end behavioural;