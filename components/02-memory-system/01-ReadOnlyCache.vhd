library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;


-- This is a set associative Pseudo-LRU cache
-- This cache will be (NSETS * WAYS * LINE_SIZE * NBIT) bits.
entity ReadOnlyCache is
    generic (
        NBIT:       integer := 32;
        ADDR_WIDTH: integer := 32;

        NSETS:     integer := 4; -- Number of sets (Must be a power of two)
        WAYS:      integer := 4; -- Cache line in each seat
        LINE_SIZE: integer := 16 -- Size of each cache line
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

end ReadOnlyCache;


architecture Behavioral of ReadOnlyCache is
    component UpCounter is
        generic (
            NBIT: integer := 8);
        port (
            clk:       in std_logic;
            rst_n:     in std_logic;
            enable:    in std_logic;

            terminal_count: out std_logic;
            count: out std_logic_vector(NBIT-1 downto 0));
    end component UpCounter;

    -- The full address is: | Tag | set_idx | word_idx | byte_idx |
    constant BYTE_WIDTH: integer := clog2(NBIT/8);
    constant SET_WIDTH: integer  := clog2(NSETS);
    constant LINE_WIDTH: integer := clog2(LINE_SIZE);

    constant TAG_WIDTH: integer := ADDR_WIDTH - SET_WIDTH - LINE_WIDTH - BYTE_WIDTH;

    type CacheLineType is array (0 to LINE_SIZE-1) of std_logic_vector(NBIT-1 downto 0);
    type CacheMemory is array (0 to WAYS-1) of CacheLineType;

    type TagType is array (0 to WAYS-1) of std_logic_vector(TAG_WIDTH-1 downto 0);

    type CacheSet is record
        lines: CacheMemory;
        tags: TagType;

        valid_bits: std_logic_vector(WAYS-1 downto 0);
        mru_bits: std_logic_vector(WAYS-1 downto 0);
    end record CacheSet;

    type CacheSetArray is array(0 to NSETS-1) of CacheSet;
    type MRUBitsArray is array(0 to NSETS-1) of std_logic_vector(WAYS-1 downto 0);
    type NextVictimArray is array(0 to NSETS-1) of unsigned(clog2(WAYS)-1 downto 0);

    signal sets: CacheSetArray;

    -- Those cannot be in sets because you cannot drive the same signal
    -- from a process, even if it's different parts of the same record.
    signal mru_bits_next: MRUBitsArray;
    signal next_victims: NextVictimArray;

    signal hit: std_logic;

    -- Indicates the currently chosen line. Only has meaning if hit = 1
    signal chosen_line: unsigned(clog2(WAYS)-1 downto 0);

    -- Signals for updating the cache on misses
    type CacheStateType is (Idle, Miss);
    signal state, state_next: CacheStateType;

    -- wc: word counter, used for loading data from memory
    signal wc_rst_n, wc_enable, wc_terminal_count: std_logic;
    signal reg_wc_count: std_logic_vector(LINE_WIDTH-1 downto 0);

    -- These signals are set from the cache controller
    signal s_counter_reset_n:    std_logic;
    signal s_load_external_word: std_logic;

    -- Extract parts from input address
    -- Address: | tag | set_idx | word_idx | byte_idx |
    alias input_tag  is i_request_addr(ADDR_WIDTH-1 downto ADDR_WIDTH - TAG_WIDTH);
    alias input_set  is i_request_addr(ADDR_WIDTH - TAG_WIDTH - 1 downto ADDR_WIDTH - TAG_WIDTH - SET_WIDTH);
    alias input_word is i_request_addr(ADDR_WIDTH - TAG_WIDTH - SET_WIDTH - 1 downto BYTE_WIDTH);

    signal input_word_idx: integer;
    signal input_set_idx:  integer;
begin
    o_hit <= hit;

    -- Done to prevent warnings from modelsim, the first condition would work fine even with only one set
    input_set_idx <= to_integer(unsigned(input_set)) when NSETS > 1
                     else input_set_idx;


    input_word_idx <= to_integer(unsigned(input_word));


    FindMatchForAddress:
    process (
            i_rd_request, sets,
            input_tag, input_set_idx, input_word_idx
        )
    begin
        hit <= '0';
        o_data_out <= (others => '0');
        chosen_line <= (others => '0');

        if i_rd_request = '1' then
            for line_idx in 0 to WAYS-1 loop
                -- To have a valid hit, you need:
                --  1. Matching tags
                --  2. Valid bit set to 1
                if sets(input_set_idx).valid_bits(line_idx) = '1' and sets(input_set_idx).tags(line_idx) = input_tag then
                    hit <= '1';
                    o_data_out <= sets(input_set_idx).lines(line_idx)(input_word_idx);
                    chosen_line <= to_unsigned(line_idx, clog2(WAYS));
                end if;
            end loop;
        end if;
    end process;

    UpdateRegisters:
    process (clk)
        variable next_victim_idx, word_idx: integer;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                for i in 0 to NSETS-1 loop
                    sets(i).valid_bits <= (others => '0');
                    sets(i).mru_bits <= (others => '0');
                end loop;

                state <= Idle;
            else
                state <= state_next;

                for set_idx in 0 to NSETS-1 loop
                    sets(set_idx).mru_bits <= mru_bits_next(set_idx);
                end loop;

                -- Update Cache Line when loading word from memory
                if (s_load_external_word and i_data_from_mem_valid) = '1' then
                    next_victim_idx := to_integer(next_victims(input_set_idx));
                    word_idx        := to_integer(unsigned(reg_wc_count));

                    sets(input_set_idx).lines(next_victim_idx)(word_idx) <= i_data_from_mem;

                    -- At the end of a read transaction, update valid bit and tag
                    if wc_terminal_count = '1' then
                        sets(input_set_idx).valid_bits(next_victim_idx) <= '1';
                        sets(input_set_idx).tags(next_victim_idx)       <= input_tag;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Miss Logic

    -- The MRU bits get updated each hit. Any time there's a cache hit, its MRU bit gets set to 1.
    -- If by doing this all MRU bits become 1, then you clear all the others and set only the last one to 1.
    UpdateMRUBit:
    process (sets, hit, i_rd_request, chosen_line, input_set_idx)
        variable chosen_line_idx: integer;
        variable next_mru_bits: std_logic_vector(WAYS-1 downto 0);
        variable all_ones: std_logic_vector(WAYS-1 downto 0);
    begin
        all_ones := (others => '1');

        for set_idx in 0 to NSETS-1 loop
            mru_bits_next(set_idx) <= sets(set_idx).mru_bits;
        end loop;

        if hit = '1' and i_rd_request = '1' then
            chosen_line_idx := to_integer(chosen_line);
            next_mru_bits := sets(input_set_idx).mru_bits;
            next_mru_bits(chosen_line_idx) := '1';

            if next_mru_bits = all_ones then
                next_mru_bits := (others => '0');
                next_mru_bits(chosen_line_idx) := '1';
            end if;

            mru_bits_next(input_set_idx) <= next_mru_bits;
        end if;
    end process UpdateMRUBit;


    -- The next victim for each set is the first line where the MRU bit is set to zero.
    -- Since the MRU bits get reset when they all get to one, there always is a next victim to pick
    PickVictim:
    process (sets)
    begin
        for set_idx in 0 to NSETS-1 loop
            -- It should be impossible for all mru_bits to be zero, but we put this just in case
            next_victims(set_idx) <= (others => '0');

            for line_idx in 0 to WAYS-1 loop
                if sets(set_idx).mru_bits(line_idx) = '0' then
                    next_victims(set_idx) <= to_unsigned(line_idx, clog2(WAYS));
                end if;
            end loop;
        end loop;
    end process;


    -- coverage off
    -- Don't reset only when both the external reset or the
    -- reset from the controller are not set
    wc_rst_n <= rst_n and s_counter_reset_n;

    wc_enable <= s_load_external_word and i_data_from_mem_valid;
    -- coverage on

    -- This counter is used to count the index of the word
    -- in the current line to replace when loading the cache on a miss
    WordInLineIndex: UpCounter
        generic map (NBIT => clog2(LINE_SIZE))
        port map (
            clk   => clk,
            rst_n => wc_rst_n,

            enable    => wc_enable,

            terminal_count => wc_terminal_count,
            count => reg_wc_count

        );

    -- Output addr: |       Tag      |    set_idx     | word_idx | byte_idx  |
    -- Comes from:  | i_request_addr | i_request_addr | counter  | all zeros |
    GenerateOutputAddr:
    process (reg_wc_count, input_tag, input_set)
    begin
        o_addr_to_mem <= (others => '0');

        -- word idx
        o_addr_to_mem(BYTE_WIDTH + LINE_WIDTH - 1 downto BYTE_WIDTH) <= reg_wc_count;

        -- set idx
        if (NSETS > 1) then
            o_addr_to_mem(BYTE_WIDTH + LINE_WIDTH + SET_WIDTH - 1 downto BYTE_WIDTH + LINE_WIDTH) <= input_set;
        end if;

        -- tag
        o_addr_to_mem(ADDR_WIDTH - 1 downto ADDR_WIDTH - TAG_WIDTH) <= input_tag;
    end process;

    FSM_Proc:
    process (state, hit, i_rd_request, wc_terminal_count, i_data_from_mem_valid)
    begin
        case state is
            when Idle =>
                s_counter_reset_n    <= '0';
                s_load_external_word <= '0';
                o_mem_rd_request     <= '0';

                if (hit = '0' and i_rd_request = '1') then
                    state_next <= Miss;
                else
                    state_next <= Idle;
                end if;

            when Miss =>
                s_counter_reset_n    <= '1';
                s_load_external_word <= '1';
                o_mem_rd_request     <= '1';

                if (wc_terminal_count and i_data_from_mem_valid) = '1' then
                    state_next <= Idle;
                else
                    state_next <= Miss;
                end if;
            when others =>
        end case;

    end process FSM_Proc;

end Behavioral;
