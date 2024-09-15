library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.utils.all;

entity TB_ReadOnlyCache is
end TB_ReadOnlyCache;

architecture tb of TB_ReadOnlyCache is
    component ReadOnlyCache is
        generic (
            NBIT:       integer := 32;
            ADDR_WIDTH: integer := 32;

            NSETS:     integer := 2;
            WAYS:      integer := 4; -- Cache line in each seat
            LINE_SIZE: integer := 16 -- Size of each cache line
        -- This cache will be (2**SET_NBIT * WAYS * LINE_SIZE * NBIT) bits.
        );

        port (
            clk, rst_n: in std_logic;

            -- Read Request Signals
            i_request_addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);
            i_rd_request:   in std_logic;

            o_data_out: out std_logic_vector(NBIT-1 downto 0);
            o_hit:      out std_logic;

            -- Signals for loading the cache from memory
            o_addr_to_mem:    out std_logic_vector(ADDR_WIDTH-1 downto 0);
            o_mem_rd_request: out std_logic;
            i_data_from_mem:  in  std_logic_vector(NBIT-1 downto 0);
            i_data_from_mem_valid: in std_logic
        );
    end component ReadOnlyCache;

    signal clk: std_logic := '0';
    signal rst_n: std_logic := '1';

    signal sim_stopped: std_logic := '0'; 

    constant ClockPeriod: time := 1 ns;

    constant LINE_SIZE: integer := 4;
    constant WAYS: integer := 6;
    constant NSETS: integer := 2;


    signal i_rd_request: std_logic;
    signal i_rd_request_addr: std_logic_vector(31 downto 0);

    signal o_data_out: std_logic_vector(31 downto 0);
    signal o_hit: std_logic;

    signal o_addr_to_mem:   std_logic_vector(31 downto 0);
    signal o_mem_rd_request: std_logic;

    signal i_data_from_mem: std_logic_vector(31 downto 0);
    signal i_data_from_mem_valid: std_logic;

begin
    DUT: ReadOnlyCache
        generic map (
            NBIT => 32,
            ADDR_WIDTH => 32,
            LINE_SIZE => LINE_SIZE,
            WAYS => WAYS,
            NSETS => NSETS
        )
        port map (
            clk => clk, 
            rst_n => rst_n,

            i_rd_request      => i_rd_request,
            i_request_addr => i_rd_request_addr,

            o_data_out => o_data_out,
            o_hit      => o_hit,

            o_addr_to_mem         => o_addr_to_mem,
            o_mem_rd_request      => o_mem_rd_request,
            i_data_from_mem       => i_data_from_mem,
            i_data_from_mem_valid => i_data_from_mem_valid
        );

    FakeMemoryProc: process
        variable clock_waits_float: real;
        variable clock_waits: integer;

        variable seed1, seed2: integer := 1;
    begin
        i_data_from_mem <= (others => '0');
        i_data_from_mem_valid <= '0';

        wait until rising_edge(clk);
        if o_mem_rd_request = '1' then
            -- Wait a random amount of clocks, from 1 to 5
            uniform(seed1, seed2, clock_waits_float);
            clock_waits := integer(floor(clock_waits_float * 4.0)) + 1;

            for i in 0 to clock_waits-1 loop
                wait until rising_edge(clk);
            end loop;

            i_data_from_mem_valid <= '1';
            i_data_from_mem <= o_addr_to_mem;
            wait until rising_edge(clk);

            i_data_from_mem <= (others => '0');
            i_data_from_mem_valid <= '0';
        end if;
    end process FakeMemoryProc;

    TestProcess: process
        procedure ReadFromCache(
            address: in std_logic_vector(31 downto 0);
            expected_result: in std_logic_vector(31 downto 0);
            should_miss: in boolean := false;
            should_hit:  in boolean := false) is
        begin
            wait until rising_edge(clk);
            i_rd_request <= '1';
            i_rd_request_addr <= address;

            wait until rising_edge(clk);
            wait until falling_edge(clk);

            if should_miss then
                assert o_hit = '0' report "Cache hit even though it should have missed";
            end if;

            if should_hit then
                assert o_hit = '1' report "Cache missed even though it should have hit";
            end if;

            for i in 0 to 1000 loop
                if o_hit = '1' then
                    exit;
                end if;
                wait until falling_edge(clk);
                if i = 1000 then
                    assert false report "Cache hasn't filled after 1000 cycles, exiting...";
                    sim_stopped <= '1';
                    wait;
                end if;
            end loop;

            assert o_data_out = expected_result
                report "Invalid result. Got """ & integer'image(to_integer(unsigned(o_data_out)))
                     & """ but expected """ & integer'image(to_integer(unsigned(expected_result))) & """.";

            wait until rising_edge(clk);
            i_rd_request <= '0';
        end ReadFromCache;

        variable rand_float: real;
        variable rand: integer;
        variable seed1, seed2: integer := 1;
        variable rand_signal: std_logic_vector(31 downto 0);
        variable prev_rand: std_logic_vector(31 downto 0);
    begin
        -- Initialize all signals here
        i_rd_request      <= '0';
        i_rd_request_addr <= (others => '0');


        rst_n <= '0';
        wait for ClockPeriod;
        rst_n <= '1';

        ReadFromCache(
            address => x"00_00_00_10",
            expected_result => x"00000010",
            should_miss => true
        );

        ReadFromCache(
            address => x"00_00_00_18",
            expected_result => x"00000018",
            should_hit => true
        );

        ReadFromCache(
            address => x"00_01_00_18",
            expected_result => x"00_01_00_18",
            should_miss => true
        );

        ReadFromCache(
            address => x"00_02_00_18",
            expected_result => x"00_02_00_18",
            should_miss => true
        );

        ReadFromCache(
            address => x"00_03_00_18",
            expected_result => x"00_03_00_18",
            should_miss => true
        );

        ReadFromCache(
            address => x"00_00_00_1C",
            expected_result => x"00_00_00_1C",
            should_hit => true
        );

        ReadFromCache(
            address => x"00_04_00_18",
            expected_result => x"00_04_00_18",
            should_miss => true
        );

        report "Trying 5'000 random addresses";
        for iter in 0 to 5000 loop
            uniform(seed1, seed2, rand_float);
            rand := integer(floor(rand_float * (2.0**29)));
            rand_signal := std_logic_vector(to_unsigned(rand, 30)) & "00";
            ReadFromCache(
                address => rand_signal,
                expected_result => rand_signal
            );
        end loop;
        report "Done!";

        report "Trying nearby accesses";
        for iter in 0 to 1000 loop
            uniform(seed1, seed2, rand_float);
            rand := integer(floor(rand_float * (2.0**29)));
            rand_signal := std_logic_vector(to_unsigned(rand, 30)) & "00";
            ReadFromCache(
                address => rand_signal,
                expected_result => rand_signal
            );

            wait until rising_edge(clk);
            i_rd_request <= '1';
            wait until rising_edge(clk);


            prev_rand := rand_signal;
            for widx in 0 to LINE_SIZE-1 loop
                -- Read signal in the same block
                rand_signal := rand_signal(31 downto (clog2(LINE_SIZE)+2)) & std_logic_vector(to_unsigned(widx, clog2(LINE_SIZE))) & "00";

                i_rd_request <= '1';
                i_rd_request_addr <= rand_signal;

                -- NOTE: Here we're testing that back to back requests work as expected
                --       As in, we should be able to request the next entry while the
                --       cache is sending us the previous one.

                wait until falling_edge(clk);
                assert o_hit = '1' report "Nearby accesses should hit";
                assert o_data_out = rand_signal report "Invalid output";

                wait until rising_edge(clk);
                prev_rand := rand_signal;

            end loop;
        end loop;


        report "Done!";

        for i in 0 to 9 loop
            wait until rising_edge(clk);
        end loop;

        -- Stop the simulation and return
        sim_stopped <= '1';
        report "Simulation Finished!";
        wait;
    end process TestProcess;

    ClockGen: process
    begin
        if sim_stopped = '0' then 
            clk <= not clk;
            wait for ClockPeriod/2;
        else
            wait;
        end if;
    end process ClockGen;

end tb;

