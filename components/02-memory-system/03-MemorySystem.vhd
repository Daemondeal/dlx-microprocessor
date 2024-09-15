library ieee;

use ieee.std_logic_1164.all;

entity MemorySystem is
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
end MemorySystem;

architecture Structural of MemorySystem is
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

    component ReadOnlyCache is
        generic (
            NBIT:       integer := 32;
            ADDR_WIDTH: integer := 32;

            NSETS:     integer := 2; -- Number of sets (Must be a power of two)
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
    end component ReadOnlyCache;

    component BusArbiter is
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

    end component BusArbiter;

    component WishboneBusInterface is
        generic (
            NBIT:       integer := 32;
            ADDR_WIDTH: integer := 32
        );

        port(
            i_wb_clk: in std_logic;

            -- NOTE: While in the project all resets are negated,
            --       the wishbone standard mandates an active high reset
            i_wb_rst: in std_logic;

            -- Internal Cache Signals (As they come out of the arbiter)
            i_mem_addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);

            -- Read Request
            i_mem_rd_request:          in std_logic;
            o_mem_data_from_mem:       out std_logic_vector(NBIT-1 downto 0);
            o_mem_data_from_mem_valid: out std_logic;

            -- Write Request
            i_mem_wr_request:  in std_logic;
            i_mem_data_to_mem: in std_logic_vector(NBIT-1 downto 0);
            o_mem_wr_done:     out std_logic;

            -- Wishbone Signals

            -- If asserted, it indicates that the 
            -- slave cannot accept another transfer
            i_wb_stall: in std_logic; 

            -- Indicates the termination of a bus cycle
            i_wb_ack:   in std_logic;

            -- Indicates that an error occurred in the bus transaction
            i_wb_err:   in std_logic;

            -- Data transferred from slave to master
            i_wb_data:  in std_logic_vector(NBIT-1 downto 0);

            -- Indicates that a valid bus cycle is in progress
            o_wb_cyc:  out std_logic; 

            -- Indicates the start of a valid data transfer cycle This will be high
            -- until the slave accepts the request, at which point this has to stay
            -- low until the next request. 
            -- Note that this only means that the master is actively making the
            -- request. If o_wb_stb is low and o_wb_cyc is high, it means that the
            -- slave has accepted the previous request, but it still isn't done and it
            -- still has not given an answer.
            o_wb_stb:  out std_logic;

            -- Indicates wheter the current bus cycle is 
            -- a read (from the slave) or a write (to the slave)
            o_wb_we:   out std_logic;

            -- The output adddress towards the slave
            o_wb_addr: out std_logic_vector(ADDR_WIDTH-1 downto 0);

            -- The data sent from master to slave
            o_wb_data: out std_logic_vector(NBIT-1 downto 0)
        );

    end component WishboneBusInterface;

    -- Instruction Cache
    signal ic_addr_to_mem: std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal ic_mem_rd_request: std_logic;
    signal ic_data_from_mem: std_logic_vector(NBIT-1 downto 0);
    signal ic_data_from_mem_valid: std_logic;

    -- Data Cache
    signal dc_addr_to_mem: std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal dc_mem_rd_request: std_logic;
    signal dc_data_from_mem: std_logic_vector(NBIT-1 downto 0);
    signal dc_data_from_mem_valid: std_logic;

    signal dc_mem_wr_request: std_logic;
    signal dc_mem_wr_done: std_logic;
    signal dc_data_to_mem: std_logic_vector(NBIT-1 downto 0);

    -- Arbiter
    signal ar_addr_to_mem: std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal ar_mem_rd_request: std_logic;
    signal ar_data_from_mem: std_logic_vector(NBIT-1 downto 0);
    signal ar_data_from_mem_valid: std_logic;

    signal ar_mem_wr_request: std_logic;
    signal ar_data_to_mem: std_logic_vector(NBIT-1 downto 0);
    signal ar_mem_wr_done: std_logic;

    -- signal clk: std_logic;

    alias clk is i_wb_clk;
    signal rst_n: std_logic;

begin
    -- NOTE: Renaming signals like this adds a delta delay, which
    --       messes with the simulation. Just use alias if you need
    --       only to rename signals
    -- clk <= i_wb_clk;

    rst_n <= not i_wb_rst;


    DCache: WriteThroughCache
        generic map (
            NBIT => NBIT,
            ADDR_WIDTH => ADDR_WIDTH,

            NSETS =>     DATA_CACHE_NSETS,
            WAYS  =>     DATA_CACHE_WAYS,
            LINE_SIZE => DATA_CACHE_LINE_SIZE
        )
        port map (
            clk => clk,
            rst_n => rst_n,

            i_request_addr => i_dc_addr,

            i_rd_request => i_dc_rd_request,
            o_data_out   => o_dc_rd_data,

            i_wr_request  => i_dc_wr_request,
            i_wr_data     => i_dc_wr_data,
            i_wr_data_sel => i_dc_wr_data_sel,

            o_hit => o_dc_hit,

            o_addr_to_mem    => dc_addr_to_mem,
            o_mem_rd_request => dc_mem_rd_request,
            i_data_from_mem  => dc_data_from_mem,
            i_data_from_mem_valid => dc_data_from_mem_valid,

            o_mem_wr_request => dc_mem_wr_request,
            i_mem_wr_done    => dc_mem_wr_done,
            o_mem_wr_data    => dc_data_to_mem
        );

    ICache: ReadOnlyCache
        generic map (
            NBIT => NBIT,
            ADDR_WIDTH => ADDR_WIDTH,

            NSETS =>     INSTRUCTION_CACHE_NSETS,
            WAYS  =>     INSTRUCTION_CACHE_WAYS,
            LINE_SIZE => INSTRUCTION_CACHE_LINE_SIZE
        )
        port map (
            clk => clk,
            rst_n => rst_n,

            i_request_addr => i_ic_addr,

            i_rd_request => i_ic_rd_request,
            o_data_out   => o_ic_rd_data,

            o_hit => o_ic_hit,

            o_addr_to_mem    => ic_addr_to_mem,
            o_mem_rd_request => ic_mem_rd_request,
            i_data_from_mem  => ic_data_from_mem,
            i_data_from_mem_valid => ic_data_from_mem_valid
        );

    Arbiter: BusArbiter
        generic map (
            NBIT => 32,
            ADDR_WIDTH => 32
        )
        port map (
            i_clk => clk,
            i_rst_n => rst_n,

            i_icache_mem_addr => ic_addr_to_mem,

            i_icache_rd_request => ic_mem_rd_request,
            o_icache_data_from_mem => ic_data_from_mem,
            o_icache_data_from_mem_valid => ic_data_from_mem_valid,

            i_dcache_mem_addr => dc_addr_to_mem,

            i_dcache_rd_request => dc_mem_rd_request,
            o_dcache_data_from_mem => dc_data_from_mem,
            o_dcache_data_from_mem_valid => dc_data_from_mem_valid,

            i_dcache_wr_request => dc_mem_wr_request,
            i_dcache_data_to_mem => dc_data_to_mem,
            o_dcache_wr_done => dc_mem_wr_done,

            o_bus_mem_addr => ar_addr_to_mem,

            o_bus_rd_request => ar_mem_rd_request,
            i_bus_data_from_mem => ar_data_from_mem,
            i_bus_data_from_mem_valid => ar_data_from_mem_valid,

            o_bus_wr_request  => ar_mem_wr_request,
            o_bus_data_to_mem => ar_data_to_mem,
            i_bus_wr_done     => ar_mem_wr_done
        );

    WBInterface: WishboneBusInterface
        generic map (
            NBIT => 32,
            ADDR_WIDTH => 32
        )
        port map (
            i_wb_clk => i_wb_clk,
            i_wb_rst => i_wb_rst,

            i_wb_stall => i_wb_stall,
            i_wb_ack => i_wb_ack,
            i_wb_err => i_wb_err,
            i_wb_data => i_wb_data,

            o_wb_cyc => o_wb_cyc,
            o_wb_stb => o_wb_stb,
            o_wb_we => o_wb_we,
            o_wb_addr => o_wb_addr,
            o_wb_data => o_wb_data,

            i_mem_addr => ar_addr_to_mem,

            i_mem_rd_request    => ar_mem_rd_request,
            o_mem_data_from_mem => ar_data_from_mem,
            o_mem_data_from_mem_valid => ar_data_from_mem_valid,

            i_mem_wr_request => ar_mem_wr_request,
            i_mem_data_to_mem => ar_data_to_mem,
            o_mem_wr_done => ar_mem_wr_done
        );
end Structural;
