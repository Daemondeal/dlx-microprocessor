library ieee;
use ieee.std_logic_1164.all;

entity FlipFlop is
    port (
        input: in std_logic;
        output: out std_logic;
        clk, rst_n: in std_logic);
end FlipFlop;

architecture Behavioral of FlipFlop is
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                output <= '0';
            else
                output <= input;
            end if;
        end if;
    end process;
end Behavioral;

