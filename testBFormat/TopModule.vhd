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
	
	component SIGNEXT_file port (
		--input signals
        raw_addr: in std_logic_vector(8 downto 0); 
        rst : in std_logic; --clock
        clk: in std_logic;  --reset
        --output signals
        ext_addr: out std_logic_vector(15 downto 0)
	);
	end component;

	-- FETCH
	signal brch_addr, CPC: std_logic_vector(15 downto 0);
	signal brch_en, stall: std_logic;
	type queue_register is array(0 to 2) of std_logic_vector(3 downto 0);
	signal pending_registers : queue_register;
	-- DECODE
	signal ra_idx, rb_idx, rc_idx: std_logic_vector(2 downto 0);
	signal ra_val, rb_val, rc_val: std_logic_vector(15 downto 0);
    signal wr_en: std_logic;
    signal short_addr: std_logic_vector(8 downto 0);
	-- EXECUTE
	signal in1, in2, out1, IR_execute, ext_addr, CPC_execute: std_logic_vector(15 downto 0);
	signal z_flag, n_flag, o_flag: std_logic;
	-- signal brch_taken: std_logic;
	signal alu_mode: std_logic_vector(2 downto 0);
	signal shift_count: std_logic_vector(3 downto 0);
	-- MEMORY ACCESS
	signal IR_memoryaccess: std_logic_vector(15 downto 0);
	-- WRITE BACK
	signal IR_writeback, alu_dt: std_logic_vector(15 downto 0);

	begin
	PC_module : PC_file port map(brch_addr, brch_en, rst, clk, stall, CPC);	
	-- ra for WRITE only, rb, rc for READ only
	REGISTER_module: REGISTER_file port map(rst, clk, rb_idx, rc_idx, rb_val, rc_val, ra_idx, ra_val, wr_en);
    ALU_module: ALU_file port map(in1, in2, alu_mode, shift_count, rst, clk, out1, z_flag, n_flag, o_flag);
    SIGNEXT_module: SIGNEXT_file port map(short_addr, rst, clk, ext_addr);
    
	process (clk) begin
        if(clk = '1' and clk'event) then 
			brch_addr <= X"0000";
			brch_en <= '0';
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
				pending_registers(0) <= "1000";
				pending_registers(1) <= "1000";
				pending_registers(2) <= "1000";
				stall <= '0';
			else
				-- code for DECODE stage
				IR_execute <= IR;
				CPC_execute <= CPC;
				stall <= '0';
				-- Pop out last element of queue, push to top of queue the register that will be changed in current instruction
				pending_registers(0) <= "1000";
				pending_registers(1) <= pending_registers(0);
				pending_registers(2) <= pending_registers(1);
				-- check if the needed registers are still being computed in subsequent stages
				if (IR(15 downto 9) = "0000001" or IR(15 downto 9) = "0000010" or IR(15 downto 9) = "0000011" or IR(15 downto 9) = "0000100") then
					-- A1 format
					if ((IR(5 downto 3) = pending_registers(0)(2 downto 0) or IR(2 downto 0) = pending_registers(0)(2 downto 0)) and pending_registers(0)(3) = '0') then
						-- rb or rc are still being computed in previous instruction
						IR_execute <= X"0000";	-- introduce NOP
						stall <= '1';			-- stall PC	
					elsif((IR(5 downto 3) = pending_registers(1)(2 downto 0) or IR(2 downto 0) = pending_registers(1)(2 downto 0)) and pending_registers(1)(3) = '0') then
						-- rb or rc are still being computed in 2 instructions before current instruction
						IR_execute <= X"0000";	-- introduce NOP
						stall <= '1';			-- stall PC		
					elsif((IR(5 downto 3) = pending_registers(2)(2 downto 0) or IR(2 downto 0) = pending_registers(2)(2 downto 0)) and pending_registers(2)(3) = '0') then
						-- rb or rc are still being computed in 3 instructions before current instruction
						IR_execute <= X"0000";	-- introduce NOP
						stall <= '1';			-- stall PC		
					else
						-- process A1 format normally
						case IR(15 downto 9) is
							when "0000001" => -- ADD
								rb_idx <= IR(5 downto 3);
								rc_idx <= IR(2 downto 0);	
								pending_registers(0) <= '0' & IR(8 downto 6);
							when "0000010" => -- SUB
								rb_idx <= IR(5 downto 3);	
								rc_idx <= IR(2 downto 0);	
								pending_registers(0) <= '0' & IR(8 downto 6);			
							when "0000011" => -- MUL
								rb_idx <= IR(5 downto 3);	
								rc_idx <= IR(2 downto 0);
								pending_registers(0) <= '0' & IR(8 downto 6);				
							when "0000100" => -- NAND
								rb_idx <= IR(5 downto 3);	
								rc_idx <= IR(2 downto 0);
							when others => NULL;	
						end case;
					end if;
				elsif(IR(15 downto 9) = "0000101" or IR(15 downto 9) = "0000110" or IR(15 downto 9) = "0000111" or IR(15 downto 9) = "0100000" or IR(15 downto 9) = "0100001" or IR(15 downto 9) = "1000011" or IR(15 downto 9) = "1000100" or IR(15 downto 9) = "1000101" or IR(15 downto 9) = "1000110") then
					-- A2, A3, B2 formats
					if (IR(8 downto 6) = pending_registers(0)(2 downto 0) and pending_registers(0)(3) = '0') then
						-- ra is still being computed in previous instruction
						IR_execute <= X"0000";	-- introduce NOP
						stall <= '1';			-- stall PC		
					elsif(IR(8 downto 6) = pending_registers(1)(2 downto 0) and pending_registers(1)(3) = '0') then
						-- ra is still being computed in 2 instructions before current instruction
						IR_execute <= X"0000";	-- introduce NOP
						stall <= '1';			-- stall PC		
					elsif(IR(8 downto 6) = pending_registers(2)(2 downto 0) and pending_registers(2)(3) = '0') then
						-- ra is still being computed in 3 instructions before current instruction
						IR_execute <= X"0000";	-- introduce NOP
						stall <= '1';			-- stall PC		
					else
						-- process A2, A3, B2 formats normally
						case IR(15 downto 9) is		
							when "0000101" => -- SHL
								rb_idx <= IR(8 downto 6);
								pending_registers(0) <= '0' & IR(8 downto 6);
							when "0000110" => -- SHR
								rb_idx <= IR(8 downto 6);
								pending_registers(0) <= '0' & IR(8 downto 6);
							when "0000111" => -- TEST
								rb_idx <= IR(8 downto 6);
							when "0100000" => -- OUT
								rb_idx <= IR(8 downto 6);
							when "0100001" => -- IN
								pending_registers(0) <= '0' & IR(8 downto 6);
							when "1000011" => -- BR
								rb_idx <= IR(8 downto 6);
								short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
								stall <= '1';			-- stall PC	
							when "1000100" => -- BR.N
								rb_idx <= IR(8 downto 6);
								short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
								stall <= '1';			-- stall PC	
							when "1000101" => -- BR.Z
								rb_idx <= IR(8 downto 6);
								short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
								stall <= '1';			-- stall PC	
							when "1000110" => -- BR.SUB
								rb_idx <= IR(8 downto 6);
								short_addr <= IR(5) & IR(5) & IR(5) & IR(5 downto 0);
								stall <= '1';			-- stall PC	
							when others => NULL;
						end case;
					end if;	
				elsif (IR(15 downto 9) = "1000111") then
					-- RETURN instruction
					stall <= '1';			-- stall PC
					if (pending_registers(0)(2 downto 0) = "111" and pending_registers(0)(3) = '0') then
						IR_execute <= X"0000";	-- introduce NOP
					elsif (pending_registers(1)(2 downto 0) = "111" and pending_registers(1)(3) = '0') then
						IR_execute <= X"0000";	-- introduce NOP
					elsif (pending_registers(2)(2 downto 0) = "111" and pending_registers(2)(3) = '0') then
						IR_execute <= X"0000";	-- introduce NOP
					else
						-- process RETURN instruction normally
						rb_idx <= "111";
					end if;
				elsif (IR(15 downto 9) = "1000000" or IR(15 downto 9) = "1000001" or IR(15 downto 9) = "1000010") then
					-- B1 format
					stall <= '1';			-- stall PC	
					short_addr <= IR(8 downto 0);
				end if;
				
				-- code for EXECUTE stage
				case IR_execute(15 downto 9) is
					when "0000000" => --NOP
						alu_mode <= "000";
						in1 <= rb_val;	
				        in2 <= rc_val;	
					when "0000001" => -- ADD
						alu_mode <= "001";
						in1 <= rb_val;	
				        in2 <= rc_val;
					when "0000010" => -- SUB
						alu_mode <= "010";	
						in1 <= rb_val;	
				        in2 <= rc_val;				
					when "0000011" => -- MUL
						alu_mode <= "011";	
						in1 <= rb_val;	
				        in2 <= rc_val;				
					when "0000100" => -- NAND
						alu_mode <= "100";	
						in1 <= rb_val;			
					when "0000101" => -- SHL
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "101";	
						in1 <= rb_val;				
					when "0000110" => -- SHR
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "110";	
						in1 <= rb_val;			
					when "0000111" => -- TEST
						alu_mode <= "111";	
						in1 <= rb_val;				
					when "0100000" => -- OUT
						alu_mode <= "111";	
						in1 <= rb_val;				
					when "0111101" => -- IN
						alu_mode <= "111";	
					when "1000000" => -- BRR
					    alu_mode <= "001";
					    in1 <= CPC_execute;
					    in2 <= ext_addr;
					when "1000001" => -- BRR.N
					    alu_mode <= "001";
					    in1 <= CPC_execute;
					    if (n_flag = '0') then
                            in2 <= X"0002";
					    else
					       in2 <= ext_addr;
					    end if;
					when "1000010" => -- BRR.Z
					    alu_mode <= "001";
					    in1 <= CPC_execute;
					    if (z_flag = '0') then
                            in2 <= X"0002";
					    else
					       in2 <= ext_addr;
					    end if;
					when "1000011" => -- BR
					    alu_mode <= "001";
					    in1 <= rb_val;
					    in2 <= ext_addr;
					when "1000100" => -- BR.N
					    alu_mode <= "001";
					    if (n_flag = '0') then
					       in1 <= CPC_execute;
					       in2 <= X"0002";
					    else
					       in1 <= rb_val;
					       in2 <= ext_addr;
					    end if;
					when "1000101" => -- BR.Z
					    alu_mode <= "001";
					    if (z_flag = '0') then
					       in1 <= CPC_execute;
					       in2 <= X"0002";
					    else
					       in1 <= rb_val;
					       in2 <= ext_addr;
					    end if;
					when "1000110" => -- BR.SUB
					    alu_mode <= "001";
					    in1 <= rb_val;
					    in2 <= ext_addr;
					when "1000111" => -- RETURN
					    alu_mode <= "111";
					    in1 <= rb_val;
					when others => NULL;				
				end case;
				IR_memoryaccess <= IR_execute;

				-- code for MEMORY ACCESS stage
				alu_dt <= out1;
				brch_en <= '0';
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
						z <= z_flag;
						n <= n_flag;
						o <= o_flag;
					when "0100001" => -- IN
						NULL;
					when "1000000" => -- BRR
					    brch_en <= '1';
						stall <= '0';
					    brch_addr <= out1;
						IR_memoryaccess <= X"0000"; 	-- clear instruciton in previous stage as we have branched
						IR_execute <= X"0000";			-- clear instruciton in previous stage as we have branched
					when "1000001" => -- BRR.N
					    brch_en <= '1';
						stall <= '0';
					    brch_addr <= out1;
						IR_memoryaccess <= X"0000"; 	-- clear instruciton in previous stage as we have branched
						IR_execute <= X"0000";			-- clear instruciton in previous stage as we have branched
					when "1000010" => -- BRR.Z
					    brch_en <= '1';
						stall <= '0';
					    brch_addr <= out1;
						IR_memoryaccess <= X"0000"; 	-- clear instruciton in previous stage as we have branched
						IR_execute <= X"0000";			-- clear instruciton in previous stage as we have branched
					when "1000011" => -- BR
					    brch_en <= '1';
						stall <= '0';
					    brch_addr <= out1;
						IR_memoryaccess <= X"0000"; 	-- clear instruciton in previous stage as we have branched
						IR_execute <= X"0000";			-- clear instruciton in previous stage as we have branched
					when "1000100" => -- BR.N
					    brch_en <= '1';
						stall <= '0';
					    brch_addr <= out1;
						IR_memoryaccess <= X"0000"; 	-- clear instruciton in previous stage as we have branched
						IR_execute <= X"0000";			-- clear instruciton in previous stage as we have branched
					when "1000101" => -- BR.Z
					    brch_en <= '1';
						stall <= '0';
					    brch_addr <= out1;
						IR_memoryaccess <= X"0000"; 	-- clear instruciton in previous stage as we have branched
						IR_execute <= X"0000";			-- clear instruciton in previous stage as we have branched
					when "1000110" => -- BR.SUB
					    brch_en <= '1';
						stall <= '0';
					    brch_addr <= out1;
					    alu_dt <= CPC_execute;
						IR_memoryaccess <= X"0000"; 	-- clear instruciton in previous stage as we have branched
						IR_execute <= X"0000";			-- clear instruciton in previous stage as we have branched
					when "1000111" => -- RETURN
					    brch_en <= '1';
						stall <= '0';
					    brch_addr <= out1;
						IR_memoryaccess <= X"0000"; 	-- clear instruciton in previous stage as we have branched
						IR_execute <= X"0000";			-- clear instruciton in previous stage as we have branched
					when others => NULL;
				end case;
				IR_writeback <= IR_memoryaccess;

				-- code for WRITE BACK stage
				wr_en <= '0';
				case IR_writeback(15 downto 9) is
					when "0000000" => --NOP
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
						NULL;
					when "0100000" => -- OUT
						NULL;
					when "0100001" => -- IN
						ra_idx <= IR_writeback(8 downto 6);	
						if (IR_writeback(8 downto 6) = "000") then
							ra_val <= X"0002"; -- or 0x"FFFE" for R0 = -2 in test B part 3
						elsif (IR_writeback(8 downto 6) = "001") then
							ra_val <= X"0003";
						elsif (IR_writeback(8 downto 6) = "010") then
							ra_val <= X"0001";
						elsif (IR_writeback(8 downto 6) = "011") then
							ra_val <= X"0005";
						elsif (IR_writeback(8 downto 6) = "100") then
							ra_val <= X"0210";
						elsif (IR_writeback(8 downto 6) = "101") then
							ra_val <= X"0001";
						elsif (IR_writeback(8 downto 6) = "110") then
							ra_val <= X"0005";
						else
							ra_val <= X"0000";
						end if;
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
					    ra_idx <= "111";
					    ra_val <= alu_dt;
					when "1000111" => -- RETURN
					    NULL;
					when others => NULL;
				end case;
			end if;
		end if;
		-- will be changed later
		PC <= CPC;
    end process;
 end behavioural;
