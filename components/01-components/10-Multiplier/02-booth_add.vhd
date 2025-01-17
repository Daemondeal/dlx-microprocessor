library ieee;
use ieee.std_logic_1164.all;

entity booth_add is
    generic (NBIT: integer:= 32);
    port (a: in  std_logic_vector(NBIT-1 downto 0); -- multiplicand
        b: in  std_logic_vector(2 downto 0);  -- Booth multiplier
        sum_in: in  std_logic_vector(NBIT-1 downto 0); -- sum input
        sum_out: out std_logic_vector(NBIT-1 downto 0); -- sum output
        p: out std_logic_vector(1 downto 0)); -- 2 bits of final result
end entity booth_add;

architecture behavior of booth_add is

    component  addsub_generic
        generic (NBIT: integer:= 32);
        port(    in_1 : in std_logic_vector(NBIT-1 downto 0);
            in_2 : in std_logic_vector(NBIT-1 downto 0);
            addsub : in std_logic_vector(0 downto 0);
            sum : out std_logic_vector(NBIT-1 downto 0);
            cout: out std_logic);
    end component;


    component fa
        Port(    A:    In    std_logic;
            B:    In    std_logic;
            Ci: In std_logic;
            S:    Out std_logic;
            Co: Out std_logic);
    end component;

    signal a2: std_logic_vector(NBIT-1 downto 0);
    signal mux_out: std_logic_vector(NBIT-1 downto 0);
    signal psum: std_logic_vector(NBIT-1 downto 0);
    signal addsubs: std_logic_vector(0 downto 0);

begin

    a2 <= a(NBIT-2 downto 0) & '0'; -- shift left by 1 (x2)

-- MUX 3 to 1 with encoder
    mux_out <= a when b="001" or b="010" or b="101" or b="110"
    else a2 when b="011" or b="100"
    else (others => '0');

-- ADD/SUB decider
    addsubs <= "1" when b="100" or b="101" or b="110"
    else (others => '0');

    ADDSUB: addsub_generic
        generic map (NBIT => NBIT)
        port map(
            in_1 => sum_in,
            in_2 => mux_out,
            addsub => addsubs,
            sum => psum,
            cout => open
        );

    sum_out(NBIT-3 downto 0) <= psum(NBIT-1 downto 2); -- input for next sum
    sum_out(NBIT-2) <= psum(NBIT-1); -- msb-1 for next sum
    sum_out(NBIT-1) <= psum(NBIT-1); -- msb for next sum

    p <= psum(1 downto 0); -- 2 bit of final result

end behavior;
