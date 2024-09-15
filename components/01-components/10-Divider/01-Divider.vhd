library ieee;

use ieee.std_logic_1164.all;

use ieee.numeric_std.all;

use work.utils.all;

entity Divider is
    generic (NBIT: integer := 32);
    port (
        i_clk, i_rst_n: in std_logic;
        i_dividend, i_divisor: in std_logic_vector(NBIT-1 downto 0);
        i_start: in std_logic;
        o_quotient, o_remainder: out std_logic_vector(NBIT-1 downto 0);
        o_result_valid: out std_logic
    );
end entity Divider;

architecture Structural of Divider is
    component AdderP4 is
        generic (
            NBIT: integer := 32;
            NBIT_PER_BLOCK: integer := 4
        );
        port (
            A, B: in std_logic_vector(NBIT - 1 downto 0);
            Ci: in std_logic;

            S: out std_logic_vector(NBIT - 1 downto 0);
            Cout: out std_logic
        );
    end component AdderP4;

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

    signal reg_remainder, reg_remainder_next: std_logic_vector(NBIT-1 downto 0);
    signal reg_quotient, reg_quotient_next: std_logic_vector(NBIT-1 downto 0);
    signal reg_divisor, reg_divisor_next: std_logic_vector(NBIT-1 downto 0);

    signal remainder_load, quotient_load, divisor_load: std_logic_vector(1 downto 0);

    constant REM_LOAD_NOTHING: std_logic_vector(1 downto 0) := "00";
    constant REM_LOAD_SUM: std_logic_vector(1 downto 0) := "01";
    constant REM_LOAD_ZEROS: std_logic_vector(1 downto 0) := "10";
    constant REM_LOAD_ONES: std_logic_vector(1 downto 0) := "11";

    constant QUOT_LOAD_NOTHING: std_logic_vector(1 downto 0) := "00";
    constant QUOT_LOAD_SUM: std_logic_vector(1 downto 0) := "01";
    constant QUOT_LOAD_IN_DIVIDEND: std_logic_vector(1 downto 0) := "10";
    constant QUOT_LOAD_SHIFT: std_logic_vector(1 downto 0) := "11";

    constant DIV_LOAD_NOTHING: std_logic_vector(1 downto 0) := "00";
    constant DIV_LOAD_IN_DIVISOR: std_logic_vector(1 downto 0) := "01";
    constant DIV_LOAD_SUM: std_logic_vector(1 downto 0) := "10";

    signal counter_tc, counter_enable: std_logic;

    signal add_sub_a, add_sub_b, add_sub_b_modified: std_logic_vector(NBIT-1 downto 0);

    signal add_sub_res: std_logic_vector(NBIT-1 downto 0);
    signal twice_rem: std_logic_vector(NBIT-1 downto 0);

    signal is_remainder_positive: std_logic;
    signal add_invert_b, add_cin: std_logic;

    signal add_a_sel: std_logic_vector(1 downto 0);
    signal add_b_sel: std_logic_vector(1 downto 0);

    constant ADD_A_SEL_ZEROS : std_logic_vector(1 downto 0) := "00";
    constant ADD_A_SEL_QUOTIENT : std_logic_vector(1 downto 0) := "01";
    constant ADD_A_SEL_REMAINDER : std_logic_vector(1 downto 0) := "10";
    constant ADD_A_SEL_TWICE_REMAINDER : std_logic_vector(1 downto 0) := "11";

    constant ADD_B_SEL_INPUT_DIVIDEND: std_logic_vector(1 downto 0) := "00";
    constant ADD_B_SEL_DIVISOR: std_logic_vector(1 downto 0) := "01";
    constant ADD_B_SEL_QUOTIENT: std_logic_vector(1 downto 0) := "10";


    type StateType is (Idle, InvertDivisor, Dividing, AdjustingQuotient, AdjustingRemainder, Done);
    signal state, state_next: StateType;
begin

    twice_rem <= reg_remainder(NBIT-2 downto 0) & reg_quotient(NBIT-1);

    is_remainder_positive <= not reg_remainder(NBIT-1);

    o_quotient <= reg_quotient;
    o_remainder <= reg_remainder;

    -- @formatter:off
    with add_a_sel select add_sub_a <=
        (others => '0') when ADD_A_SEL_ZEROS,
        reg_quotient when ADD_A_SEL_QUOTIENT,
        reg_remainder when ADD_A_SEL_REMAINDER,
        twice_rem when ADD_A_SEL_TWICE_REMAINDER,
        (others => '0') when others;

    with add_b_sel select add_sub_b <=
        i_dividend when ADD_B_SEL_INPUT_DIVIDEND,
        reg_divisor when ADD_B_SEL_DIVISOR,
        reg_quotient when ADD_B_SEL_QUOTIENT,
        reg_divisor when others;
    -- @formatter:on

    XorLayer:
    for i in 0 to NBIT-1 generate
        add_sub_b_modified(i) <= add_sub_b(i) xor add_invert_b;
    end generate;


    AddSub: AdderP4
        generic map (NBIT => NBIT, NBIT_PER_BLOCK => 4)
        port map (
            A => add_sub_a,
            B => add_sub_b_modified,
            Ci => add_cin,

            S => add_sub_res,

            Cout => open
        );

    Counter: UpCounter
        generic map (NBIT => clog2(NBIT))
        port map (
            clk   => i_clk,
            rst_n => i_rst_n,

            enable    => counter_enable,

            terminal_count => counter_tc,
            count => open -- NOTE: We only need the terminal count

        );


    proc_NextIter:
    process (remainder_load, quotient_load, divisor_load, reg_remainder, reg_quotient, reg_divisor, add_sub_res, i_dividend, i_divisor, is_remainder_positive)
    begin
        case remainder_load is
            when REM_LOAD_NOTHING =>
                reg_remainder_next <= reg_remainder;
            when REM_LOAD_SUM =>
                reg_remainder_next <= add_sub_res;
            when REM_LOAD_ZEROS =>
                reg_remainder_next <= (others => '0');
            when REM_LOAD_ONES =>
                reg_remainder_next <= (others => '1');
            when others =>
                reg_remainder_next <= reg_remainder;
        end case;

        case quotient_load is
            when QUOT_LOAD_NOTHING =>
                reg_quotient_next <= reg_quotient;
            when QUOT_LOAD_SUM =>
                reg_quotient_next <= add_sub_res;
            when QUOT_LOAD_IN_DIVIDEND =>
                reg_quotient_next <= i_dividend;
            when QUOT_LOAD_SHIFT =>
                reg_quotient_next <= reg_quotient(NBIT-2 downto 0) & is_remainder_positive;
            when others =>
                reg_quotient_next <= reg_quotient;
        end case;

        case divisor_load is
            when DIV_LOAD_NOTHING =>
                reg_divisor_next <= reg_divisor;
            when DIV_LOAD_SUM =>
                reg_divisor_next <= add_sub_res;
            when DIV_LOAD_IN_DIVISOR =>
                reg_divisor_next <= i_divisor;
            when others =>
                reg_divisor_next <= reg_divisor;
        end case;

    end process;

    proc_FSM:
    process (state, i_start, counter_tc, i_dividend, i_divisor, reg_remainder, is_remainder_positive)
    begin
        state_next <= state;
        counter_enable <= '0';
        o_result_valid <= '0';


        add_a_sel <= ADD_A_SEL_ZEROS;
        add_b_sel <= ADD_B_SEL_DIVISOR;
        add_invert_b <= '0';
        add_cin <= '0';

        remainder_load <= REM_LOAD_NOTHING;
        quotient_load <= QUOT_LOAD_NOTHING;
        divisor_load <= DIV_LOAD_NOTHING;

        case state is
            when Idle =>
                -- Here we normalize the dividend
                add_a_sel <= ADD_A_SEL_ZEROS;
                add_b_sel <= ADD_B_SEL_INPUT_DIVIDEND;

                add_cin <= '1';
                add_invert_b <= '1';

                state_next <= Idle;

                if i_start = '1' then
                    if (i_dividend(NBIT-1) xor i_divisor(NBIT-1)) = '1' then
                        remainder_load <= REM_LOAD_ONES;
                    else
                        remainder_load <= REM_LOAD_ZEROS;
                    end if;

                    -- If divisor is negative, we invert both divisor and divivdend
                    -- to make the algorithm work.
                    if (i_divisor(NBIT-1) = '1') then
                        quotient_load <= QUOT_LOAD_SUM;
                        state_next <= InvertDivisor;
                    else
                        quotient_load <= QUOT_LOAD_IN_DIVIDEND;
                        state_next <= Dividing;
                    end if;
                end if;

                divisor_load <= DIV_LOAD_IN_DIVISOR;

            when InvertDivisor =>
                add_a_sel <= ADD_A_SEL_ZEROS;
                add_b_sel <= ADD_B_SEL_DIVISOR;

                add_cin <= '1';
                add_invert_b <= '1';

                divisor_load <= DIV_LOAD_SUM;

                state_next <= Dividing;
            when Dividing =>
                counter_enable <= '1';
                o_result_valid <= '0';

                add_a_sel <= ADD_A_SEL_TWICE_REMAINDER;
                add_b_sel <= ADD_B_SEL_DIVISOR;

                add_cin      <= not reg_remainder(NBIT-1);
                add_invert_b <= not reg_remainder(NBIT-1);

                quotient_load <= QUOT_LOAD_SHIFT;
                remainder_load <= REM_LOAD_SUM;


                if counter_tc = '1' then
                    state_next <= AdjustingQuotient;
                else
                    state_next <= Dividing;
                end if;
            when AdjustingQuotient =>
                if (is_remainder_positive) = '0' then
                    state_next <= AdjustingRemainder;
                else
                    state_next <= Done;
                end if;
                o_result_valid <= '0';

                -- Q := Q - (not Q) = Q - (not (not Q)) + 1 = Q + Q + 1
                add_a_sel <= ADD_A_SEL_QUOTIENT;
                add_b_sel <= ADD_B_SEL_QUOTIENT;


                -- if R < 0 then Q := Q - 1
                add_cin <= not reg_remainder(NBIT-1);
                add_invert_b <= '0';

                quotient_load <= QUOT_LOAD_SUM;

            when AdjustingRemainder =>
                state_next <= Done;
                o_result_valid <= '0';

                add_a_sel <= ADD_A_SEL_REMAINDER;
                add_b_sel <= ADD_B_SEL_DIVISOR;

                add_cin <= '0';
                add_invert_b <= '0';


                remainder_load <= REM_LOAD_SUM;

            when Done =>
                state_next <= Idle;
                o_result_valid <= '1';
            when others =>
                state_next <= Idle;
                o_result_valid <= '0';
        end case;
    end process;

    proc_UpdateRegisters:
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                reg_remainder <= (others => '0');
                reg_divisor  <= (others => '0');
                reg_quotient <= (others => '0');
                state <= Idle;
            else
                reg_remainder <= reg_remainder_next;
                reg_divisor <= reg_divisor_next;
                reg_quotient <= reg_quotient_next;

                state <= state_next;
            end if;
        end if;
    end process;

end Structural;

