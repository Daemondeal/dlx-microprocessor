library ieee;
use ieee.std_logic_1164.all;

entity BlockPG is
    port (
        Pik, Gik: in std_logic;
        Pkpj, Gkpj: in std_logic;
        Gij, Pij: out std_logic);
end BlockPG;

architecture Behavioral of BlockPG is
begin
    Gij <= Gik or (Pik and Gkpj);
    Pij <= Pik and Pkpj;
end Behavioral;

