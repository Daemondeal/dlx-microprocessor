library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity tb_UpCounter is
end tb_UpCounter;

architecture tb of tb_UpCounter is
    component UpCounter is
        generic (
            NBIT: integer := 8);
        port (
            clk:      in std_logic;
            rst_n:    in std_logic;
            enable:   in std_logic;

            terminal_count: out std_logic;
            count: out std_logic_vector(NBIT-1 downto 0));
    end component;

    signal clk, rst_n, en, tc: std_logic;
    signal count: std_logic_vector(7 downto 0);

    constant ClockPeriod: time := 1 ns;
    constant NBIT: integer := 8;
    signal sim_stopped: std_logic := '0';

begin
    DUT: UpCounter
        generic map (
            NBIT => 8
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            enable => en,

            terminal_count => tc,
            count => count);

    process
        variable prev_count: std_logic_vector(7 downto 0);
        variable prev_tc: std_logic;
    begin
        rst_n <= '0';
        en <= '1';

        wait for ClockPeriod * 5/4;
        assert count = x"00" report "Should reset";
        rst_n <= '1';

        for i in 1 to 531 loop
            wait until falling_edge(clk);

            assert_CorrectCount:
            assert count = std_logic_vector(to_unsigned(i mod 2**NBIT, NBIT));

            if (i mod 2**NBIT) = 2**NBIT-1 then
                assert_TerminalCountTrue:
                assert tc = '1';
            else
                assert_TerminalCountFalse:
                assert tc = '0';
            end if;

            prev_count := count;
            prev_tc := tc;
        end loop;

        en <= '0';
        for i in 0 to 123 loop
            wait until falling_edge(clk);
            assert_EnableCount:
            assert count = prev_count;
            assert_EnableTerminalCount:
            assert tc = prev_tc;
        end loop;


        rst_n <= '1';

        wait until rising_edge(clk);
        sim_stopped <= '1';

        wait;
    end process;

    process
    begin
        if sim_stopped = '0' then
            clk <= '0';
            wait for ClockPeriod/2;
            clk <= '1';
            wait for ClockPeriod/2;
        else
            wait;
        end if;
    end process;


end tb;
