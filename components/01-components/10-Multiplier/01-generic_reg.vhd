library ieee;
use ieee.std_logic_1164.all;

entity generic_reg is
    generic (NBIT: integer:= 32);
    port (input: in std_logic_vector(NBIT-1 downto 0);
        output: out std_logic_vector(NBIT-1 downto 0);
        clk, rst_n: in std_logic);
end generic_reg;

architecture behavior of generic_reg is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                output<= (others => '0');
            else
                output<= input;
            end if;
        end if;
    end process;
end behavior;
