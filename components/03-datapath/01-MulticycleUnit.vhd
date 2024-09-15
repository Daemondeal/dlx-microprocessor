library ieee;

use ieee.std_logic_1164.all;
use work.control_word.all;

entity MulticycleUnit is
    generic (NBIT: integer := 32);
    port (
        i_clk, i_rst_n: in std_logic;
        i_in1, i_in2: in std_logic_vector(NBIT-1 downto 0);

        i_flush: in std_logic;
        i_stall: in std_logic;

        i_multicycle_op: in MulticycleOpType;
        o_result: out std_logic_vector(NBIT-1 downto 0);
        o_busy: out std_logic
    );
end MulticycleUnit;

architecture Structural of MulticycleUnit is
    component Multiplier is
        generic (
            NBIT: integer := 32
        );
        port (
            i_clk, i_rst_n: in std_logic;
            i_in1, i_in2: in std_logic_vector(NBIT-1 downto 0);
            i_mult_request: in std_logic;
            o_product: out std_logic_vector(NBIT-1 downto 0);
            o_mult_busy: out std_logic
        );
    end component Multiplier;

    component Divider is
        generic (NBIT: integer := 32);
        port (
            i_clk, i_rst_n: in std_logic;
            i_dividend, i_divisor: in std_logic_vector(NBIT-1 downto 0);
            i_start: in std_logic;
            o_quotient, o_remainder: out std_logic_vector(NBIT-1 downto 0);
            o_result_valid: out std_logic
        );
    end component Divider;


    signal units_reset_n: std_logic;

    signal multiply_request: std_logic;
    signal multiply_result: std_logic_vector(NBIT-1 downto 0);
    signal multiply_busy: std_logic;

    signal divide_request: std_logic;
    signal divide_valid: std_logic;

    signal divide_quotient, divide_remainder: std_logic_vector(NBIT-1 downto 0);
begin

    -- The multiplier needs a separate stall signal since it can cause
    -- the same stall itself, so we need a way for it to have lower priority
    -- in case something else stalls execution (Otherwise by stalling it would
    -- also stall itself, deadlocking the whole CPU).
    proc_Requests:
    process (i_multicycle_op, i_stall, multiply_result, multiply_busy, divide_quotient, divide_remainder, divide_valid)
    begin
        multiply_request <= '0';
        divide_request <= '0';
        o_result <= (others => '0');
        o_busy <= '0';

        if i_stall = '0' then
            case i_multicycle_op is
                when MulticycleMultiply =>
                    multiply_request <= '1';
                    o_result <= multiply_result;
                    o_busy <= multiply_busy;

                when MulticycleDivide =>
                    divide_request <= '1';
                    o_result <= divide_quotient;
                    o_busy <= not divide_valid;

                when MulticycleModulo =>
                    divide_request <= '1';
                    o_result <= divide_remainder;
                    o_busy <= not divide_valid;

                when MulticycleNone =>
                when others =>
            end case;
        end if;
    end process;

    -- If the pipeline stage gets flushed, we need to restart the mutiplier and
    -- abort the current running operation, otherwise it will keep operating and
    -- stalling the pipeline for a result that would get discarded anyways.
    units_reset_n <= not ((not i_rst_n) or i_flush);

    unit_Mult: Multiplier
        generic map (NBIT => NBIT)
        port map (
            i_clk => i_clk,
            i_rst_n => units_reset_n,

            i_in1 => i_in1,
            i_in2 => i_in2,

            i_mult_request =>  multiply_request,
            o_product => multiply_result,
            o_mult_busy =>  multiply_busy
        );

    unit_Div: Divider
        generic map (NBIT => NBIT)
        port map (
            i_clk => i_clk,
            i_rst_n => units_reset_n,
            i_dividend => i_in1,
            i_divisor => i_in2,
            i_start => divide_request,

            o_quotient => divide_quotient,
            o_remainder => divide_remainder,
            o_result_valid => divide_valid
        );

end Structural;
