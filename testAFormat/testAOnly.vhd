-----------------------------------------------------------
--
-- ECE241 Lab 2
--
-- Second example that implements some simple random logic
--
-- (c)2018 Dr. D. Capson    Dept. of ECE
--                          University of Victoria
--
-----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CONTROLLER_file is 
	port(
		--input signals
		rst: in std_logic;  
		clk: in std_logic;
		IR: in std_logic_vector(15 downto 0);  
		--output signal
		PC: out std_logic_vector(15 downto 0);
		out_val: out std_logic_vector(15 downto 0)
	);
end CONTROLLER_file;

architecture behavioural of CONTROLLER_file is
	component ALU_file port (
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
		o_flag: out std_logic
	);
	end component;

	component PC_file port (
		--input signals
        brch_addr: in std_logic_vector(15 downto 0);  
        brch_en: in std_logic;
        rst: in std_logic;  
        clk: in std_logic;  
        --output signal
        NPC: out std_logic_vector(15 downto 0);
        CPC: out std_logic_vector(15 downto 0)
	);
	end component;

	component REGISTER_file port (
		rst : in std_logic; 
        clk: in std_logic;
        --read signals
        rd_index1, rd_index2 : in std_logic_vector(2 downto 0);
        rd_data1, rd_data2: out std_logic_vector(15 downto 0);
        --write signals
        wr_index: in std_logic_vector(2 downto 0);
        wr_data: in std_logic_vector(15 downto 0);
        wr_enable: in std_logic
	);
	end component;

	-- FETCH
	signal brch_addr, CPC, NPC: std_logic_vector(15 downto 0);
	signal brch_en: std_logic;
	-- DECODE
	signal ra_idx, rb_idx, rc_idx: std_logic_vector(2 downto 0);
	signal ra_val, rb_val, rc_val: std_logic_vector(15 downto 0);
	signal wr_en: std_logic;

	-- EXECUTE
	signal in1, in2, out1, IR_execute: std_logic_vector(15 downto 0);
	signal z_flag, n_flag, o_flag: std_logic;
	-- signal brch_taken: std_logic;
	signal alu_mode: std_logic_vector(2 downto 0);
	signal shift_count: std_logic_vector(3 downto 0);
	-- MEMORY ACCESS
	signal IR_memoryaccess: std_logic_vector(15 downto 0);
	-- WRITE BACK
	signal IR_writeback, alu_dt: std_logic_vector(15 downto 0);

	begin
	PC_module : PC_file port map(brch_addr, brch_en, rst, clk, NPC, CPC);	
	-- ra for WRITE only, rb, rc for READ only
	REGISTER_module: REGISTER_file port map(rst, clk, rb_idx, rc_idx, rb_val, rc_val, ra_idx, ra_val, wr_en);
    ALU_module: ALU_file port map(in1, in2, alu_mode, shift_count, rst, clk, out1, z_flag, n_flag, o_flag);

	process (clk) begin
        if(clk = '1' and clk'event) then 
			brch_addr <= X"0000";
			brch_en <= '0';
			if (rst='1') then
				IR_writeback <= X"0000";
				IR_memoryaccess <= X"0000";
				IR_execute <= X"0000";
				wr_en <= '0';
				alu_mode <= "000";
				shift_count <= "0000";
				out_val <= X"0000";
			else

				-- code for DECODE stage
				case IR(15 downto 9) is
					when "0000000" => --NOP
						NULL;
					when "0000001" => -- ADD
						rb_idx <= IR(5 downto 3);
						rc_idx <= IR(2 downto 0);					
					when "0000010" => -- SUB
						rb_idx <= IR(5 downto 3);	
						rc_idx <= IR(2 downto 0);				
					when "0000011" => -- MUL
						rb_idx <= IR(5 downto 3);	
						rc_idx <= IR(2 downto 0);				
					when "0000100" => -- NAND
						rb_idx <= IR(5 downto 3);	
						rc_idx <= IR(2 downto 0);				
					when "0000101" => -- SHL
						rb_idx <= IR(8 downto 6);
					when "0000110" => -- SHR
						rb_idx <= IR(8 downto 6);
					when "0000111" => -- TEST
						rb_idx <= IR(8 downto 6);
					when "0100000" => -- OUT
						rb_idx <= IR(8 downto 6);
					when "0100001" => -- IN
						NULL;
					when others => NULL; 
				end case;
				IR_execute <= IR;

				-- code for EXECUTE stage
				in1 <= rb_val;	-- just for Test A format
				in2 <= rc_val;	-- just for Test A format
				case IR_execute(15 downto 9) is
					when "0000000" => --NOP
						alu_mode <= "000";
					when "0000001" => -- ADD
						alu_mode <= "001";
					when "0000010" => -- SUB
						alu_mode <= "010";					
					when "0000011" => -- MUL
						alu_mode <= "011";					
					when "0000100" => -- NAND
						alu_mode <= "100";					
					when "0000101" => -- SHL
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "101";					
					when "0000110" => -- SHR
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "110";					
					when "0000111" => -- TEST
						alu_mode <= "111";					
					when "0100000" => -- OUT
						alu_mode <= "111";					
					when "0111101" => -- IN
						alu_mode <= "111";	
					when others => NULL; 				
				end case;
				IR_memoryaccess <= IR_execute;

				-- code for MEMORY ACCESS stage
				alu_dt <= out1;
				case IR_memoryaccess(15 downto 9) is
					when "0000000" => --NOP
						NULL;
					when "0000001" => -- ADD
						NULL;
					when "0000010" => -- SUB
						NULL;			
					when "0000011" => -- MUL
						NULL;				
					when "0000100" => -- NAND
						NULL;				
					when "0000101" => -- SHL
						NULL;				
					when "0000110" => -- SHR
						NULL;			
					when "0000111" => -- TEST
						NULL;				
					when "0100000" => -- OUT
						out_val <= out1;
					when "0100001" => -- IN
						NULL;
					when others => NULL; 
				end case;
				IR_writeback <= IR_memoryaccess;

				-- code for WRITE BACK stage
				case IR_writeback(15 downto 9) is
					when "0000000" => --NOP
						wr_en <= '0';
					when "0000001" => -- ADD
						ra_idx <= IR_writeback(8 downto 6);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000010" => -- SUB
						ra_idx <= IR_writeback(8 downto 6);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000011" => -- MUL
						ra_idx <= IR_writeback(8 downto 6);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000100" => -- NAND
						ra_idx <= IR_writeback(8 downto 6);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000101" => -- SHL
						ra_idx <= IR_writeback(8 downto 6);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000110" => -- SHR
						ra_idx <= IR_writeback(8 downto 6);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000111" => -- TEST
						wr_en <= '0';
					when "0100000" => -- OUT
						wr_en <= '0';
					when "0100001" => -- IN
						ra_idx <= IR_writeback(8 downto 6);	
						if (IR_writeback(8 downto 6) = "001") then
							ra_val <= X"0003";
						else
							ra_val <= X"0005";
						end if;
						wr_en <= '1';	
					when others => NULL; 
				end case;
				
			end if;
		end if;
		-- will be changed later
		PC <= CPC;
    end process;
 end behavioural;
