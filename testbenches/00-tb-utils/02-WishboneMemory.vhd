-- Non synthetizable Wishbone compatible memory

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

use work.tb_utils.all;

entity tb_WishboneMemory is
    generic ( NBIT: integer := 32;
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
end tb_WishboneMemory;

architecture Behavioral of tb_WishboneMemory is
    type MemoryType is array (0 to 2**(ADDR_WIDTH-2)) of std_logic_vector(NBIT-1 downto 0);
    -- signal memory: MemoryType := (others => x"DEADBEEF");
    signal memory: MemoryType := (others => (others => 'Z'));
begin


    FakeMemory: process
        file mem_fp: text;
        variable file_line: line;
        variable index: integer := 0;
        variable tmp_data_u: std_logic_vector(NBIT-1 downto 0);
        variable wait_cycles: integer := 0;
        variable mem_address: integer := 0;
    begin
        o_wb_stall <= '0';
        o_wb_ack <= '0';
        o_wb_err <= '0';
        o_wb_data <= (others => '0');


        -- Load memory from mem file
        if i_wb_rst = '1' then
            report "Loading from """ & INSTRUCTIONS_FILENAME & """.";
            index := INSTRUCTIONS_START_ADDR;
            file_open(mem_fp, INSTRUCTIONS_FILENAME, READ_MODE);
            while (not endfile(mem_fp)) loop
                readline(mem_fp, file_line);
                hread(file_line, tmp_data_u);
                memory(index) <= tmp_data_u;
                index := index + 1;
            end loop;
            file_close(mem_fp);
            wait until rising_edge(i_wb_clk);
        end if;

        -- NOTE: This falling edge wait models a combinational answer to the stb signal
        wait until falling_edge(i_wb_clk);
        if i_wb_stb = '1' then
            assert i_wb_cyc = '1' report "wb_stb and wb_cyc must be asserted together";
            wait_cycles := random_int(MIN_STALL_CYCLES, MAX_STALL_CYCLES);
            for i in 0 to wait_cycles-1 loop
                o_wb_stall <= '1';
                wait until rising_edge(i_wb_clk);
            end loop;
            o_wb_stall <= '0';

            wait_cycles := random_int(MIN_WAIT_CYCLES, MAX_WAIT_CYCLES);
            if wait_cycles > 0 then
                for i in 0 to wait_cycles-1 loop
                    wait until rising_edge(i_wb_clk);
                    wait until falling_edge(i_wb_clk);
                    assert i_wb_cyc = '1' report "wb_cyc must stay high until the slave responds";

                    -- NOTE: The following is only true for masters that don't support pipelining
                    assert i_wb_stb = '0' report "wb_stb must stay low until the slave responds";
                end loop;
                wait until rising_edge(i_wb_clk);
            end if;
            mem_address := to_integer(unsigned(i_wb_addr(ADDR_WIDTH-1 downto 2)));

            if i_wb_we = '1' then
                if VERBOSE then
                    report "WRITE: mem(""" & to_hex_string(i_wb_addr) & """) <- """
                    & to_hex_string(i_wb_data) & """;";
                end if;
                memory(mem_address) <= i_wb_data;
                o_wb_ack <= '1';
                wait until rising_edge(i_wb_clk);
                o_wb_ack <= '0';
            else
                if VERBOSE then
                    report "READ: mem(""" & to_hex_string(i_wb_addr) & """) = """
                    & to_hex_string(memory(mem_address)) & """;";
                end if;
                o_wb_data <= memory(mem_address);
                o_wb_ack <= '1';
                wait until rising_edge(i_wb_clk);
                o_wb_ack <= '0';

            end if;
        end if;
    end process FakeMemory;

    MemoryDump: process (i_memory_dump)
        file mem_fp: text;
        variable row: line;
        variable addr_physical: std_logic_vector(ADDR_WIDTH-1 downto 0);
    begin
        if rising_edge(i_memory_dump) then
            file_open(mem_fp, DUMP_FILENAME, WRITE_MODE);

            for addr in 0 to 2**(ADDR_WIDTH-2)-1 loop
                addr_physical := std_logic_vector(to_unsigned(addr * 4, ADDR_WIDTH));
                hwrite(row, addr_physical);
                write(row, string'(": "));
                hwrite(row, memory(addr));
                writeline(mem_fp, row);
            end loop;

            file_close(mem_fp);
        end if;
    end process MemoryDump;


end Behavioral;
