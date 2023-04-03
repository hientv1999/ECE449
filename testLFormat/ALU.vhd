library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU_file is
    port(
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
end ALU_file; --nothing

architecture behavioural of ALU_file is

--ALU operations 
signal output   : std_logic_vector(31 downto 0);
signal z        : std_logic;
signal n        : std_logic;
signal o        : std_logic;

begin
    process(in1, in2, alu_mode, shift_count, output) begin
        -- calculate result
        case alu_mode(2 downto 0) is
            when "001" => --ADD
                output <= X"0000" & std_logic_vector(signed(in1) + signed(in2));
            when "010" => --SUB
                output <= X"0000" & std_logic_vector(signed(in1) - signed(in2));
            when "011" => --MUL
                output <= std_logic_vector(signed(in1) * signed(in2));
            when "100" => --NAND
                output <=  X"0000" & (in1 NAND in2);
            when "101" => --SHL (2's complement)             
                if (shift_count(3 downto 0) = "0001") then  
                    output <= X"0000" & in1(15) & in1(13 downto 0) & '0';
                    
                elsif (shift_count(3 downto 0) = "0010") then
                    output <= X"0000" & in1(15) & in1(12 downto 0) & "00";
                    
                elsif (shift_count(3 downto 0) = "0011") then
                    output <= X"0000" & in1(15) & in1(11 downto 0) & "000";
                        
                elsif (shift_count(3 downto 0) = "0100") then 
                    output <= X"0000" & in1(15) & in1(10 downto 0) & "0000";

                elsif (shift_count(3 downto 0) = "0101") then 
                    output <= X"0000" & in1(15) & in1(9 downto 0) & "00000";

                elsif (shift_count(3 downto 0) = "0110") then 
                    output <= X"0000" & in1(15) & in1(8 downto 0) & "000000";

                elsif (shift_count(3 downto 0) = "0111") then 
                    output <= X"0000" & in1(15) & in1(7 downto 0) & "0000000";

                elsif (shift_count(3 downto 0) = "1000") then 
                    output <= X"0000" & in1(15) & in1(6 downto 0) & "00000000";

                elsif (shift_count(3 downto 0) = "1001") then 
                    output <= X"0000" & in1(15) & in1(5 downto 0) & "000000000";

                elsif (shift_count(3 downto 0) = "1010") then 
                    output <= X"0000" & in1(15) & in1(4 downto 0) & "0000000000";

                elsif (shift_count(3 downto 0) = "1011") then 
                    output <= X"0000" & in1(15) & in1(3 downto 0) & "00000000000";

                elsif (shift_count(3 downto 0) = "1100") then 
                    output <= X"0000" & in1(15) & in1(2 downto 0) & "000000000000";

                elsif (shift_count(3 downto 0) = "1101") then 
                    output <= X"0000" & in1(15) & in1(1 downto 0) & "0000000000000";

                elsif (shift_count(3 downto 0) = "1110") then 
                    output <= X"0000" & in1(15) & in1(0) & "00000000000000";

                elsif (shift_count(3 downto 0) = "1111") then 
                    output <= X"00000000";
                end if;
            when "110" => --SHR (2's complement)
                if (shift_count(3 downto 0) = "0001") then
                    output <= X"0000" & in1(15) & in1(15) & in1(14 downto 1);                   
            
                elsif (shift_count(3 downto 0) = "0010") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(14 downto 2);
                
                elsif (shift_count(3 downto 0) = "0011") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 3);
                    
                elsif (shift_count(3 downto 0) = "0100") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 4);
                
                elsif (shift_count(3 downto 0) = "0101") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 5);

                elsif (shift_count(3 downto 0) = "0110") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 6);
            
                elsif (shift_count(3 downto 0) = "0111") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 7);
        
                elsif (shift_count(3 downto 0) = "1000") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 8);
        
                elsif (shift_count(3 downto 0) = "1001") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 9);
        
                elsif (shift_count(3 downto 0) = "1010") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 10);
                    
                elsif (shift_count(3 downto 0) = "1011") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 11);

                elsif (shift_count(3 downto 0) = "1100") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 12);

                elsif (shift_count(3 downto 0) = "1101") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14 downto 13);

                elsif (shift_count(3 downto 0) = "1110") then
                    output <= X"0000" & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(15) & in1(14);

                elsif (shift_count(3 downto 0) = "1111") then
                    output <= X"00000000";

                end if;                        
            when "111" => --TEST
                output <= X"0000" & in1;
            when others => --NOP
                output <= output;
        end case;
    end process;

    process(clk) begin
        if (clk ='1' and clk'event) then
            if(rst='1') then
                output <= X"00000000";
                z <= '0';
                n <= '0';
                o <= '0';
            else
                --recalculate zero flag
                if output(15 downto 0) = X"0000" then
                    z <= '1'; 
                else
                    z <= '0';
                end if;
                --get negative flag
                n <= output(15); 
                -- get overflow flag
                case alu_mode(2 downto 0) is
                    when "000" => --NOP
                        o <= o;
                    when "001" => --ADD
                        if (in1(15) = in2(15) AND output(15) /= in1(15)) then
                            o <= '1';
                        else 
                            o <= '0';
                        end if;
                    when "010" => --SUB
                        if (in1(15) /= in2(15) AND output(15) = in2(15)) then
                            o <= '1';
                        else 
                            o <= '0';
                        end if;
                    when "011" => --MUL
                        if (signed(output) > X"00007FFF" OR signed(output) < X"FFFF1000") then
                            o <= '1';
                        else 
                            o <= '0';
                        end if;
                    when "101" => --SHL (2's complement)
                        if (output(31) /= output(30) or output(31) /=  output(29) or
                        output(31) /= output(28) or output(31) /=  output(27) or
                        output(31) /= output(26) or output(31) /=  output(25) or
                        output(31) /= output(24) or output(31) /=  output(23) or
                        output(31) /= output(22) or output(31) /=  output(21) or
                        output(31) /= output(20) or output(31) /=  output(19) or
                        output(31) /= output(18) or output(31) /=  output(17) or
                        output(31) /= output(16) or output(31) /=  output(15)) then
                            o <= '1';
                        else
                            o <= '0';
                        end if;
                    when others => 
                            o <= '0';
                end case;
            end if;
        end if;
    end process;
    
    --port signal to outputs
    result <= output(15 downto 0);
    z_flag <= z ;
    n_flag <= n;
    o_flag <= o;
end behavioural;
