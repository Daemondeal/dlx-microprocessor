library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_utils.all;


entity tb_MemorySystem is
    generic (
        -- The file where to dump the memory contents
        DUMP: string := "./testvectors/memory_system_dump.mem";

        -- The file where the Read Only Instruction Memory is stored
        PROGRAM: string  := "./testvectors/memory_system.mem"
    );
end tb_MemorySystem;

architecture tb of tb_MemorySystem is
    component MemorySystem is
        generic (
            NBIT: integer       := 32;
            ADDR_WIDTH: integer := 32;

            INSTRUCTION_CACHE_NSETS: integer := 2;
            INSTRUCTION_CACHE_WAYS: integer := 4;
            INSTRUCTION_CACHE_LINE_SIZE: integer := 16;

            DATA_CACHE_NSETS: integer := 2;
            DATA_CACHE_WAYS: integer := 4;
            DATA_CACHE_LINE_SIZE: integer := 16
        );

        port (
            -- Interface with the environment
            i_wb_clk: in std_logic;
            i_wb_rst: in std_logic;

            i_wb_stall: in std_logic;
            i_wb_ack:   in std_logic;
            i_wb_err:   in std_logic;
            i_wb_data:  in std_logic_vector(NBIT-1 downto 0);

            o_wb_cyc:  out std_logic;
            o_wb_stb:  out std_logic;
            o_wb_we:   out std_logic;

            o_wb_addr: out std_logic_vector(ADDR_WIDTH-1 downto 0);
            o_wb_data: out std_logic_vector(NBIT-1 downto 0);

            -- Interface with the datapath

            -- ic: Instruction Cache
            i_ic_addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);

            i_ic_rd_request: in  std_logic;
            o_ic_rd_data:    out std_logic_vector(NBIT-1 downto 0);

            o_ic_hit: out std_logic;

            -- dc: Data Cache
            i_dc_addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);

            i_dc_rd_request: in  std_logic;
            o_dc_rd_data:    out std_logic_vector(NBIT-1 downto 0);

            i_dc_wr_request:  in std_logic;
            i_dc_wr_data:     in std_logic_vector(NBIT-1 downto 0);
            i_dc_wr_data_sel: in std_logic_vector((NBIT/8)-1 downto 0);

            o_dc_hit: out std_logic
        );
    end component MemorySystem;


    component tb_WishboneMemory is
        generic (
            NBIT: integer := 32;
            ADDR_WIDTH: integer := 10;
            VERBOSE: boolean := false;
            DUMP_FILENAME: string := "dump.mem";
            INSTRUCTIONS_FILENAME: string := "program.mem";
            INSTRUCTIONS_START_ADDR: integer := 256
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


    signal clk, rst_n: std_logic := '0';
    signal sim_stopped: std_logic := '0';
    constant ClockPeriod: time := 1 ns;
    constant IC_CYCLES: integer := 6000;
    constant DC_CYCLES: integer := 2000;

    -- dc: Data Cache
    signal s_dc_addr: std_logic_vector(31 downto 0);

    signal s_dc_rd_request: std_logic;
    signal s_dc_rd_data: std_logic_vector(31 downto 0);

    signal s_dc_wr_request: std_logic;
    signal s_dc_wr_data: std_logic_vector(31 downto 0);
    signal s_dc_wr_data_sel: std_logic_vector(3 downto 0);

    signal s_dc_hit: std_logic;


    -- ic: Instruction Cache
    signal s_ic_addr: std_logic_vector(31 downto 0);

    signal s_ic_rd_request: std_logic;
    signal s_ic_rd_data: std_logic_vector(31 downto 0);

    signal s_ic_hit: std_logic;

    -- Wishbone Bus
    signal wb_stall, wb_ack, wb_err, wb_cyc, wb_stb, wb_we: std_logic;
    signal wb_data_slave_to_master, wb_data_master_to_slave: std_logic_vector(31 downto 0);
    signal wb_addr: std_logic_vector(31 downto 0);
    signal wb_memory_addr: std_logic_vector(10 downto 0);

    signal wb_clk, wb_rst: std_logic;

    signal s_memory_dump: std_logic := '0';
    signal data_finished, instruction_finished: std_logic := '0';

    type MemType is array (0 to 255) of std_logic_vector(31 downto 0);
    signal mirror_memory: MemType := (others => (others => 'Z'));
begin

    wb_memory_addr <= wb_addr(10 downto 0);
    wb_rst <= not rst_n;
    wb_clk <= clk;

    DUT_Memory: tb_WishboneMemory
        generic map (
            NBIT => 32,
            ADDR_WIDTH => 11,
            VERBOSE => false,
            DUMP_FILENAME => DUMP,
            INSTRUCTIONS_FILENAME => PROGRAM,
            INSTRUCTIONS_START_ADDR => 256
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

            i_memory_dump => s_memory_dump
        );

    DUT_MemorySystem: MemorySystem
        generic map (
            NBIT => 32,
            ADDR_WIDTH => 32
        )
        port map (
            i_wb_clk => wb_clk,
            i_wb_rst => wb_rst,

            i_wb_stall => wb_stall,
            i_wb_ack   => wb_ack,
            i_wb_err   => wb_err,
            i_wb_data  => wb_data_slave_to_master,

            o_wb_cyc => wb_cyc,
            o_wb_stb => wb_stb,
            o_wb_we  => wb_we,

            o_wb_addr => wb_addr,
            o_wb_data => wb_data_master_to_slave,

            i_ic_addr => s_ic_addr,

            i_ic_rd_request => s_ic_rd_request,
            o_ic_rd_data    => s_ic_rd_data,

            o_ic_hit   => s_ic_hit,

            -- dc: Data Cache
            i_dc_addr => s_dc_addr,

            i_dc_rd_request => s_dc_rd_request,
            o_dc_rd_data => s_dc_rd_data,

            i_dc_wr_request => s_dc_wr_request,
            i_dc_wr_data => s_dc_wr_data,
            i_dc_wr_data_sel => s_dc_wr_data_sel,

            o_dc_hit   => s_dc_hit
        );

    process
    begin
        if sim_stopped = '0' then
            clk <= not clk;
            wait for ClockPeriod/2;
        else
            wait;
        end if;
    end process;

    ICache_Test: process
        variable address: integer;
        variable cycles: integer;
    begin
        s_ic_addr <= (others => '0');
        s_ic_rd_request <= '0';

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        s_ic_rd_request <= '1';
        s_ic_addr <= x"00_00_04_00";

        while s_ic_hit = '0' loop
            wait until falling_edge(clk);
        end loop;

        wait until rising_edge(clk);


        s_ic_rd_request <= '0';

        for i in 0 to IC_CYCLES loop
            cycles := random_int(0, 5);

            if cycles /= 0 then
                for j in 1 to cycles loop
                    wait until rising_edge(clk);
                end loop;
            end if;

            address := random_int(0, 268/4) * 4;
            s_ic_rd_request <= '1';
            s_ic_addr <= std_logic_vector(to_unsigned(address + 1024, 32));

            wait until falling_edge(clk);
            while s_ic_hit = '0' loop
                wait until falling_edge(clk);
            end loop;

            s_ic_rd_request <= '0';
            assert to_integer(unsigned(s_ic_rd_data)) = address
            report "Invalid read from ICache (Got """ & integer'image(to_integer(unsigned(s_ic_rd_data)))
            & """ but expected """ & integer'image(address) & """)";

            wait until rising_edge(clk);
        end loop;

        wait until rising_edge(clk);
        instruction_finished <= '1';
        wait;
    end process ICache_Test;

    DCache_Test: process
        variable address: integer;
        variable cycles: integer;
    begin

        s_dc_addr <= (others => '0');

        s_dc_rd_request <= '0';

        s_dc_wr_request <= '0';
        s_dc_wr_data <= (others => '0');
        s_dc_wr_data_sel <= "1111";

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        s_dc_wr_request <= '1';
        s_dc_wr_data <= x"CAFEBABE";

        while s_dc_hit = '0' loop
            wait until rising_edge(clk);
        end loop;

        mirror_memory(0) <= x"CAFEBABE";
        s_dc_wr_request <= '0';

        for i in 0 to DC_CYCLES loop
            cycles := random_int(0, 5);
            if cycles /= 0 then
                for j in 1 to cycles loop
                    wait until rising_edge(clk);
                end loop;
            end if;

            address := random_int(0, 255) * 4;

            if random_bool then
                -- Read
                s_dc_rd_request <= '1';
                s_dc_addr <= std_logic_vector(to_unsigned(address, 32));

                wait until falling_edge(clk);
                while s_dc_hit = '0' loop
                    wait until falling_edge(clk);
                end loop;

                assert s_dc_rd_data = mirror_memory(address/4)
                report "Invalid read from DCache (Got " & to_hex_string(s_dc_rd_data) &
                " but expected " & to_hex_string(mirror_memory(address/4)) & "). Address: " & integer'image(address/4);

                wait until rising_edge(clk);
                s_dc_rd_request <= '0';
            else
                -- Write
                s_dc_wr_request <= '1';
                s_dc_wr_data <= random_stdvec(32);
                s_dc_wr_data_sel <= random_stdvec(4);
                s_dc_addr <= std_logic_vector(to_unsigned(address, 32));

                wait until falling_edge(clk);
                while s_dc_hit = '0' loop
                    wait until falling_edge(clk);
                end loop;

                for i in 0 to 3 loop
                    if s_dc_wr_data_sel(i) = '1' then
                        mirror_memory(address/4)((i+1)*8-1 downto i*8) <= s_dc_wr_data((i+1)*8-1 downto i*8);
                    end if;
                end loop;
                -- report "writing " & to_hex_string(s_dc_wr_data) & " to "  & integer'image(address/4);
                wait until rising_edge(clk);
                s_dc_wr_request <= '0';
            end if;

            wait until rising_edge(clk);
        end loop;

        -- NOTE: The data cache may take a few cycles to fully write out
        --       the last word
        for i in 0 to 10 loop
            wait until rising_edge(clk);
        end loop;
        data_finished <= '1';
        wait;
    end process DCache_Test;

    process
    begin
        rst_n <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst_n <= '1';

        while (instruction_finished = '0' or data_finished = '0') loop
            wait until rising_edge(clk);
        end loop;

        wait until rising_edge(clk);
        s_memory_dump <= '1';
        wait until rising_edge(clk);
        s_memory_dump <= '0';

        report "Simulation Finished";
        sim_stopped <= '1';

        wait;
    end process;


end tb;
