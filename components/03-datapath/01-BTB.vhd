library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BTB is
    generic (
        NBIT: integer := 32;
        LINE_ADDR_WIDTH: integer := 4
    );
    port (
        enable, clk, reset_n, write_en: in std_logic;
        taken_branch: in std_logic;
        next_addr_computed: in std_logic_vector(NBIT-1 downto 0);
        next_pc: in std_logic_vector(NBIT-1 downto 0);

        next_pc_mem_stage: in std_logic_vector(NBIT-1 downto 0);

        jump_address: out std_logic_vector(NBIT-1 downto 0);
        sel_mux_next_pc: out std_logic; --0 for normal execution, 1 for jump

        flush: out std_logic
    );
end BTB;

architecture behavioral of BTB is
    constant NUMBER_OF_LINES: integer := 2**LINE_ADDR_WIDTH;

    type BTBMemoryType is array(0 to NUMBER_OF_LINES-1) of std_logic_vector(NBIT-1 downto 0);


    signal next_addr: BTBMemoryType := (others => (others => '0'));
    signal curr_addr: BTBMemoryType := (others => (others => '0'));

    --to every line inside the BTB is assigned a validity bit:
    --when it is 1, the entry is not valid, so it can be replaced
    --when it is 0, the entry is valid
    signal validity: std_logic_vector(0 to NUMBER_OF_LINES-1) := (others => '1');

    --to every line inside the BTB is assigned also a replace bit:
    --the replace bit is looked at only when the BTB is full and all the entries inside
    --it are valid
    --when this bit is 0, the entry can be replaced
    --if the entry is, in fact, replaced, the replace bit is immediately put to 1
    --when this bit is 1, the entry cannot be replaced
    --if, at a certain point, all replace bits are set, they will all be put to zero again
    signal last_replaced: std_logic_vector(0 to NUMBER_OF_LINES-1) := (others => '0');

    --signals in fetch stage:
    signal jump_address_fetch: std_logic_vector(NBIT-1 downto 0) := (others => '0');
    signal sel_mux_next_pc_fetch: std_logic := '0';

    --signals in mem stage:
    signal matching_memory, different_link: std_logic := '0';
    signal jump_address_mem: std_logic_vector(NBIT-1 downto 0) := (others => '0');
    signal sel_mux_next_pc_mem: std_logic := '0';
    signal takes_from_mem: std_logic := '0';
    signal flush_mem: std_logic := '0';
    signal validity_mem: std_logic_vector(0 to NUMBER_OF_LINES-1) := (others => '1');
    signal last_replaced_mem: std_logic_vector(0 to NUMBER_OF_LINES-1) := (others => '0');
    signal next_addr_mem: BTBMemoryType := (others => (others => '0'));
    signal curr_addr_mem: BTBMemoryType := (others => (others => '0'));


begin


    process (clk)
    begin
        if rising_edge(clk) then
            if (reset_n = '0') then
                --internal values
                validity <= (others => '1');
                last_replaced <= (others => '0');
                curr_addr <= (others => (others => '0'));
                next_addr <= (others => (others => '0'));
            elsif (enable = '1') then
                if (takes_from_mem = '0') then
                    --take the decision from fetch
                    validity <= validity;
                    last_replaced <= last_replaced;
                    curr_addr <= curr_addr;
                    next_addr <= next_addr;
                else
                    --take the decision from mem
                    validity <= validity_mem;
                    last_replaced <= last_replaced_mem;
                    curr_addr <= curr_addr_mem;
                    next_addr <= next_addr_mem;
                end if;
            end if;
        end if;
    end process;

    --combinational signals
    jump_address <= jump_address_fetch when takes_from_mem = '0' else jump_address_mem;
    sel_mux_next_pc <= sel_mux_next_pc_fetch when takes_from_mem = '0' else sel_mux_next_pc_mem;
    takes_from_mem <= (taken_branch XOR matching_memory) when different_link = '0' else '1';
    flush <= flush_mem when takes_from_mem = '1' else '0';


    first_scan:
    process (enable, next_pc, curr_addr, validity, next_addr)
    begin
        sel_mux_next_pc_fetch <= '0';
        jump_address_fetch <= (others => '0');
        if (enable = '1') then
            search_equal_entry:
            for i in 0 to NUMBER_OF_LINES-1 loop
                if ((next_pc = curr_addr(i)) AND (validity(i) = '0')) then
                    sel_mux_next_pc_fetch <= '1';
                    jump_address_fetch <= next_addr(i);
                    exit;
                end if;
            end loop search_equal_entry;
        end if;
    end process;

    memory_scan:
    process (enable, next_pc_mem_stage, curr_addr, validity, next_addr, next_addr_computed)
    begin
        matching_memory <= '0';
        different_link <= '0';
        if (enable = '1') then
            search_equal_entry2:
            for i in 0 to NUMBER_OF_LINES-1 loop
                if ((next_pc_mem_stage = curr_addr(i)) AND (validity(i) = '0')) then
                    matching_memory <= '1';
                    if (not(next_addr(i) = next_addr_computed)) then
                        different_link <= '1';
                    end if;
                    exit;
                end if;
            end loop search_equal_entry2;
        end if;
    end process;

    Decision_on_branch:
    process(reset_n, enable, write_en, taken_branch, matching_memory,
            next_pc_mem_stage, next_addr_computed, curr_addr_mem,
            different_link, validity, last_replaced,
            curr_addr, next_addr)
        variable full, replaced_all : integer;
    begin
        if (reset_n = '0') then
            validity_mem <= (others => '1');
            sel_mux_next_pc_mem <= '0';
            jump_address_mem <= (others => '0');
            flush_mem <= '0';
            curr_addr_mem <= (others => (others => '0'));
            next_addr_mem <= (others => (others => '0'));
            last_replaced_mem <= (others => '0');
        elsif (enable = '1') then
            validity_mem <= validity;
            sel_mux_next_pc_mem <= '0';
            jump_address_mem <= (others => '0');
            flush_mem <= '0';
            curr_addr_mem <= curr_addr;
            next_addr_mem <= next_addr;
            last_replaced_mem <= last_replaced;
            if (taken_branch = '0') then
                if (matching_memory = '1') then
                    --branch mispredicted: we thought it was taken, but it was not
                    search_inside_BTB:
                    for p in 0 to NUMBER_OF_LINES-1 loop
                        if ((next_pc_mem_stage = curr_addr(p)) AND (validity(p) = '0')) then
                            if (write_en = '1') then
                                validity_mem(p) <= '1';
                            end if;
                            --the last next_pc must be restored
                            sel_mux_next_pc_mem <= '1';
                            jump_address_mem <= curr_addr_mem(p);
                            --next instructions in pipeline must be flushed
                            flush_mem <= '1';
                            exit;
                        end if;
                    end loop search_inside_BTB;
                end if;
            else
                if (matching_memory = '0') then
                    sel_mux_next_pc_mem <= '1';
                    jump_address_mem <= next_addr_computed;
                    --next instructions in pipeline must be flushed
                    flush_mem <= '1';
                    if (write_en = '1') then
                        full := 1;
                        new_entry:
                        for j in 0 to NUMBER_OF_LINES-1 loop
                            if (validity(j) = '1') then
                                --branch mispredicted: we thought it was not taken, but it was
                                full := 0;
                                curr_addr_mem(j) <= next_pc_mem_stage;
                                next_addr_mem(j) <= next_addr_computed;
                                validity_mem(j) <= '0';
                                exit;
                            end if;
                        end loop new_entry;
                        replaced_all := 1;
                        if (full = 1) then
                            replace:
                            for k in 0 to NUMBER_OF_LINES-1 loop
                                if (last_replaced(k) = '0') then
                                    replaced_all := 0;
                                    curr_addr_mem(k) <= next_pc_mem_stage;
                                    next_addr_mem(k) <= next_addr_computed;
                                    last_replaced_mem(k) <= '1';
                                    exit;
                                end if;
                            end loop replace;

                            if (replaced_all = 1) then
                                last_replaced_mem <= (others => '0');
                                curr_addr_mem(0) <= next_pc_mem_stage;
                                next_addr_mem(0) <= next_addr_computed;
                                last_replaced_mem(0) <= '1';
                            end if;
                        end if;
                    end if;
                else
                    if (different_link = '1') then
                        search_inside_BTB2:
                        for z in 0 to NUMBER_OF_LINES-1 loop
                            if (next_pc_mem_stage = curr_addr(z)) then
                                if (write_en = '1') then
                                    next_addr_mem(z) <= next_addr_computed;
                                end if;
                                jump_address_mem <= next_addr_computed;
                                sel_mux_next_pc_mem <= '1';
                                flush_mem <= '1';
                                exit;
                            end if;
                        end loop search_inside_BTB2;
                    end if;
                end if;
            end if;
        else
            validity_mem <= validity;
            sel_mux_next_pc_mem <= '0';
            jump_address_mem <= (others => '0');
            flush_mem <= '0';
            curr_addr_mem <= curr_addr;
            next_addr_mem <= next_addr;
            last_replaced_mem <= last_replaced;
        end if;
    end process;

end behavioral;

