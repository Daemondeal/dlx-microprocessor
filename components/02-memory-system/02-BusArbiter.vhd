library ieee;

use ieee.std_logic_1164.all;

entity BusArbiter is
    generic (
        NBIT:       integer := 32;
        ADDR_WIDTH: integer := 32
    );
    port (
        i_clk, i_rst_n: in std_logic;

        -- Instruction Cache
        i_icache_mem_addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);

        i_icache_rd_request:          in std_logic;
        o_icache_data_from_mem:       out std_logic_vector(NBIT-1 downto 0);
        o_icache_data_from_mem_valid: out std_logic;

        -- Data Cache
        i_dcache_mem_addr:    in std_logic_vector(ADDR_WIDTH-1 downto 0);

        i_dcache_rd_request:          in std_logic;
        o_dcache_data_from_mem:       out std_logic_vector(NBIT-1 downto 0);
        o_dcache_data_from_mem_valid: out std_logic;

        i_dcache_wr_request:  in std_logic;
        i_dcache_data_to_mem: in std_logic_vector(NBIT-1 downto 0);
        o_dcache_wr_done:     out std_logic;

        -- Output to mem interface
        o_bus_mem_addr:    out std_logic_vector(ADDR_WIDTH-1 downto 0);

        o_bus_rd_request:          out std_logic;
        i_bus_data_from_mem:       in  std_logic_vector(NBIT-1 downto 0);
        i_bus_data_from_mem_valid: in  std_logic;

        o_bus_wr_request:  out std_logic;
        o_bus_data_to_mem: out std_logic_vector(NBIT-1 downto 0);
        i_bus_wr_done:     in  std_logic
    );

end BusArbiter;

architecture Behavioral of BusArbiter is
    type StateType is (Idle, GrantICache, GrantDCache);
    signal state, state_next: StateType;

    signal grant_icache, grant_dcache: std_logic;
begin

    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                state <= Idle;
            else
                state <= state_next;
            end if;
        end if;
    end process;

    CachePassthrough: process (
        grant_icache, grant_dcache,
        i_bus_data_from_mem, i_bus_data_from_mem_valid, i_bus_wr_done,
        i_icache_mem_addr, i_icache_rd_request,
        i_dcache_mem_addr, i_dcache_rd_request, i_dcache_wr_request, i_dcache_data_to_mem
    )
    begin
        o_icache_data_from_mem <= (others => '0');
        o_icache_data_from_mem_valid <= '0';

        o_dcache_data_from_mem <= (others => '0');
        o_dcache_data_from_mem_valid <= '0';
        o_dcache_wr_done <= '0';

        o_bus_mem_addr <= (others => '0');
        o_bus_rd_request <= '0';
        o_bus_wr_request <= '0';
        o_bus_data_to_mem <= (others => '0');

        if grant_icache = '1' then
            o_bus_mem_addr <= i_icache_mem_addr;

            o_bus_rd_request <= i_icache_rd_request;
            o_icache_data_from_mem <= i_bus_data_from_mem;
            o_icache_data_from_mem_valid <= i_bus_data_from_mem_valid;

            o_bus_wr_request <= '0';
            o_bus_data_to_mem <= (others => '0');
        elsif grant_dcache = '1' then
            o_bus_mem_addr <= i_dcache_mem_addr;

            o_bus_rd_request <= i_dcache_rd_request;
            o_dcache_data_from_mem <= i_bus_data_from_mem;
            o_dcache_data_from_mem_valid <= i_bus_data_from_mem_valid;

            o_bus_wr_request <= i_dcache_wr_request;
            o_bus_data_to_mem <= i_dcache_data_to_mem;
            o_dcache_wr_done <= i_bus_wr_done;
        end if;

    end process CachePassthrough;


    process (
        state,
        i_icache_rd_request,
        i_dcache_rd_request, i_dcache_wr_request
    )
    begin
        state_next <= state;
        grant_icache <= '0';
        grant_dcache <= '0';

        case state is
            when Idle =>
                if i_icache_rd_request = '1' then
                    state_next <= GrantICache;
                elsif i_dcache_wr_request = '1' or i_dcache_rd_request = '1' then
                    state_next <= GrantDCache;
                end if;
            when GrantICache =>
                grant_icache <= '1';
                if i_icache_rd_request = '0' then
                    state_next <= Idle;
                end if;
            when GrantDCache =>
                grant_dcache <= '1';
                if (i_dcache_wr_request = '0' and i_dcache_rd_request = '0') then
                    state_next <= Idle;
                end if;
            when others =>
                state_next <= Idle;
        end case;
    end process;
end Behavioral;
