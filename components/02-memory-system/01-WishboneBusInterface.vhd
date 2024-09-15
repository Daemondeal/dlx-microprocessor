library ieee;

use ieee.std_logic_1164.all;

entity WishboneBusInterface is
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
end WishboneBusInterface;

architecture Behavioral of WishboneBusInterface is
    type StateType is (Idle, BusRequest, BusWait);
    signal state, state_next: StateType;

    signal wb_cyc, wb_stb: std_logic;

    signal memory_request: std_logic;
begin

    o_wb_cyc <= wb_cyc;
    o_wb_stb <= wb_stb;

    process (i_wb_clk)
    begin
        if rising_edge(i_wb_clk) then
            if i_wb_rst = '1' then
                state <= Idle;
            else
                state <= state_next;
            end if;
        end if;
    end process;


    -- Passing signals from inside through. This is fine to do even when their
    -- value is undefined, since those signals will be ignored unless the proper
    -- control signals are asserted.
    o_wb_addr <= i_mem_addr;
    o_wb_data <= i_mem_data_to_mem;
    o_mem_data_from_mem <= i_wb_data;

    -- Enable writes only when we get a write request.
    o_wb_we <= i_mem_wr_request and wb_cyc;

    memory_request <= i_mem_wr_request or i_mem_rd_request;

    process (state, i_wb_stall, i_wb_ack, i_mem_wr_request, i_mem_rd_request, memory_request)
    begin
        o_mem_data_from_mem_valid <= '0';
        o_mem_wr_done <= '0';
        state_next <= state;

        wb_cyc <= '0';
        wb_stb <= '0';

        case state is
            when Idle =>
                wb_cyc <= '0';
                wb_stb <= '0';

                if i_wb_stall = '0' and memory_request = '1' then
                    state_next <= BusRequest;
                end if;
            when BusRequest =>
                wb_cyc <= '1';
                wb_stb <= '1';

                -- As soon as we i_wb_stall goes low, the request has been
                -- accepted. Ideally, here we should be able to send another
                -- request while we wait for the previous one, but this master
                -- does not support pipelined requests
                if i_wb_stall = '0' then
                    state_next <= BusWait;

                    -- The ack signal could come at the same time as
                    -- the stall going low, which would mean that the
                    -- transaction ended right there
                    if i_wb_ack = '1' then
                        state_next <= Idle;

                        if i_mem_wr_request = '1' then
                            o_mem_wr_done <= '1';
                        elsif i_mem_rd_request = '1' then
                            o_mem_data_from_mem_valid <= '1';
                        else
                            assert false report "Invalid usage of interface: the request must either be a read or a write";
                        end if;
                    end if;
                end if;
            when BusWait =>
                wb_cyc <= '1';
                wb_stb <= '0';

                -- The transaction is still ongoing, we only
                -- need to wait for the slave to be done
                if i_wb_ack = '1' then

                    state_next <= Idle;

                    if i_mem_wr_request = '1' then
                        o_mem_wr_done <= '1';
                    elsif i_mem_rd_request = '1' then
                        o_mem_data_from_mem_valid <= '1';
                    else
                        assert false report "Invalid usage of interface: the request must either be a read or a write";
                    end if;
                end if;
            when others =>
                o_mem_data_from_mem_valid <= '0';
                o_mem_wr_done <= '0';
                state_next <= state;
        end case;
    end process;
end Behavioral;
