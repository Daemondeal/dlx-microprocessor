library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

use work.tb_utils.all;

entity TB_Divider is
end TB_Divider;

architecture tb of TB_Divider is
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

    signal clk: std_logic := '0';
    signal rst_n: std_logic := '1';

    signal s_dividend, s_divisor, s_quotient, s_remainder: std_logic_vector(31 downto 0);
    signal s_start, s_result_valid: std_logic;

    signal sim_stopped: std_logic := '0';

    constant ClockPeriod: time := 1.5 ns;
begin

    DUT: Divider
        generic map(
            NBIT => 32
        )
        port map(
            i_clk => clk,
            i_rst_n => rst_n,
            i_dividend => s_dividend,
            i_divisor => s_divisor,
            i_start => s_start,
            o_quotient => s_quotient,
            o_remainder => s_remainder,
            o_result_valid => s_result_valid
        );

    TestProcess: process

        variable t_dividend, t_divisor, t_quotient, t_remainder: std_logic_vector(31 downto 0);
        file testvec_fp: text;
        variable testvec_line: line;
    begin
        -- Initialize all signals here
        s_divisor <= (others => '0');
        s_dividend <= (others => '0');
        s_start <= '0';
        rst_n <= '0';
        wait for ClockPeriod;
        rst_n <= '1';



        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        file_open(testvec_fp, "./testvectors/division.mem", READ_MODE);
        while (not endfile(testvec_fp)) loop
            readline(testvec_fp, testvec_line);
            hread(testvec_line, t_dividend);

            readline(testvec_fp, testvec_line);
            hread(testvec_line, t_divisor);

            readline(testvec_fp, testvec_line);
            hread(testvec_line, t_quotient);

            readline(testvec_fp, testvec_line);
            hread(testvec_line, t_remainder);

            s_dividend <= t_dividend;
            s_divisor <= t_divisor;
            s_start <= '1';
            wait until rising_edge(clk);
            s_start <= '0';

            while s_result_valid = '0' loop
                wait until falling_edge(clk);
            end loop;

            assert_Quotient:
            assert s_quotient = t_quotient;
            assert_Remainder:
            assert s_remainder = t_remainder;

            wait until rising_edge(clk);
        end loop;

        file_close(testvec_fp);

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

