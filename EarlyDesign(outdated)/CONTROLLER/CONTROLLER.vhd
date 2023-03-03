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

entity CONTROLLER_file is end CONTROLLER_file;

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

	-- component MEMORY_file port(
    --     --input signals       
    --     addr_dt: in std_logic_vector(15 downto 0); 
    --     addr_ins: in std_logic_vector(15 downto 0);  

    --     din_dt: in std_logic_vector(15 downto 0); 
        
    --     en_dt: in std_logic;
    --     en_ins: in std_logic;
    --     rst: in std_logic;  
    --     clk: in std_logic;  
    --     regcea: in std_logic;  
    --     regceb: in std_logic;  
    --     wea: in std_logic;

    --     --output signal
    --     dout_dt: in std_logic_vector(15 downto 0);  
    --     dout_ins: in std_logic_vector(15 downto 0)
    -- );
	-- end component;

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

	signal rst, clk: std_logic;
	-- FETCH
	signal brch_addr, CPC, NPC, IR: std_logic_vector(15 downto 0);
	signal brch_en: std_logic;
	-- DECODE
	signal ra_idx, rb_idx, rc_idx: std_logic_vector(2 downto 0);
	signal ra_val, rb_val, rc_val: std_logic_vector(15 downto 0);
	signal IR_decode: std_logic_vector(15 downto 0);
	signal wr_en: std_logic;

	-- EXECUTE
	signal in1, in2, ou1, IR_execute: std_logic_vector(15 downto 0);
	signal z_flag, n_flag, o_flag: std_logic;
	-- signal brch_taken: std_logic;
	signal alu_mode: std_logic_vector(2 downto 0);
	signal shift_count: std_logic_vector(3 downto 0);
	-- MEMORY ACCESS
	signal addr_dt, din_dt, dout_dt: std_logic_vector(15 downto 0);
	signal en_dt, en_ins, regcea, regceb, wea: std_logic;
	signal IR_memoryaccess: std_logic_vector(15 downto 0);
	-- WRITE BACK
	signal IR_writeback: std_logic_vector(15 downto 0);

	begin
	PC : PC_file port map(brch_addr, brch_en, rst, clk, NPC, CPC);	
	-- ra for WRITE only, rb, rc for READ only
	REGISTER: REGISTER_file port map(rst, clk, rb_idx, rc_idx, rb_val, rc_val, ra_idx, ra_val, wr_en);
    ALU: ALU_file port map(in1, in2, alu_mode, shift_count, rst, clk, out1, z_flag, n_flag, o_flag);
	MEMORY: MEMORY_file port map(addr_dt, CPC, din_dt, en_dt, en_ins, rst, clk, regcea, regceb, wea, dout_dt, IR);

	process  begin
        if(clk = '0' and clk'event) then 
			brch_addr <= X"0000";
			brch_en <= '0';
			if (rst='1') then
				IR_writeback <= X"0000";
				IR_memoryaccess <= X"0000";
				IR_execute <= X"0000";
				IR_decode <= X"0000";
				wr_en <= '0';
				alu_mode <= "000";
				shift_count <= "0000";
				en_ins <= '0';
			else
				IR_writeback <= IR_memoryaccess;
				IR_memoryaccess <= IR_execute;
				IR_execute <= IR_decode;
				IR_decode <= IR;
				en_ins <= '1';
			
				-- code for DECODE stage
				case IR_decode(15 downto 9) is
					when "0000000" => --NOP
						NULL
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
				end case;

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
						shift_count <= IR(3 downto 0);
						alu_mode <= "101";					
					when "0000110" => -- SHR
						shift_count <= IR(3 downto 0);
						alu_mode <= "110";					
					when "0000111" => -- TEST
						alu_mode <= "111";					
					when "0100000" => -- OUT
						alu_mode <= "000";					
					when "0100001" => -- IN
						alu_mode <= "000";					
				end case;

				-- code for MEMORY ACCESS stage
				result <= out1;	-- just for Test A format
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
						din_dt <= result;
						addr_dt <= X"FFF2";	-- output port is x"FFF2"
						en_dt <= '0';		
					when "0100001" => -- IN
						addr_dt <= X"FFF0";	-- output port is x"FFF0"
						en_dt <= '1';
				end case;

				-- code for WRITE BACK stage
				case IR_writeback(15 downto 9) is
					when "0000000" => --NOP
						wr_en <= '0';
					when "0000001" => -- ADD
						ra_idx <= IR(8 downto 6);
						ra_val <= result;
						wr_en <= '1';
					when "0000010" => -- SUB
						ra_idx <= IR(8 downto 6);
						ra_val <= result;
						wr_en <= '1';
					when "0000011" => -- MUL
						ra_idx <= IR(8 downto 6);
						ra_val <= result;
						wr_en <= '1';
					when "0000100" => -- NAND
						ra_idx <= IR(8 downto 6);
						ra_val <= result;
						wr_en <= '1';
					when "0000101" => -- SHL
						wr_en <= '0';
					when "0000110" => -- SHR
						wr_en <= '0';
					when "0000111" => -- TEST
						wr_en <= '0';
					when "0100000" => -- OUT
						wr_en <= '0';
					when "0100001" => -- IN
						ra_idx <= <= IR(8 downto 6);	
						ra_val <= dout_dt;
						wr_en <= '1';	
				end case;
			end if;
		end if;
		-- will be changed later
    end process;
 end behavioural;
