library ieee;
use ieee.std_logic_1164.all;

entity CarryLookaheadAdder4 is
    port (
        A:  in  std_logic_vector(3 downto 0);
        B:  in  std_logic_vector(3 downto 0);
        Ci: in  std_logic;
        S:  out std_logic_vector(3 downto 0));
end CarryLookaheadAdder4;

architecture Structural of CarryLookaheadAdder4 is
    signal g: std_logic_vector(3 downto 0);
    signal p: std_logic_vector(3 downto 0);
    signal c: std_logic_vector(2 downto 0);
begin

    g <= A and B;
    p <= A xor B;

    -- Manual Carry Lookahead Structure

    c(0) <= g(0) or (Ci and p(0));

    c(1) <= g(1) or (g(0) and p(1))
                 or (Ci and p(0) and p(1));

    c(2) <= g(2) or (g(1) and p(2))
                 or (g(0) and p(1) and p(2))
                 or (Ci and p(0) and p(1) and p(2));


    S(0) <= p(0) xor Ci;
    S(1) <= p(1) xor c(0);
    S(2) <= p(2) xor c(1);
    S(3) <= p(3) xor c(2);

end Structural;

