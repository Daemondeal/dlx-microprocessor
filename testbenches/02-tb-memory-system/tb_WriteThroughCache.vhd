library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.utils.all;
use work.tb_utils.all;

entity TB_WriteThroughCache is
end TB_WriteThroughCache;

architecture tb of TB_WriteThroughCache is
    component WriteThroughCache is
        generic (
            NBIT:       integer := 32;
            ADDR_WIDTH: integer := 32;

            NSETS:     integer := 4; -- Number of sets (Must be a power of two)
            WAYS:      integer := 4; -- Cache line in each seat
            LINE_SIZE: integer := 16 -- Size of each cache line
        );

        port (
            clk, rst_n: in std_logic;

            i_request_addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);

            i_rd_request:  in std_logic;

            i_wr_request: in std_logic;
            i_wr_data:     in std_logic_vector(NBIT-1 downto 0);
            i_wr_data_sel: in std_logic_vector((NBIT/8) - 1 downto 0);

            o_data_out: out std_logic_vector(NBIT-1 downto 0);
            o_hit:      out std_logic;


            -- Signals for loading the cache from memory
            o_addr_to_mem:    out std_logic_vector(ADDR_WIDTH-1 downto 0);
            o_mem_rd_request: out std_logic;
            i_data_from_mem:  in  std_logic_vector(NBIT-1 downto 0);
            i_data_from_mem_valid: in std_logic;

            -- Signals for writing back to memory
            o_mem_wr_request: out std_logic;
            i_mem_wr_done:    in std_logic;
            o_mem_wr_data: out std_logic_vector(NBIT-1 downto 0)
        );
    end component WriteThroughCache;

    signal clk: std_logic := '0';
    signal rst_n: std_logic := '1';

    signal sim_stopped: std_logic := '0'; 

    constant ClockPeriod: time := 1 ns;

    constant LINE_SIZE: integer := 8;
    constant WAYS: integer := 4;
    constant NSETS: integer := 1;


    signal i_request_addr: std_logic_vector(31 downto 0);

    signal i_rd_request: std_logic; 
    signal i_wr_request: std_logic; 
    signal i_wr_data: std_logic_vector(31 downto 0);
    signal i_wr_data_sel: std_logic_vector(3 downto 0);

    signal o_data_out: std_logic_vector(31 downto 0);
    signal o_hit: std_logic;

    signal o_addr_to_mem:   std_logic_vector(31 downto 0);
    signal o_mem_rd_request: std_logic;

    signal i_data_from_mem: std_logic_vector(31 downto 0);
    signal i_data_from_mem_valid: std_logic;

    signal o_mem_wr_request: std_logic;
    signal i_mem_wr_done: std_logic;
    signal o_dataout_to_mem: std_logic_vector(31 downto 0);

    constant MEM_AWIDTH: integer := 10;
    type FakeMemoryType is array (0 to 2**MEM_AWIDTH-1) of std_logic_vector(31 downto 0);
    signal fake_memory: FakeMemoryType  := (others => x"DEADBEEF");

    -- This memory mirrors what there would be in the memory if there was 
    -- no cache, to make sure that the cache works as intended
    signal mirror_memory: FakeMemoryType := (others => x"DEADBEEF");

begin
    DUT: WriteThroughCache
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

            i_request_addr => i_request_addr,

            i_rd_request  => i_rd_request,
            i_wr_request  => i_wr_request,
            i_wr_data     => i_wr_data,
            i_wr_data_sel => i_wr_data_sel,

            o_data_out => o_data_out,
            o_hit      => o_hit,

            o_addr_to_mem         => o_addr_to_mem,
            o_mem_rd_request      => o_mem_rd_request,
            i_data_from_mem       => i_data_from_mem,
            i_data_from_mem_valid => i_data_from_mem_valid,

            o_mem_wr_request => o_mem_wr_request,
            i_mem_wr_done    => i_mem_wr_done,
            o_mem_wr_data => o_dataout_to_mem
        );

    FakeMemoryProc: process
        variable clock_waits_float: real;
        variable clock_waits: integer;

        variable seed1, seed2: integer := 1;

        variable addr: integer := 0;
    begin
        i_data_from_mem <= (others => '0');
        i_data_from_mem_valid <= '0';
        i_mem_wr_done <= '0';

        wait until rising_edge(clk);
        if o_mem_rd_request = '1' then
            assert o_addr_to_mem(1 downto 0) = "00" report "Misaligned mem access";
            -- Wait a random amount of clocks, from 1 to 5
            uniform(seed1, seed2, clock_waits_float);
            clock_waits := integer(floor(clock_waits_float * 4.0)) + 1;

            for i in 0 to clock_waits-1 loop
                wait until rising_edge(clk);
            end loop;

            i_data_from_mem_valid <= '1';

            addr := to_integer(unsigned(o_addr_to_mem((MEM_AWIDTH+2)-1 downto 2)));
            i_data_from_mem <= fake_memory(addr);
            wait until rising_edge(clk);

            i_data_from_mem <= (others => '0');
            i_data_from_mem_valid <= '0';
        elsif o_mem_wr_request = '1' then
            assert o_addr_to_mem(1 downto 0) = "00" report "Misaligned mem access";
            -- Wait a random amount of clocks, from 1 to 5
            uniform(seed1, seed2, clock_waits_float);
            clock_waits := integer(floor(clock_waits_float * 4.0)) + 1;

            for i in 0 to clock_waits-1 loop
                wait until rising_edge(clk);
            end loop;

            i_mem_wr_done <= '1';

            addr := to_integer(unsigned(o_addr_to_mem((MEM_AWIDTH+2)-1 downto 2)));
            fake_memory(addr) <= o_dataout_to_mem;
            wait until rising_edge(clk);

            i_mem_wr_done <= '0';
        end if;
    end process FakeMemoryProc;

    TestProcess: process
        procedure ReadFromCache(
            address: in std_logic_vector(31 downto 0);
            should_miss: in boolean := false;
            should_hit:  in boolean := false) is

            variable expected_result: std_logic_vector(31 downto 0);
            variable addr: integer;
        begin
            wait until rising_edge(clk);
            i_rd_request <= '1';
            i_request_addr <= address;

            wait until rising_edge(clk);
            wait until falling_edge(clk);
            if o_hit = '1' then
                i_rd_request <= '0';
            end if;

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

            addr := to_integer(unsigned(address((MEM_AWIDTH+2)-1 downto 2)));
            expected_result := mirror_memory(addr);

            assert o_data_out = expected_result
                report "Invalid result. Got """ & to_hex_string(o_data_out) 
                     & """ but expected """ & to_hex_string(expected_result) 
                     & """ (addr: """ & to_hex_string(address) & """).";

            wait until rising_edge(clk);
            i_rd_request <= '0';
        end ReadFromCache;

        procedure WriteToCache(
            address: in std_logic_vector(31 downto 0);
            data:    in std_logic_vector(31 downto 0)) is
            variable addr: integer := 0;
        begin
            wait until rising_edge(clk);
            i_wr_request <= '1';
            i_request_addr <= address;
            i_wr_data <= data;

            wait until rising_edge(clk);
            wait until falling_edge(clk);

            if o_hit = '1' then
                i_wr_request <= '0';
            end if;

            for i in 0 to 1000 loop
                if o_hit = '1' then
                    exit;
                end if;
                wait until falling_edge(clk);
                if i = 1000 then
                    assert false report "Cache hasn't stopped writing after 1000 cycles, exiting...";
                    sim_stopped <= '1';
                    wait;
                end if;
            end loop;

            addr := to_integer(unsigned(i_request_addr((MEM_AWIDTH+2)-1 downto 2)));

            -- report "hex_addr: """ & to_hex_string(i_request_addr) & """";
            -- report "mirror(" & integer'image(addr) & ") <- " & to_hex_string(data) & """";

            for i in 0 to 3 loop
                if i_wr_data_sel(i) = '1' then
                    mirror_memory(addr)((i+1)*8-1 downto i*8) <= data((i+1)*8-1 downto i*8);
                end if;
            end loop;
            wait until rising_edge(clk);
            i_wr_request <= '0';
        end procedure WriteToCache;

        variable address: std_logic_vector(31 downto 0);
        variable data:    std_logic_vector(31 downto 0);
    begin
        -- Initialize all signals here
        i_rd_request   <= '0';
        i_wr_request   <= '0';
        i_request_addr <= (others => '0');
        i_wr_data <= (others => '0'); 
        i_wr_data_sel <= "1111";

        rst_n <= '0';
        wait for ClockPeriod;
        wait for ClockPeriod;
        rst_n <= '1';

        ReadFromCache(
            address => x"00_00_00_10",
            should_miss => true
        );

        WriteToCache(
            address => x"00_00_00_10",
            data    => random_stdvec(32)
        );

        ReadFromCache(
            address => x"00_00_00_10",
            should_hit => true
        );

        -- Manual Test
        WriteToCache(
            address => x"00_00_00_10",
            data    => random_stdvec(32)
        );

        report "Trying 5'000 random ops";
        for iter in 0 to 5000 loop
            address := (others => '0');
            address((MEM_AWIDTH+2)-1 downto 2) := random_stdvec(MEM_AWIDTH);
            if random_bool then
                data := random_stdvec(32);
                -- report "Writing """ & to_hex_string(data) & """ to addr """ & to_hex_string(address) & """";
                i_wr_data_sel <= random_stdvec(4);

                WriteToCache(
                    address => address,
                    data    => data
                );
            else
                ReadFromCache(
                    address => address
                );
            end if;
        end loop;
        report "Done!"; 

        -- NOTE: WT Cache may take a while to finish the
        --       last transaction
        for i in 0 to 10 loop
            wait until rising_edge(clk);
        end loop;

        for i in 0 to 2**MEM_AWIDTH-1 loop
            assert mirror_memory(i) = fake_memory(i)
                report "Memory contents differ at address " & integer'image(i)
                    & " (Mem content: """ & to_hex_string(fake_memory(i))
                    & """, Mirror content: """ & to_hex_string(mirror_memory(i))
                    & """)";
        end loop;
        -- assert mirror_memory = fake_memory report "The two memory contents should be identical";

        report "Trying nearby accesses";
        for iter in 0 to 1000 loop
            address := (others => '0');
            address((MEM_AWIDTH+2)-1 downto 2) := random_stdvec(MEM_AWIDTH);

            ReadFromCache(
                address => address
            );

            wait until rising_edge(clk);
            i_rd_request <= '1';
            wait until rising_edge(clk);


            data := mirror_memory(to_integer(unsigned(address((MEM_AWIDTH+2)-1 downto 2))));
            for widx in 0 to LINE_SIZE-1 loop
                -- Read signal in the same block
                address := address(31 downto (clog2(LINE_SIZE)+2)) & std_logic_vector(to_unsigned(widx, clog2(LINE_SIZE))) & "00";

                i_rd_request <= '1';
                i_request_addr <= address;

                -- NOTE: Here we're testing that back to back requests work as expected
                --       As in, we should be able to request the next entry while the
                --       cache is sending us the previous one.

                data := mirror_memory(to_integer(unsigned(address((MEM_AWIDTH+2)-1 downto 2))));
                wait until falling_edge(clk);
                assert o_hit = '1' report "Nearby accesses should hit";
                assert o_data_out = data 
                    report "Invalid output";

                wait until rising_edge(clk);

            end loop;
        end loop;

        report "Done!";

        assert mirror_memory = fake_memory report "The two memory contents should be identical";

        i_wr_data_sel <= "1111";
        report "Manual Test";

        ReadFromCache(
            address => x"00000100"
        );

        ReadFromCache(
            address => x"00000100",
            should_miss => false
        );
        ReadFromCache(
            address => x"00000200"
        );
        ReadFromCache(
            address => x"00000300"
        );
        ReadFromCache(
            address => x"00000400"
        );

        wait until rising_edge(clk);

        i_wr_request <= '1';
        i_request_addr <= x"00000400";
        i_wr_data <= x"AAAABBBB";

        wait until rising_edge(clk);
        wait until o_hit = '1';
        mirror_memory(to_integer(unsigned(i_request_addr((MEM_AWIDTH+2)-1 downto 2)))) <= x"AAAABBBB";

        i_request_addr <= x"00000404";
        i_wr_data <= x"AAAABBBC";
        wait until rising_edge(clk); 
        mirror_memory(to_integer(unsigned(i_request_addr((MEM_AWIDTH+2)-1 downto 2)))) <= x"AAAABBBC";
        wait until falling_edge(clk);
        assert o_hit = '0';

        wait until o_hit = '1';
        i_wr_request <= '0';
        wait until rising_edge(clk); 

        ReadFromCache(x"00000400");
        ReadFromCache(x"00000404");

        report "Manually testing wr_data_sel";

        address := x"00_00_00_08";
        i_wr_data_sel <= "1111";
        WriteToCache(address, x"00000000");

        mirror_memory(2) <= (others => '0');

        i_wr_data_sel <= "0001";
        WriteToCache(x"00_00_00_08", x"AABBCCDD");
        mirror_memory(2) <= x"00_00_00_DD";

        ReadFromCache(x"00_00_00_08");

        i_wr_data_sel <= "0010";
        WriteToCache(x"00_00_00_08", x"AABBCCDD");
        mirror_memory(2) <= x"00_00_CC_DD";

        ReadFromCache(x"00_00_00_08");

        i_wr_data_sel <= "0100";
        WriteToCache(x"00_00_00_08", x"AABBCCDD");
        mirror_memory(2) <= x"00_BB_CC_DD";

        ReadFromCache(x"00_00_00_08");

        i_wr_data_sel <= "1000";
        WriteToCache(x"00_00_00_08", x"AABBCCDD");
        mirror_memory(2) <= x"AA_BB_CC_DD";

        ReadFromCache(x"00_00_00_08");

        i_wr_data_sel <= "1011";
        WriteToCache(x"00_00_00_08", x"00_00_00_00");
        mirror_memory(2) <= x"00_BB_00_00";

        ReadFromCache(x"00_00_00_08");

        for i in 0 to 10 loop
            wait until rising_edge(clk);
        end loop;

        assert fake_memory = mirror_memory
            report "The memory contents must be the same";

        report "Done";



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

