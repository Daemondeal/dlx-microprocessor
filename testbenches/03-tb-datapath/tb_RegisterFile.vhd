library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_RegisterFile is
end TB_RegisterFile;

architecture Testbench of TB_RegisterFile is
    component RegisterFile is
        generic (
            NBIT: integer := 32;
            NREG_SELECT: integer := 5;
            NREG: integer := 32
        );

        port (
            clk, enable, rst_n, write_enable: in std_logic;
            input: in std_logic_vector(NBIT-1 downto 0);
            select_in: in std_logic_vector(NREG_SELECT-1 downto 0);
            select_out1, select_out2: in std_logic_vector(NREG_SELECT-1 downto 0);
            output1, output2: out std_logic_vector(NBIT-1 downto 0)
        );
    end component RegisterFile;

    signal clk, rst_n, en, wr_en: std_logic;
    signal input, output1, output2: std_logic_vector(31 downto 0);
    signal sel_in, sel_out1, sel_out2: std_logic_vector(4 downto 0);

    constant ClockPeriod: time := 20 ns;
    signal sim_stopped: std_logic := '0';
begin
    DUT: RegisterFile
        generic map (
            NBIT => 32, NREG_SELECT => 5, NREG => 32
        )
        port map (
            clk => clk, rst_n => rst_n, enable => en, write_enable => wr_en,
            input => input, output1 => output1, output2 => output2,
            select_in => sel_in, select_out1 => sel_out1, select_out2 => sel_out2
        );

    CLK_PROC: process
    begin
        if sim_stopped = '0' then
            clk <= '0';
            wait for ClockPeriod/2;
            clk <= '1';
            wait for ClockPeriod/2;
        else
            wait;
        end if;
    end process CLK_PROC;

    TEST_PROC: process
    begin
        rst_n <= '0';
        en    <= '1';
        wr_en <= '0';

        sel_in <= "00000";
        sel_out1 <= "00000";
        sel_out2 <= "00000";

        input <= x"00000000";
        wait for ClockPeriod * 5/4;

        rst_n <= '1';
        wr_en <= '1';
        sel_in <= "01000";

        input <= x"DEADBEEF";

        wait for ClockPeriod;

        assert output1 = x"00000000";
        assert output2 = x"00000000";

        wr_en <= '1';
        sel_in <= "00001";
        input <= x"AABBCCDD";

        sel_out1 <= "01000";
        sel_out2 <= "00000";

        wait for ClockPeriod; 

        assert output1 = x"DEADBEEF";
        assert output2 = x"00000000";

        wr_en <= '0';
        sel_out2 <= "00001";

        wait for ClockPeriod;

        assert output1 = x"DEADBEEF";
        assert output2 = x"AABBCCDD";

        -- Try if all registers work
        wr_en <= '1';
        for i in 0 to 31 loop
            sel_in <= std_logic_vector(to_unsigned(i, 5));
            input <= std_logic_vector(to_unsigned(i, 32));
            wait for ClockPeriod;
        end loop;
        wr_en <= '0';

        for i in 0 to 31 loop
            sel_out1 <= std_logic_vector(to_unsigned(i, 5));
            sel_out2 <= std_logic_vector(to_unsigned(i, 5));

            wait for ClockPeriod;

            assert output1 = std_logic_vector(to_unsigned(i, 32));
            assert output2 = std_logic_vector(to_unsigned(i, 32));
        end loop;

        sel_out1 <= "00010";
        sel_out2 <= "00011";
        wait for ClockPeriod;

        -- Try enable low
        en <= '0';
        for i in 0 to 31 loop
            sel_out1 <= std_logic_vector(to_unsigned(i, 5));
            sel_out2 <= std_logic_vector(to_unsigned(i, 5));

            wait for ClockPeriod;

            assert output1 = x"00_00_00_02";
            assert output2 = x"00_00_00_03";
        end loop;

        wait for ClockPeriod;

        report "Simulation Finished!";
        sim_stopped <= '1';
        wait;
    end process TEST_PROC;
end Testbench;

