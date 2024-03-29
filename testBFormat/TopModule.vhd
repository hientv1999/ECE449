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
		--output signal
		z, n, o: out std_logic;
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
        stall: in std_logic;
        --output signal
        CPC: out std_logic_vector(15 downto 0);
        NPC: out std_logic_vector(15 downto 0)
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
	
	component SIGNEXT_file port (
		--input signals
        raw_addr: in std_logic_vector(8 downto 0); 
        rst : in std_logic; --clock
        clk: in std_logic;  --reset
        --output signals
        ext_addr: out std_logic_vector(15 downto 0)
	);
    end component;
    
	component MEMORY_file port (
		addr_dt: in std_logic_vector(15 downto 0); 
        addr_ins: in std_logic_vector(15 downto 0);  

        din_dt: in std_logic_vector(15 downto 0); 
        
        en_dt: in std_logic;
        en_ins: in std_logic;
        rst: in std_logic;  
        clk: in std_logic;  
        regcea: in std_logic;  
        regceb: in std_logic;  
        wea: in std_logic;

        --output signal
        dout_dt: out std_logic_vector(15 downto 0);  
        dout_ins: out std_logic_vector(15 downto 0)
	);
	end component;

	-- FETCH
	signal brch_addr, CPC, NPC, IR: std_logic_vector(15 downto 0);
	signal brch_en, stall: std_logic;
	-- DECODE
	signal ra_idx, rb_idx, rc_idx: std_logic_vector(2 downto 0);
	signal ra_val, rb_val, rc_val: std_logic_vector(15 downto 0);
    signal wr_en: std_logic;
    signal short_addr: std_logic_vector(8 downto 0);
	-- EXECUTE
	signal ra_idx_execute, rb_idx_execute, rc_idx_execute: std_logic_vector(3 downto 0);
	signal in1, in2, out1, IR_execute, ext_addr, CPC_execute, NPC_execute: std_logic_vector(15 downto 0);
	signal z_flag, n_flag, o_flag: std_logic;
	signal alu_mode: std_logic_vector(2 downto 0);
	signal shift_count: std_logic_vector(3 downto 0);
	-- MEMORY ACCESS
	signal ra_idx_memoryaccess, rb_idx_memoryaccess, rc_idx_memoryaccess: std_logic_vector(3 downto 0);
	signal IR_memoryaccess: std_logic_vector(15 downto 0);
	signal brch_en_memoryaccess: std_logic;
	signal addr_dt, din_dt: std_logic_vector(15 downto 0);
	-- WRITE BACK
	signal ra_idx_writeback, rb_idx_writeback, rc_idx_writeback: std_logic_vector(3 downto 0);
	signal IR_writeback, alu_dt, mem_dt: std_logic_vector(15 downto 0);
	signal en_dt, en_ins, rst_clk, regcea, regceb, wea: std_logic;

	begin
	PC_module : PC_file port map(brch_addr, brch_en, rst, clk, stall, CPC, NPC);	
	-- ra for WRITE only, rb, rc for READ only
	REGISTER_module: REGISTER_file port map(rst, clk, rb_idx, rc_idx, rb_val, rc_val, ra_idx, ra_val, wr_en);
    ALU_module: ALU_file port map(in1, in2, alu_mode, shift_count, rst, clk, out1, z_flag, n_flag, o_flag);
    SIGNEXT_module: SIGNEXT_file port map(short_addr, rst, clk, ext_addr);
    MEMORY_module: MEMORY_file port map(addr_dt, CPC, din_dt, en_dt, en_ins, rst, clk, regcea, regceb, wea, mem_dt, IR);

	process (clk) begin
        if(clk = '1' and clk'event) then 
			brch_addr <= X"0000";
			brch_en <= '0';
			en_ins <= '1';
			z <= z_flag;
			n <= n_flag;
			o <= o_flag;
			-- regcea,regceb,web are unknown signals
			if (rst='1') then
				IR_writeback <= X"0000";
				IR_memoryaccess <= X"0000";
				IR_execute <= X"0000";
				wr_en <= '0';
				n <= '0';
				z <= '0';
				o <= '0';
				alu_mode <= "000";
				shift_count <= "0000";
				out_val <= X"0000";
				ra_idx_execute <= "1000";
				rb_idx_execute <= "1000";
				rc_idx_execute <= "1000";
				ra_idx_memoryaccess <= "1000";
				rb_idx_memoryaccess <= "1000";
				rc_idx_memoryaccess <= "1000";
				ra_idx_writeback <= "1000";
				rb_idx_writeback <= "1000";
				rc_idx_writeback <= "1000";
				stall <= '0';

			else
				-- code for DECODE stage
				IR_execute <= IR;
				CPC_execute <= CPC;
				NPC_execute <= NPC;
				stall <= '0';
				ra_idx_execute <= "1000";
				rb_idx_execute <= "1000";
				rc_idx_execute <= "1000";
				case IR(15 downto 9) is
					when "0000001" => -- ADD
						rb_idx <= IR(5 downto 3);
						rc_idx <= IR(2 downto 0);	
						ra_idx_execute <= '0' & IR(8 downto 6);
						rb_idx_execute <= '0' & IR(5 downto 3);
						rc_idx_execute <= '0' & IR(2 downto 0);	
					when "0000010" => -- SUB
						rb_idx <= IR(5 downto 3);	
						rc_idx <= IR(2 downto 0);	
						ra_idx_execute <= '0' & IR(8 downto 6);
						rb_idx_execute <= '0' & IR(5 downto 3);
						rc_idx_execute <= '0' & IR(2 downto 0);			
					when "0000011" => -- MUL
						rb_idx <= IR(5 downto 3);	
						rc_idx <= IR(2 downto 0);
						ra_idx_execute <= '0' & IR(8 downto 6);
						rb_idx_execute <= '0' & IR(5 downto 3);
						rc_idx_execute <= '0' & IR(2 downto 0);					
					when "0000100" => -- NAND
						rb_idx <= IR(5 downto 3);	
						rc_idx <= IR(2 downto 0);
						ra_idx_execute <= '0' & IR(8 downto 6);
						rb_idx_execute <= '0' & IR(5 downto 3);
						rc_idx_execute <= '0' & IR(2 downto 0);	
					when "0000101" => -- SHL
						rb_idx <= IR(8 downto 6);
						ra_idx_execute <= '0' & IR(8 downto 6);
						rb_idx_execute <= '0' & IR(8 downto 6);
					when "0000110" => -- SHR
						rb_idx <= IR(8 downto 6);
						ra_idx_execute <= '0' & IR(8 downto 6);
						rb_idx_execute <= '0' & IR(8 downto 6);
					when "0000111" => -- TEST
						rb_idx <= IR(8 downto 6);
						rb_idx_execute <= '0' & IR(8 downto 6);
					when "0100000" => -- OUT
						rb_idx <= IR(8 downto 6);
						rb_idx_execute <= '0' & IR(8 downto 6);
					when "0100001" => -- IN
						ra_idx_execute <= '0' & IR(8 downto 6);
					when "1000000" => -- BRR
						short_addr <= IR(8 downto 0);
					when "1000001" => -- BRR.N
						short_addr <= IR(8 downto 0);
					when "1000010" => -- BRR.Z
						short_addr <= IR(8 downto 0);
					when "1000011" => -- BR
						rb_idx <= IR(8 downto 6);
						rb_idx_execute <= '0' & IR(8 downto 6);
						short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
					when "1000100" => -- BR.N
						rb_idx <= IR(8 downto 6);
						rb_idx_execute <= '0' & IR(8 downto 6);
						short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
					when "1000101" => -- BR.Z
						rb_idx <= IR(8 downto 6);
						rb_idx_execute <= '0' & IR(8 downto 6);
						short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
					when "1000110" => -- BR.SUB
						rb_idx <= IR(8 downto 6);
						rb_idx_execute <= '0' & IR(8 downto 6);
						ra_idx_execute <= "0111";
						short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
					when "1000111" => -- RETURN
						rb_idx <= "111";
						rb_idx_execute <= "0111";
					when "0010000" => -- LOAD
						rb_idx <= IR(5 downto 3);
						rb_idx_execute <= '0' & IR(5 downto 3);
						ra_idx_execute <= '0' & IR(8 downto 6);
					when "0010001" => -- STORE
						rb_idx <= IR(5 downto 3);
						rb_idx_execute <= '0' & IR(5 downto 3);
					when "0010010" => --LOADIMM
						ra_idx_execute <= "0111";
					when "0010011" => --MOV
						rb_idx <= IR(5 downto 3);
						rb_idx_execute <= '0' & IR(5 downto 3);
						ra_idx_execute <= '0' & IR(8 downto 6);
					when others => NULL;	
				end case;
				
				-- code for EXECUTE stage
				IR_memoryaccess <= IR_execute;
				ra_idx_memoryaccess <= ra_idx_execute;
				rb_idx_memoryaccess <= rb_idx_execute;
				rc_idx_memoryaccess <= rc_idx_execute;
				brch_en_memoryaccess <= '0';
				case IR_execute(15 downto 9) is
					when "0000000" => --NOP
						alu_mode <= "000";
					when "0000001" => -- ADD
						alu_mode <= "001";
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in2 <= mem_dt;
							end if;
						else
							in2 <= rc_val;	
						end if;
					when "0000010" => -- SUB
						alu_mode <= "010";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in2 <= mem_dt;
							end if;
						else
							in2 <= rc_val;	
						end if;			
					when "0000011" => -- MUL
						alu_mode <= "011";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in2 <= mem_dt;
							end if;
						else
							in2 <= rc_val;	
						end if;				
					when "0000100" => -- NAND
						alu_mode <= "100";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;			
					when "0000101" => -- SHL
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "101";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;				
					when "0000110" => -- SHR
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "110";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;			
					when "0000111" => -- TEST
						alu_mode <= "111";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;				
					when "0100000" => -- OUT
						alu_mode <= "111";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;				
					when "0100001" => -- IN
						alu_mode <= "111";	
					when "1000000" => -- BRR
					    alu_mode <= "001";
					    in1 <= CPC_execute;
					    in2 <= ext_addr;
						brch_en_memoryaccess <= '1';
					when "1000001" => -- BRR.N
					    alu_mode <= "001";
					    in1 <= CPC_execute;
					    if (n_flag = '0') then
                            in2 <= X"0002";
					    else
					       in2 <= ext_addr;
						   brch_en_memoryaccess <= '1';
					    end if;
					when "1000010" => -- BRR.Z
					    alu_mode <= "001";
					    in1 <= CPC_execute;
					    if (z_flag = '0') then
                            in2 <= X"0002";
					    else
					       in2 <= ext_addr;
						   brch_en_memoryaccess <= '1';
					    end if;
					when "1000011" => -- BR
					    alu_mode <= "001";
					    in1 <= rb_val;
					    in2 <= ext_addr;
						brch_en_memoryaccess <= '1';
					when "1000100" => -- BR.N
					    alu_mode <= "001";
					    if (n_flag = '0') then
					       in1 <= CPC_execute;
					       in2 <= X"0002";
					    else
					       in1 <= rb_val;
					       in2 <= ext_addr;
						   brch_en_memoryaccess <= '1';
					    end if;
					when "1000101" => -- BR.Z
					    alu_mode <= "001";
					    if (z_flag = '0') then
					       in1 <= CPC_execute;
					       in2 <= X"0002";
					    else
					       in1 <= rb_val;
					       in2 <= ext_addr;
						   brch_en_memoryaccess <= '1';
					    end if;
					when "1000110" => -- BR.SUB
						brch_en_memoryaccess <= '1';
					    alu_mode <= "001";
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;
					    in2 <= ext_addr;
					when "1000111" => -- RETURN
						brch_en_memoryaccess <= '1';
					    alu_mode <= "111";
					    if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;
					when "0010000" => -- LOAD
						alu_mode <= "111";
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;				
					when "0010001" => -- STORE
						alu_mode <= "111";
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;		
					when "0010010" => --LOADIMM
						NULL;
					when "0010011" => --MOV
						alu_mode <= "111";
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';

								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;

							else
								in1 <= out1;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							in1 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								in1 <= mem_dt;
							end if;
						else
							in1 <= rb_val;	
						end if;		
					when others => NULL;				
				end case;
				

				-- code for MEMORY ACCESS stage
				IR_writeback <= IR_memoryaccess;
				ra_idx_writeback <= ra_idx_memoryaccess;
				rb_idx_writeback <= rb_idx_memoryaccess;
				rc_idx_writeback <= rc_idx_memoryaccess;
				alu_dt <= out1;
				brch_en <= brch_en_memoryaccess;
				brch_addr <= out1;
				en_dt <= '0';
				wea <= '0';
				if (brch_en_memoryaccess = '1') then
					-- clear instruction in previous stages as we have branched
					IR_memoryaccess <= X"0000";
					ra_idx_memoryaccess <= "1000";
					rb_idx_memoryaccess <= "1000";
					rc_idx_memoryaccess <= "1000";
					brch_en_memoryaccess <= '0';

					IR_execute <= X"0000";
					ra_idx_execute <= "1000";
					rb_idx_execute <= "1000";
					rc_idx_execute <= "1000";
				end if;
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
						addr_dt <= X"FFF2";
						din_dt <= out1;
						en_dt <= '1';
						wea <= '1';
					when "0100001" => -- IN
						addr_dt <= X"FFF0";
						en_dt <= '1';
					when "1000000" => -- BRR
						NULL;
					when "1000001" => -- BRR.N
						NULL;
					when "1000010" => -- BRR.Z
						NULL;
					when "1000011" => -- BR
						NULL;
					when "1000100" => -- BR.N
						NULL;
					when "1000101" => -- BR.Z
						NULL;
					when "1000110" => -- BR.SUB
						NULL;
					when "1000111" => -- RETURN
					    NULL;
					when "0010000" => -- LOAD
						addr_dt <= out1;
						en_dt <= '1';
					when "0010001" => -- STORE
						addr_dt <= IR_memoryaccess(8 downto 6);
						din_dt <= out1;
						en_dt <= '1';
						wea <= '1';
					when "0010010" => --LOADIMM
						NULL;
					when "0010011" => --MOV
						alu_dt <= out1;
					when others => NULL;
				end case;

				-- code for WRITE BACK stage
				wr_en <= '0';
				case IR_writeback(15 downto 9) is
					when "0000000" => --NOP
					when "0000001" => -- ADD
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000010" => -- SUB
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000011" => -- MUL
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000100" => -- NAND
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000101" => -- SHL
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000110" => -- SHR
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0000111" => -- TEST
						NULL;
					when "0100000" => -- OUT
						NULL;
					when "0100001" => -- IN
						ra_idx <= ra_idx_writeback(2 downto 0);	
						ra_val <= mem_dt;
						wr_en <= '1';	
					when "1000000" => -- BRR
					    NULL;
					when "1000001" => -- BRR.N
					    NULL;
					when "1000010" => -- BRR.Z
					    NULL;
					when "1000011" => -- BR
					    NULL;
					when "1000100" => -- BR.N
					    NULL;
					when "1000101" => -- BR.Z
					    NULL;
					when "1000110" => -- BR.SUB
					    wr_en <= '1';
					    ra_idx <= ra_idx_writeback(2 downto 0);	
					    ra_val <= alu_dt;
					when "1000111" => -- RETURN
					    NULL;
					when "0010000" => -- LOAD
						ra_idx <= IR_writeback(8 downto 6);
						ra_val <= mem_dt;
						wr_en <= '1';
					when "0010001" => -- STORE
						NULL;
					when "0010010" => --LOADIMM
						ra_idx <= "111";
						if (IR_writeback(8) = '1') then
							ra_val <= IR_writeback(7 downto 0) & X"00";
						else
							ra_val <= X"00" & IR_writeback(7 downto 0);
						end if;
						wr_en <= '1';
					when "0010011" => --MOV
						ra_idx <= IR_writeback(8 downto 6);
						ra_val <= alu_dt;
						wr_en <= '1';
					when others => NULL;
				end case;
			end if;
		end if;
		-- will be changed later
		PC <= CPC;
    end process;
 end behavioural;
