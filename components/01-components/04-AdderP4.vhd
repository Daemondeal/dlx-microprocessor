library ieee;
use ieee.std_logic_1164.all;

entity AdderP4 is
    generic (
        NBIT: integer := 32;
        NBIT_PER_BLOCK: integer := 4
    );
    port (
        A, B: in std_logic_vector(NBIT - 1 downto 0);
        Ci: in std_logic;

        S: out std_logic_vector(NBIT - 1 downto 0);
        Cout: out std_logic
    );
end AdderP4;

architecture Structural of AdderP4 is
    component CarryGenerator is
        generic (
            NBIT :        integer := 32;
            NBIT_PER_BLOCK: integer := 4);
        port (
            A: in std_logic_vector(NBIT-1 downto 0);
            B: in std_logic_vector(NBIT-1 downto 0);
            Cin: in std_logic;
            Co:  out std_logic_vector((NBIT/NBIT_PER_BLOCK)-1 downto 0));
    end component CarryGenerator;

    component SumGenerator is
        generic (
            NBIT_PER_BLOCK: integer := 4;
            NBLOCKS:        integer := 8);
        port (
            A:  in  std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
            B:  in  std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0);
            Ci: in  std_logic_vector(NBLOCKS-1 downto 0);
            S:  out std_logic_vector(NBIT_PER_BLOCK*NBLOCKS-1 downto 0));
    end component SumGenerator;

    constant CARRY_NUMBER: integer := NBIT/NBIT_PER_BLOCK;

    signal sum_generator_ci: std_logic_vector(CARRY_NUMBER-1 downto 0);
    signal carry_generated: std_logic_vector(CARRY_NUMBER-1 downto 0);

begin
    CarryGenerator_Instance: CarryGenerator
        generic map (
            NBIT => NBIT,
            NBIT_PER_BLOCK => NBIT_PER_BLOCK)
        port map (
            A => A,
            B => B,
            Cin => Ci,
            Co => carry_generated 
        );

    sum_generator_ci <= carry_generated(CARRY_NUMBER-2 downto 0) & Ci;

    GenerateSum: SumGenerator
        generic map (
            NBLOCKS => NBIT/NBIT_PER_BLOCK,
            NBIT_PER_BLOCK => NBIT_PER_BLOCK)
        port map (
            A => A,
            B => B,
            Ci => sum_generator_ci,
            S => S
        );

    Cout <= carry_generated(CARRY_NUMBER-1);
end Structural;

