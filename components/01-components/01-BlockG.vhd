library ieee;
use ieee.std_logic_1164.all;

entity BlockG is
    port (
        Pik, Gik: in std_logic;
        Gkpj: in std_logic;
        Gij: out std_logic);
end BlockG;

architecture Behavioral of BlockG is
begin
    Gij <= Gik or (Pik and Gkpj);
end Behavioral;

