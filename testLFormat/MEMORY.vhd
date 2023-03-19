library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
Library xpm;
use xpm.vcomponents.all;

entity MEMORY_file is
    port(
        --input signals       
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
end MEMORY_file;


architecture behavioural of PC_file is

--MEMORY signal 
-- signal dout_dt, dout_ins, addr_dt, addr_ins, din_dt : std_logic_vector(15 downto 0);
-- signal ena, enb, wea: std_logic;

begin
    -- xpm_memory_dpdistram: Dual Port Distributed RAM
    -- Xilinx Parameterized Macro, version 2018.3
    xpm_memory_dpdistram_inst : xpm_memory_dpdistram
    generic map (
        ADDR_WIDTH_A => 16 , -- 16-bit addressing
        ADDR_WIDTH_B => 16 , -- 16-bit addressing
        BYTE_WRITE_WIDTH_A => 16, -- 16-bit data
        CLOCKING_MODE => "common_clock", -- DEFAULT VALUE
        MEMORY_INIT_FILE => "none", -- DEFAULT VALUE
        MEMORY_INIT_PARAM => "0", -- DEFAULT VALUE
        MEMORY_OPTIMIZATION => "true", -- DEFAULT VALUE
        MEMORY_SIZE => 8192, -- 1024 bytes block
        MESSAGE_CONTROL => 0, -- DEFAULT VALUE
        READ_DATA_WIDTH_A => 16, -- 16-bit data
        READ_DATA_WIDTH_B => 16, -- 16-bit data
        READ_LATENCY_A => 2, -- DEFAULT VALUE
        READ_LATENCY_B => 2, -- DEFAULT VALUE
        READ_RESET_VALUE_A => "0", -- DEFAULT VALUE
        READ_RESET_VALUE_B => "0", -- DEFAULT VALUE
        RST_MODE_A => "SYNC", -- DEFAULT VALUE
        RST_MODE_B => "SYNC", -- DEFAULT VALUE
        USE_EMBEDDED_CONSTRAINT => 0, -- DEFAULT VALUE
        USE_MEM_INIT => 1, -- DEFAULT VALUE
        WRITE_DATA_WIDTH_A => 16 -- 16-bit data
    )

    port map (
        douta => dout_dt, -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
        doutb => dout_ins, -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
        addra => addr_dt, -- ADDR_WIDTH_A-bit input: Address for port A write and read operations.
        addrb => addr_ins, -- ADDR_WIDTH_B-bit input: Address for port B write and read operations.
        clka => clk, -- 1-bit input: Clock signal for port A. Also clocks port B when parameter
        -- CLOCKING_MODE is "common_clock".
        --  clkb => clkb, -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
        -- "independent_clock". Unused when parameter CLOCKING_MODE is "common_clock".
        dina => din_dt, -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
        ena => en_dt, -- 1-bit input: Memory enable signal for port A. Must be high on clock cycles when read
        -- or write operations are initiated. Pipelined internally.
        enb => en_ins, -- 1-bit input: Memory enable signal for port B. Must be high on clock cycles when read
        -- or write operations are initiated. Pipelined internally.
        regcea => regcea, -- 1-bit input: Clock Enable for the last register stage on the output data path.
        regceb => regceb, -- 1-bit input: Do not change from the provided value.
        rsta => rst, -- 1-bit input: Reset signal for the final port A output register stage. Synchronously
        -- resets output port douta to the value specified by parameter READ_RESET_VALUE_A.
        rstb => rst, -- 1-bit input: Reset signal for the final port B output register stage. Synchronously
        -- resets output port doutb to the value specified by parameter READ_RESET_VALUE_B.
        wea => wea -- WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input data port dina. 1
        -- bit wide when word-wide writes are used. In byte-wide write configurations, each bit
        -- controls the writing one byte of dina to address addra. For example, to
        -- synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea
        -- would be 4'b0010.
    );
    -- End of xpm_memory_dpdistram_inst instantiation

end behavioural;