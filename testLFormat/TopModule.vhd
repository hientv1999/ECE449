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
		clk_display: in std_logic;
		btn,num: in std_logic_vector(3 downto 0);
		input_port: in std_logic_vector(9 downto 0);
		-- output signals
        an: out std_logic_vector(3 downto 0);
        sseg: out std_logic_vector(6 downto 0);
		z, n, o: out std_logic;
		output_port: out std_logic

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
		hold_flag: in std_logic;
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
    
	component RAM_file port (
		--input signals       
        addr_dt: in std_logic_vector(15 downto 0); 
        addr_ins: in std_logic_vector(15 downto 0);  

        din_dt: in std_logic_vector(15 downto 0);
        
        wr_mem_en: in std_logic_vector(0 downto 0);
        rst: in std_logic;  
        clk: in std_logic;  

        --output signal
        dout_dt: out std_logic_vector(15 downto 0);  
        dout_ins: out std_logic_vector(15 downto 0)
	);
	end component;
	
	component ROM_file port(
        --input signals       
        addr: in std_logic_vector(15 downto 0); 

        rst: in std_logic;  
        clk: in std_logic; 

        -- output signal
        dout: out std_logic_vector(15 downto 0)
    );
    end component;
    
    component MUX_file port(
        in1: in std_logic_vector(15 downto 0);
        in2: in std_logic_vector(15 downto 0);
        sel, stall: in std_logic;
        out1: out std_logic_vector(15 downto 0)
    );
    end component;
    
    component display_controller port(
        clk, reset: in std_logic;
        hex3, hex2, hex1, hex0: in std_logic_vector(3 downto 0);
        an: out std_logic_vector(3 downto 0);
        sseg: out std_logic_vector(6 downto 0)
    );
    end component;

    signal CPU_output: std_logic_vector(15 downto 0);
	signal digit3, digit2, digit1, digit0: std_logic_vector(3 downto 0);
	-- FETCH
	signal brch_addr, CPC, IR_ROM, IR_RAM, IR: std_logic_vector(15 downto 0);
	signal brch_en, stall: std_logic;
	-- DECODE
	signal ra_idx, rb_idx, rc_idx: std_logic_vector(2 downto 0);
	signal ra_val, rb_val, rc_val: std_logic_vector(15 downto 0);
    signal wr_en: std_logic;
    signal short_addr: std_logic_vector(8 downto 0);
	-- EXECUTE
	signal ra_idx_execute, rb_idx_execute, rc_idx_execute: std_logic_vector(3 downto 0);
	signal in1, in2, IR_execute, ext_addr, CPC_execute: std_logic_vector(15 downto 0);
	signal z_flag, n_flag, o_flag, stall_MUX, hold_flag: std_logic;
	signal alu_mode: std_logic_vector(2 downto 0);
	signal shift_count: std_logic_vector(3 downto 0);
	-- MEMORY ACCESS
	signal ra_idx_memoryaccess, rb_idx_memoryaccess, rc_idx_memoryaccess: std_logic_vector(3 downto 0);
	signal IR_memoryaccess, out1, out2: std_logic_vector(15 downto 0);
	signal addr_dt, din_dt: std_logic_vector(15 downto 0);
	-- WRITE BACK
	signal ra_idx_writeback, rb_idx_writeback, rc_idx_writeback: std_logic_vector(3 downto 0);
	signal IR_writeback, alu_dt, mem_dt: std_logic_vector(15 downto 0);
	signal rst_clk, regcea, regceb: std_logic;
	signal wr_mem_en: std_logic_vector(0 downto 0);

	begin
	PC_module : PC_file port map(brch_addr, brch_en, rst, clk, stall, CPC);	
	-- ra for WRITE only, rb, rc for READ only
	REGISTER_module: REGISTER_file port map(rst, clk, rb_idx, rc_idx, rb_val, rc_val, ra_idx, ra_val, wr_en);
    ALU_module: ALU_file port map(in1, in2, alu_mode, shift_count, rst, clk, hold_flag, out1, z_flag, n_flag, o_flag);
    SIGNEXT_module: SIGNEXT_file port map(short_addr, rst, clk, ext_addr);
    RAM_module: RAM_file port map(addr_dt, CPC, din_dt, wr_mem_en, rst, clk, mem_dt, IR_RAM);
    ROM_module: ROM_file port map(CPC, rst, clk, IR_ROM);
    MUX_ROMRAM: MUX_file port map(IR_ROM, IR_RAM, stall_MUX, CPC(10), IR);
    DISPLAY_module: display_controller port map(clk_display, rst, digit3, digit2, digit1, digit0, an, sseg); 

	process(clk_display) begin
	    -- 0000: CPC
	    -- 0001: IR
	    -- 0010: num
	    -- 0011: CPU_output
	    -- 0100: rb_idx
	    -- 0101: rc_idx
	    -- 0110: rb_val
	    -- 0111: rc_val
	    -- 1000: in1
	    -- 1001: in2
	    -- 1010: alu_mode, shift_count
	    -- 1011: out1
	    -- 1100: brch_en, stall
	    -- 1101: brch_addr
	    -- 1110: wr_en, ra_idx
	    -- 1111: ra_val
		if (clk_display = '0' and clk_display'event) then
			if (btn = "0000") then			-- CPC
                digit3 <= CPC(15 downto 12);
                digit2 <= CPC(11 downto 8);
                digit1 <= CPC(7 downto 4);
                digit0 <= CPC(3 downto 0);
            elsif (btn = "0001") then		-- IR
                digit3 <= IR(15 downto 12);
                digit2 <= IR(11 downto 8);
                digit1 <= IR(7 downto 4);
                digit0 <= IR(3 downto 0);
            elsif (btn = "0010") then		-- num
                digit3 <= X"0";
                digit2 <= X"0";
                digit1 <= X"0";
                digit0 <= num;
			elsif (btn = "0011") then		-- CPU_output
                digit3 <= CPU_output(15 downto 12);
                digit2 <= CPU_output(11 downto 8);
                digit1 <= CPU_output(7 downto 4);
                digit0 <= CPU_output(3 downto 0);
			elsif (btn = "0100") then		-- rb index
				digit3 <= "0000";
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= '0' & rb_idx;
			elsif (btn = "0101") then		-- rc index
				digit3 <= "0000";
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= '0' & rc_idx;
			elsif (btn = "0110") then		-- rb value
				digit3 <= rb_val(15 downto 12);
				digit2 <= rb_val(11 downto 8);
				digit1 <= rb_val(7 downto 4);
				digit0 <= rb_val(3 downto 0);
			elsif (btn = "0111") then		-- rc value
				digit3 <= rc_val(15 downto 12);
				digit2 <= rc_val(11 downto 8);
				digit1 <= rc_val(7 downto 4);
				digit0 <= rc_val(3 downto 0);
			elsif (btn = "1000") then		-- in1 of ALU
				digit3 <= in1(15 downto 12);
				digit2 <= in1(11 downto 8);
				digit1 <= in1(7 downto 4);
				digit0 <= in1(3 downto 0);
			elsif (btn = "1001") then		-- in2 of ALU
				digit3 <= in2(15 downto 12);
				digit2 <= in2(11 downto 8);
				digit1 <= in2(7 downto 4);
				digit0 <= in2(3 downto 0);
			elsif (btn = "1010") then		-- alu_mode, shift_count of ALU
				digit3 <= '0' & alu_mode;
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= shift_count; 	
			elsif (btn = "1011") then		-- out1 of ALU
				digit3 <= out1(15 downto 12);
                digit2 <= out1(11 downto 8);
                digit1 <= out1(7 downto 4);
                digit0 <= out1(3 downto 0);
			elsif (btn = "1100") then		-- brch_en, stall
				digit3 <= "000" & brch_en;
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= "000" & stall;
			elsif (btn = "1101") then		-- brch_addr
				digit3 <= brch_addr(15 downto 12);
				digit2 <= brch_addr(11 downto 8);
				digit1 <= brch_addr(7 downto 4);
				digit0 <= brch_addr(3 downto 0);
			elsif (btn = "1110") then		-- wr_en, ra_idx
				digit3 <= "000" & wr_en;
				digit2 <= "0000";
				digit1 <= "0000";
				digit0 <= '0' & ra_idx;
			elsif (btn = "1111") then		-- ra_val
				digit3 <= ra_val(15 downto 12);
				digit2 <= ra_val(11 downto 8);
				digit1 <= ra_val(7 downto 4);
				digit0 <= ra_val(3 downto 0);
			end if;
		end if;
	end process;

	process (clk) begin
        if(clk = '0' and clk'event) then
			brch_addr <= X"0000";
			brch_en <= '0';
			z <= z_flag;
			n <= n_flag;
			o <= o_flag;
			shift_count <= "0000";
			ra_val <= X"0000";
			ra_idx <= "000";
			rb_idx <= "000";
            rc_idx <= "000";
            in1 <= X"0000";
			in2 <= X"0000";
			hold_flag <= '0';
			stall <= '0';
			wr_en <= '0';
			ra_idx_execute <= "1000";
			rb_idx_execute <= "1000";
			rc_idx_execute <= "1000";
            stall_MUX <= '0';
			if (rst='1') then
				IR_writeback <= X"0000";
				IR_memoryaccess <= X"0000";
				IR_execute <= X"0000";
				n <= '0';
				z <= '0';
				o <= '0';
				CPU_output <= X"0000";
				alu_mode <= "000";
				ra_idx_memoryaccess <= "1000";
				rb_idx_memoryaccess <= "1000";
				rc_idx_memoryaccess <= "1000";
				ra_idx_writeback <= "1000";
				rb_idx_writeback <= "1000";
				rc_idx_writeback <= "1000";
			else
				-- code for WRITE BACK stage
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
						ra_val <= input_port & "000000";
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
						if (alu_dt = X"FFF0") then
							ra_val <= X"000" & num;
						else
							ra_val <= mem_dt;
						end if;
						ra_idx <= ra_idx_writeback(2 downto 0);
						wr_en <= '1';
					when "0010001" => -- STORE
						NULL;
					when "0010010" => --LOADIMM
						ra_idx <= "111";
						ra_val <= alu_dt;
						wr_en <= '1';
					when "0010011" => --MOV
						ra_idx <= ra_idx_writeback(2 downto 0);
						ra_val <= alu_dt;
						wr_en <= '1';
					when others => NULL;
				end case;
				
				-- code for MEMORY ACCESS stage
				IR_writeback <= IR_memoryaccess;
				ra_idx_writeback <= ra_idx_memoryaccess;
				rb_idx_writeback <= rb_idx_memoryaccess;
				rc_idx_writeback <= rc_idx_memoryaccess;
				alu_dt <= out1;
				wr_mem_en <= "0";
				
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
						output_port <= out1(0);
					when "0100001" => -- IN
						NULL;
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
						alu_dt <= out1;
					when "0010001" => -- STORE
						if (out1 = X"FFF2") then
							CPU_output <= out2;
						else
							addr_dt <= out1;	-- dest
							din_dt <= out2;		-- src
							wr_mem_en <= "1";
						end if;
						
					when "0010010" => --LOADIMM
						alu_dt <= out1;
					when "0010011" => --MOV
						alu_dt <= out1;
					when others => NULL;
				end case;
				
				-- code for EXECUTE stage
				IR_memoryaccess <= IR_execute;
				ra_idx_memoryaccess <= ra_idx_execute;
				rb_idx_memoryaccess <= rb_idx_execute;
				rc_idx_memoryaccess <= rc_idx_execute;
				brch_addr <= out1;
				case IR_execute(15 downto 9) is
					when "0000000" => --NOP
						alu_mode <= "000";
						hold_flag <= '1';
					when "0000001" => -- ADD
						alu_mode <= "001";
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in2 <= X"000" & num;
								else
									in2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in2 <= input_port & "000000";
							end if;
						else
							in2 <= rc_val;	
						end if;
					when "0000010" => -- SUB
						alu_mode <= "010";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in2 <= X"000" & num;
								else
									in2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in2 <= input_port & "000000";
							end if;
						else
							in2 <= rc_val;	
						end if;		
					when "0000011" => -- MUL
						alu_mode <= "011";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in2 <= X"000" & num;
								else
									in2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in2 <= input_port & "000000";
							end if;
						else
							in2 <= rc_val;	
						end if;			
					when "0000100" => -- NAND
						alu_mode <= "100";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;

						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								in2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							in2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in2 <= X"000" & num;
								else
									in2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in2 <= input_port & "000000";
							end if;
						else
							in2 <= rc_val;	
						end if;			
					when "0000101" => -- SHL
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "101";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;
					when "0000110" => -- SHR
						shift_count <= IR_execute(3 downto 0);
						alu_mode <= "110";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;			
					when "0000111" => -- TEST
						alu_mode <= "111";	
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;				
					when "0100000" => -- OUT
						alu_mode <= "111";	
						hold_flag <= '1';
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;			
					when "0100001" => -- IN
						alu_mode <= "111";	
						hold_flag <= '1';
					when "1000000" => -- BRR
					    alu_mode <= "001";
					    hold_flag <= '1';
					    in1 <= CPC_execute;
					    in2 <= ext_addr;
						stall_MUX <= '1';		
					when "1000001" => -- BRR.N
					    alu_mode <= "001";
					    in1 <= CPC_execute;
					    if (n_flag = '0') then
                            in2 <= X"0002";
					    else
					       in2 <= ext_addr;
						   stall_MUX <= '1';
					    end if;
					when "1000010" => -- BRR.Z
					    alu_mode <= "001";
					    in1 <= CPC_execute;
					    if (z_flag = '0') then
                            in2 <= X"0002";
					    else
					       in2 <= ext_addr;
						   stall_MUX <= '1';
					    end if;
					when "1000011" => -- BR
					    alu_mode <= "001";
					    hold_flag <= '1';
					    in1 <= rb_val;
					    in2 <= ext_addr;
						stall_MUX <= '1';					
					when "1000100" => -- BR.N
					    alu_mode <= "001";
					    if (n_flag = '0') then
					       in1 <= CPC_execute;
					       in2 <= X"0002";
					    else
							if (rb_idx_execute = ra_idx_memoryaccess) then
								if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
									stall <= '1';
									alu_mode <= "000";
									IR_memoryaccess <= X"0000";
									ra_idx_memoryaccess <= "1000";
									rb_idx_memoryaccess <= "1000";
									rc_idx_memoryaccess <= "1000";

									IR_execute <= IR_execute;
									ra_idx_execute <= ra_idx_execute;
									rb_idx_execute <= rb_idx_execute;
									rc_idx_execute <= rc_idx_execute;
								elsif (IR_memoryaccess(15 downto 9) = "0010010") then
									if (IR_memoryaccess(8) = '1') then
										in1 <=  IR_memoryaccess(7 downto 0) & alu_dt(7 downto 0);
									else
										in1 <= alu_dt(15 downto 8) & IR_memoryaccess(7 downto 0);
									end if;
								else
									in1 <= out1;
								end if;
							elsif (rb_idx_execute = ra_idx_writeback) then
								in1 <= alu_dt;
								if (IR_writeback(15 downto 9) = "0010000") then
									if (out1 = X"FFF0") then
										in1 <= X"000" & num;
									else
										in1 <= mem_dt;
									end if;
								elsif (IR_writeback(15 downto 9) = "0100001") then
									in1 <= input_port & "000000";
								end if;
							else
								in1 <= rb_val;	
							end if;
					       in2 <= ext_addr;
						   stall_MUX <= '1';
					    end if;
					when "1000101" => -- BR.Z
					    alu_mode <= "001";
					    if (z_flag = '0') then
					       in1 <= CPC_execute;
					       in2 <= X"0002";
					    else
							if (rb_idx_execute = ra_idx_memoryaccess) then
								if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
									stall <= '1';
									alu_mode <= "000";
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
								if (IR_writeback(15 downto 9) = "0010000") then
									if (out1 = X"FFF0") then
										in1 <= X"000" & num;
									else
										in1 <= mem_dt;
									end if;
								elsif (IR_writeback(15 downto 9) = "0100001") then
									in1 <= input_port & "000000";
								end if;
							else
								in1 <= rb_val;	
							end if;
					       in2 <= ext_addr;
						   stall_MUX <= '1';
					    end if;
					when "1000110" => -- BR.SUB
						stall_MUX <= '1';
					    alu_mode <= "001";
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;
					    in2 <= ext_addr;
					when "1000111" => -- RETURN
						stall_MUX <= '1';
                        hold_flag <= '1';
					    alu_mode <= "111";
					    if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;
					when "0010000" => -- LOAD
						alu_mode <= "111";
						hold_flag <= '1';
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;	
					when "0010001" => -- STORE
						alu_mode <= "111";
						hold_flag <= '1';
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;	
						
						if (rc_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rc_idx_execute <= rc_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								out2 <= out1;
							end if;
						elsif (rc_idx_execute = ra_idx_writeback) then
							out2 <= alu_dt;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									out2 <= X"000" & num;
								else
									out2 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								out2 <= input_port & "000000";
							end if;
						else
							out2 <= rc_val;	
						end if;	
					when "0010010" => --LOADIMM
						alu_mode <= "001";	
						hold_flag <= '1';
                        if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
								IR_memoryaccess <= X"0000";
								ra_idx_memoryaccess <= "1000";
								rb_idx_memoryaccess <= "1000";
								rc_idx_memoryaccess <= "1000";

								IR_execute <= IR_execute;
								ra_idx_execute <= ra_idx_execute;
								rb_idx_execute <= rb_idx_execute;
								rc_idx_execute <= rc_idx_execute;
							else
								if (IR_execute(8) = '1') then
									in1 <= X"00" & out1(7 downto 0);
									in2 <= IR_execute(7 downto 0) & X"00";
								else
									in1 <= out1(15 downto 8) & X"00";
									in2 <= X"00" & IR_execute(7 downto 0);
								end if;
							end if;
						elsif (rb_idx_execute = ra_idx_writeback) then
							if (IR_execute(8) = '1') then
								in1 <= X"00" & alu_dt(7 downto 0);
								in2 <= IR_execute(7 downto 0) & X"00";
							else
								in1 <= alu_dt(15 downto 8) & X"00";
								in2 <= X"00" & IR_execute(7 downto 0);
							end if;
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									if (IR_execute(8) = '1') then
										in1 <= X"000" & num;
										in2 <= IR_execute(7 downto 0) & X"00";
									else
										in1 <= X"0000";
										in2 <= X"00" & IR_execute(7 downto 0);
									end if;
								else
									if (IR_execute(8) = '1') then
										in1 <= X"00" & mem_dt(7 downto 0);
										in2 <= IR_execute(7 downto 0) & X"00";
									else
										in1 <= mem_dt(15 downto 8) & X"00";
										in2 <= X"00" & IR_execute(7 downto 0);
									end if;
								end if;
								
							elsif (IR_writeback(15 downto 9) = "0100001") then
								if (IR_execute(8) = '1') then
									in1 <= X"00" & input_port(1 downto 0) & "000000";
									in2 <= IR_execute(7 downto 0) & X"00";
								else
									in1 <= input_port(9 downto 2) & X"00";
									in2 <= X"00" & IR_execute(7 downto 0);
								end if;
							end if;
						else
							if (IR_execute(8) = '1') then
								in1 <= X"00" & rb_val(7 downto 0);
								in2 <= IR_execute(7 downto 0) & X"00";
							else
								in1 <= rb_val(15 downto 8) & X"00";
								in2 <= X"00" & IR_execute(7 downto 0);
							end if;
						end if;	
					when "0010011" => --MOV
						alu_mode <= "111";
						hold_flag <= '1';
						if (rb_idx_execute = ra_idx_memoryaccess) then
							if (IR_memoryaccess(15 downto 9) = "0100001" or IR_memoryaccess(15 downto 9) = "0010000") then
								stall <= '1';
								alu_mode <= "000";
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
							if (IR_writeback(15 downto 9) = "0010000") then
								if (out1 = X"FFF0") then
									in1 <= X"000" & num;
								else
									in1 <= mem_dt;
								end if;
							elsif (IR_writeback(15 downto 9) = "0100001") then
								in1 <= input_port & "000000";
							end if;
						else
							in1 <= rb_val;	
						end if;		
					when others => NULL;				
				end case;

				-- code for DECODE stage
                IR_execute <= IR;
                CPC_execute <= CPC;
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
                        rb_idx <= IR(8 downto 6);    -- dest
                        rb_idx_execute <= '0' & IR(8 downto 6);
                        rc_idx <= IR(5 downto 3);    -- src
                        rc_idx_execute <= '0' & IR(5 downto 3);
                    when "0010010" => --LOADIMM
                        rb_idx <= "111";
                        rb_idx_execute <= "0111";
                        ra_idx_execute <= "0111";
                    when "0010011" => --MOV
                        rb_idx <= IR(5 downto 3);
                        rb_idx_execute <= '0' & IR(5 downto 3);
                        ra_idx_execute <= '0' & IR(8 downto 6);
                    when others => NULL;
					if (stall_MUX = '1') then
					    stall_MUX <= '0';
					    hold_flag <= '1';
						brch_en <= '1';
						-- clear instruction in previous stages as we have branched
						IR_memoryaccess <= X"0000";
						ra_idx_memoryaccess <= "1000";
						rb_idx_memoryaccess <= "1000";
						rc_idx_memoryaccess <= "1000";
	
						IR_execute <= X"0000";
						ra_idx_execute <= "1000";
						rb_idx_execute <= "1000";
						rc_idx_execute <= "1000";
					end if;    
                end case;
			end if;
		end if;
    end process;
 end behavioural;
