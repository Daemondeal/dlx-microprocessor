library ieee;
use ieee.std_logic_1164.all;

entity SumGenerator is
    generic (
        NBIT_PER_BLOCK: integer := 4;
        NBLOCKS:        integer := 8);
    port (
        A:  in  std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
        B:  in  std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
        Ci: in  std_logic_vector(NBLOCKS-1 downto 0);
        S:  out std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0));
end SumGenerator;

architecture Structural of SumGenerator is
    component CarrySelect is
        generic (
            NBIT_PER_BLOCK: integer := 4
        );
        port (
            A, B: in std_logic_vector(NBIT_PER_BLOCK-1 downto 0);
            Ci: in std_logic;
            S: out std_logic_vector(NBIT_PER_BLOCK-1 downto 0)
        );
    end component CarrySelect;

begin
    SelectChain: for i in 0 to NBLOCKS-1 generate 
        SelectBlock: CarrySelect 
            generic map (NBIT_PER_BLOCK => NBIT_PER_BLOCK)
            port map (
                A => A((i+1)*NBIT_PER_BLOCK-1 downto i*NBIT_PER_BLOCK),
                B => B((i+1)*NBIT_PER_BLOCK-1 downto i*NBIT_PER_BLOCK),
                Ci => Ci(i),
                S => S((i+1)*NBIT_PER_BLOCK-1 downto i*NBIT_PER_BLOCK)
            );
    end generate;
end Structural;
