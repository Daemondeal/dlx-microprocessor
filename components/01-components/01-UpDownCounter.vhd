library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity UpDownCounter is
    generic (
        NBIT: integer := 8);
    port (
        clk:       in std_logic;
        rst_n:     in std_logic;
        enable:    in std_logic;
        up_ndown:  in std_logic;
        max_count: in std_logic_vector(NBIT-1 downto 0);

        terminal_count: out std_logic;
        count: out std_logic_vector(NBIT-1 downto 0));
end UpDownCounter;

architecture Behavioral of UpDownCounter is
    signal count_reg, count_reg_next: unsigned(NBIT-1 downto 0);
begin
    count <= std_logic_vector(count_reg);

    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                count_reg <= (others => '0');
            else
                count_reg <= count_reg_next;
            end if;
        end if;
    end process;

    process (enable, up_ndown, count_reg, max_count)
    begin
        if enable = '1' then
            if up_ndown = '1' then
                if count_reg = unsigned(max_count) then
                    count_reg_next <= (others => '0');
                else
                    count_reg_next <= count_reg + 1;
                end if;
            else
                if count_reg = 0 then
                    count_reg_next <= unsigned(max_count);
                else
                    count_reg_next <= count_reg - 1;
                end if;
            end if;
        else
            count_reg_next <= count_reg;
        end if;

        if up_ndown = '1' then
            if count_reg = unsigned(max_count) then
                terminal_count <= '1';
            else
                terminal_count <= '0';
            end if;
        else
            if count_reg = 0 then
                terminal_count <= '1';
            else
                terminal_count <= '0';
            end if;
        end if;
    end process;
end Behavioral;

