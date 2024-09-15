library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.tb_utils.all;
use work.instructions.all;

entity TB_DLX is
    generic (
        MAX_CYCLES: integer := 100;

        -- The file where to dump the memory contents
        DUMP: string := "./programs/memory_unit_test/dump.mem";

        -- The file where the Read Only Instruction Memory is stored
        PROGRAM: string  := "./programs/memory_unit_test/instruction_rom.mem";

        RESET_ADDR: std_logic_vector(31 downto 0) := (others => '0');

        MIN_STALL_CYCLES: integer := 1;
        MAX_STALL_CYCLES: integer := 3;
        MIN_WAIT_CYCLES: integer := 1;
        MAX_WAIT_CYCLES: integer := 2;

        INSTRUCTION_CACHE_NSETS: integer := 2;
        INSTRUCTION_CACHE_WAYS: integer := 4;
        INSTRUCTION_CACHE_LINE_SIZE: integer := 16;

        DATA_CACHE_NSETS: integer := 2;
        DATA_CACHE_WAYS: integer := 4;
        DATA_CACHE_LINE_SIZE: integer := 16
    );
end TB_DLX;

architecture tb of TB_DLX is
    component DLX is
        generic (
            NBIT: integer := 32;
            ADDR_WIDTH: integer := 32;
            RESET_ADDR: std_logic_vector(31 downto 0) := (others => '0');

            BTB_LINES_WIDTH: integer := 4;

            INSTRUCTION_CACHE_NSETS: integer := 2;
            INSTRUCTION_CACHE_WAYS: integer := 4;
            INSTRUCTION_CACHE_LINE_SIZE: integer := 16;

            DATA_CACHE_NSETS: integer := 2;
            DATA_CACHE_WAYS: integer := 4;
            DATA_CACHE_LINE_SIZE: integer := 16
        );
        port (
            i_debug_dump: in std_logic;

            i_wb_clk:  in std_logic;
            i_wb_rst:  in std_logic;

            i_wb_stall: in std_logic; 
            i_wb_ack:   in std_logic;
            i_wb_err:   in std_logic;
            i_wb_data:  in std_logic_vector(NBIT-1 downto 0);

            o_wb_cyc:  out std_logic;
            o_wb_stb:  out std_logic;
            o_wb_we:   out std_logic;

            o_wb_addr: out std_logic_vector(ADDR_WIDTH-1 downto 0);
            o_wb_data: out std_logic_vector(NBIT-1 downto 0)
        );
    end component DLX;

    component tb_WishboneMemory is
        generic (
            NBIT: integer := 32;
            ADDR_WIDTH: integer := 10;
            VERBOSE: boolean := false;
            DUMP_FILENAME: string := "dump.mem";
            INSTRUCTIONS_FILENAME: string := "program.mem";
            INSTRUCTIONS_START_ADDR: integer := 256;
            MIN_STALL_CYCLES: integer := 1;
            MAX_STALL_CYCLES: integer := 3;
            MIN_WAIT_CYCLES: integer := 1;
            MAX_WAIT_CYCLES: integer := 2
        );
        port (
            i_wb_clk: in std_logic;
            i_wb_rst: in std_logic;

            o_wb_stall: out std_logic;
            o_wb_ack:   out std_logic;
            o_wb_err:   out std_logic;
            o_wb_data:  out std_logic_vector(NBIT-1 downto 0);

            i_wb_cyc:   in std_logic;
            i_wb_stb:   in std_logic;
            i_wb_we:    in std_logic;
            i_wb_addr:  in std_logic_vector(ADDR_WIDTH-1 downto 0);
            i_wb_data:  in std_logic_vector(NBIT-1 downto 0);

            i_memory_dump: in std_logic
        );
    end component tb_WishboneMemory;


    signal sim_stopped: std_logic := '0'; 

    constant ClockPeriod: time := 1 ns;

    constant MEMORY_ADDR_SIZE: integer := 16;

    signal debug_dump_memory: std_logic;

    -- Wishbone Bus 
    signal wb_stall, wb_ack, wb_err, wb_cyc, wb_stb, wb_we: std_logic;
    signal wb_data_slave_to_master, wb_data_master_to_slave: std_logic_vector(31 downto 0);
    signal wb_addr: std_logic_vector(31 downto 0);
    signal wb_memory_addr: std_logic_vector(MEMORY_ADDR_SIZE-1 downto 0);

    signal wb_clk: std_logic := '0';
    signal wb_rst: std_logic;
begin

    wb_memory_addr <= wb_addr(MEMORY_ADDR_SIZE-1 downto 0);

    DUT: DLX
        generic map(
            NBIT => 32,
            ADDR_WIDTH => 32,
            RESET_ADDR => (others => '0'),

            BTB_LINES_WIDTH => 4,

            INSTRUCTION_CACHE_NSETS => INSTRUCTION_CACHE_NSETS,
            INSTRUCTION_CACHE_WAYS => INSTRUCTION_CACHE_WAYS,
            INSTRUCTION_CACHE_LINE_SIZE => INSTRUCTION_CACHE_LINE_SIZE,

            DATA_CACHE_NSETS => DATA_CACHE_NSETS,
            DATA_CACHE_WAYS => DATA_CACHE_WAYS,
            DATA_CACHE_LINE_SIZE => DATA_CACHE_LINE_SIZE
        )
        port map (
            i_debug_dump => debug_dump_memory,

            i_wb_clk => wb_clk,
            i_wb_rst => wb_rst,

            i_wb_stall => wb_stall,
            i_wb_ack => wb_ack,
            i_wb_err => wb_err,
            i_wb_data => wb_data_slave_to_master,

            o_wb_cyc => wb_cyc,
            o_wb_stb => wb_stb,
            o_wb_we => wb_we,

            o_wb_addr => wb_addr,
            o_wb_data => wb_data_master_to_slave
        );

    DUT_Memory: tb_WishboneMemory
        generic map (
            NBIT => 32,
            ADDR_WIDTH => MEMORY_ADDR_SIZE,
            VERBOSE => false,
            DUMP_FILENAME => DUMP,
            INSTRUCTIONS_FILENAME => PROGRAM,
            INSTRUCTIONS_START_ADDR => 0,
            MIN_STALL_CYCLES => MIN_STALL_CYCLES,
            MAX_STALL_CYCLES => MAX_STALL_CYCLES,
            MIN_WAIT_CYCLES => MIN_WAIT_CYCLES,
            MAX_WAIT_CYCLES => MAX_WAIT_CYCLES 
        )
        port map (
            i_wb_clk => wb_clk,
            i_wb_rst => wb_rst,

            o_wb_stall => wb_stall,
            o_wb_ack => wb_ack,
            o_wb_err => wb_err,
            o_wb_data => wb_data_slave_to_master,

            i_wb_cyc => wb_cyc,
            i_wb_stb => wb_stb,
            i_wb_we => wb_we,
            i_wb_addr => wb_memory_addr,
            i_wb_data => wb_data_master_to_slave,

            i_memory_dump => debug_dump_memory
        );

    TestProcess: process
        variable cycles: integer := 0;
    begin
        debug_dump_memory <= '0';
        -- Initialcze all signals here
        wb_rst <= '1';
        wait for ClockPeriod;
        wb_rst <= '0';

        for i in 0 to MAX_CYCLES loop
            wait until rising_edge(wb_clk);

            cycles := cycles + 1;

            if wb_addr(31 downto 16) = x"FFFF" and wb_stb = '1' then
                report "Halting the CPU...";
                exit;
            end if;


            if i = MAX_CYCLES then
                report "Cycle Limit reached, stopping early...";
            end if;
        end loop;

        wait until rising_edge(wb_clk);
        debug_dump_memory <= '1';

        wait until rising_edge(wb_clk);
        debug_dump_memory <= '0';

        report "Cycles taken: " & integer'image(cycles);

        -- Stop the simulation and return
        sim_stopped <= '1';
        report "Simulation Finished!";
        wait;
    end process TestProcess;

    ClockGen: process
    begin
        if sim_stopped = '0' then 
            wb_clk <= not wb_clk;
            wait for ClockPeriod/2;
        else
            wait;
        end if;
    end process ClockGen;

end tb;

