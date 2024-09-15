library ieee;
use ieee.std_logic_1164.all;

entity RCA is
    generic (
        NBIT:  integer := 32
    );
    port (
        A:  in  std_logic_vector(NBIT-1 downto 0);
        B:  in  std_logic_vector(NBIT-1 downto 0);
        Ci: in  std_logic;
        S:  out std_logic_vector(NBIT-1 downto 0);
        Co: out std_logic);
end RCA;

architecture Structural of RCA is
    signal carry_vec: std_logic_vector(NBIT downto 0);
begin
    carry_vec(0) <= Ci;
    Co <= carry_vec(NBIT);

    AdderStructure: for i in 0 to NBIT-1 generate
        carry_vec(i+1) <= (A(i) and B(i)) or (A(i) and carry_vec(i)) or (B(i) and carry_vec(i));
        S(i) <= A(i) xor B(i) xor carry_vec(i);
    end generate;

end Structural;

