library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CarrySelect is
    generic (
        NBIT_PER_BLOCK: integer := 4
    );
    port (
        A, B: in std_logic_vector(NBIT_PER_BLOCK-1 downto 0);
        Ci: in std_logic;
        S: out std_logic_vector(NBIT_PER_BLOCK-1 downto 0)
    );
end CarrySelect;

architecture Behavioral of CarrySelect is
    component RCA is 
        generic (
            NBIT:  integer := 32
        );
        port (
            A:  in  std_logic_vector(NBIT-1 downto 0);
            B:  in  std_logic_vector(NBIT-1 downto 0);
            Ci: in  std_logic;
            S:  out std_logic_vector(NBIT-1 downto 0);
            Co: out std_logic);
    end component RCA; 

    component CarryLookaheadAdder4 is
        port (
            A:  in  std_logic_vector(3 downto 0);
            B:  in  std_logic_vector(3 downto 0);
            Ci: in  std_logic;
            S:  out std_logic_vector(3 downto 0));
    end component CarryLookaheadAdder4;

    signal S_C0, S_C1: std_logic_vector(NBIT_PER_BLOCK-1 downto 0);
begin

    CarryLookaheadOptimized:
    if NBIT_PER_BLOCK = 4 generate
        Sum_Cin0 : CarryLookaheadAdder4
            port map (
                     A => A,
                     B => B,
                     Ci => '0',
                     S => S_C0
                 );

        Sum_Cin1 : CarryLookaheadAdder4
            port map (
                     A => A,
                     B => B,
                     Ci => '1',
                     S => S_C1
                 );

        S <= S_C0 when Ci = '0' else S_C1;
    end generate;

    UnoptimizedRCA:
    if NBIT_PER_BLOCK /= 4 generate
        Sum_Cin0 : RCA 
            generic map (NBIT => NBIT_PER_BLOCK)
            port map (
                     A => A,
                     B => B,
                     Ci => '0',
                     S => S_C0,
                     Co => open
                 );

        Sum_Cin1 : RCA 
            generic map (NBIT => NBIT_PER_BLOCK)
            port map (
                     A => A,
                     B => B,
                     Ci => '1',
                     S => S_C1,
                     Co => open
                 );

        S <= S_C0 when Ci = '0' else S_C1;
    end generate;
end Behavioral;

