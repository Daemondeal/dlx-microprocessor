library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity UpCounter is
    generic (
        NBIT: integer := 8);
    port (
        clk:       in std_logic;
        rst_n:     in std_logic;
        enable:    in std_logic;

        terminal_count: out std_logic;
        count: out std_logic_vector(NBIT-1 downto 0));
end UpCounter;

architecture Behavioral of UpCounter is
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

    process (enable, count_reg)
        variable ones: unsigned(NBIT-1 downto 0);
    begin
        if enable = '1' then
            count_reg_next <= count_reg + 1;
        else
            count_reg_next <= count_reg;
        end if;

        ones := (others => '1');
        if count_reg = ones then
            terminal_count <= '1';
        else
            terminal_count <= '0';
        end if;
    end process;
end Behavioral;

