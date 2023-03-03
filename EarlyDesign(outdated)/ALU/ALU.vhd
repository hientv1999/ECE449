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
end ALU_file;

architecture behavioural of ALU_file is

--ALU operations 
signal output   : std_logic_vector(31 downto 0);
signal z        : std_logic;
signal n        : std_logic;
signal o        : std_logic;

begin
    process(clk, alu_mode, in1, in2, shift_count, rst) begin
       if(clk='0' and clk'event) then 
            if(rst='1') then
                output <= X"00000000";
                z <= '0';
                n <= '0';
                o <= '0';
            else
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
                            
                        end if;                        
                    when "111" => --TEST
                       output <= X"0000" & in1;
                    when others => --NOP
                        output <= output;
                end case;
            end if; 
        end if;
        
        if (clk ='1' and clk'event) then
            --gecalculate zero flag
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
                    if (in1(15) /= in1(15-to_integer(unsigned(shift_count)))) then
                        o <= '1';
                    else
                        o <= '0';
                    end if;
                when others => 
                        o <= '0';
            end case;
        end if;
    end process;
    
    --port signal to outputs
    result <= output(15 downto 0);
    z_flag <= z ;
    n_flag <= n;
    o_flag <= o;
end behavioural;