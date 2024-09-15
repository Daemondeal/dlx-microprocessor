library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity CarryGenerator is
    generic (
        NBIT :        integer := 32;
        NBIT_PER_BLOCK: integer := 4);
    port (
        A: in std_logic_vector(NBIT-1 downto 0);
        B: in std_logic_vector(NBIT-1 downto 0);
        Cin: in std_logic;
        Co:  out std_logic_vector((NBIT/NBIT_PER_BLOCK)-1 downto 0));
end entity CarryGenerator;

architecture Structural of CarryGenerator is
    component BlockG is
        port (
            Pik, Gik: in std_logic;
            Gkpj: in std_logic;
            Gij: out std_logic);
    end component BlockG;

    component BlockPG is
        port (
            Pik, Gik: in std_logic;
            Pkpj, Gkpj: in std_logic;
            Gij, Pij: out std_logic);
    end component BlockPG;

    type SignalVector is array(NBIT-1 downto 0) of std_logic_vector(NBIT-1 downto 0);
    signal temp_p, temp_g: SignalVector;

    constant layers: integer := integer(ceil(log2(real(NBIT))));
    signal first_p, first_g: std_logic;

begin

    temp_p(0) <= A xor B;
    temp_g(0)(NBIT-1 downto 1) <= A(NBIT-1 downto 1) and B(NBIT-1 downto 1);

    first_p <= A(0) xor B(0);
    first_g <= A(0) and B(0);

    FirstBlock: BlockG
        port map (
            Pik => first_p,
            Gik => first_g,

            Gkpj => Cin,
            Gij => temp_g(0)(0)
        );

    LayerGen: for layer in 1 to layers generate
        constant step: integer := 2 ** layer;
    begin

        StepCheck: if step <= NBIT_PER_BLOCK generate
            FirstStep: for n in 0 to (NBIT / step)-1 generate
                Original: if n = 0 generate
                    CurBlock: BlockG
                    port map (
                         Pik  => temp_p(layer-1)(n * 2 + 1),
                         Gik  => temp_g(layer-1)(n * 2 + 1),

                         Gkpj => temp_g(layer-1)(n * 2),

                         Gij  => temp_g(layer)(n)
                     );
                end generate;
                Copies: if n > 0 generate
                    CurBlock: BlockPG
                    port map (
                         Pik  => temp_p(layer-1)(n * 2 + 1),
                         Gik  => temp_g(layer-1)(n * 2 + 1),

                         Pkpj => temp_p(layer-1)(n * 2),
                         Gkpj => temp_g(layer-1)(n * 2),

                         Pij  => temp_p(layer)(n),
                         Gij  => temp_g(layer)(n)
                     );
                end generate;
            end generate;
        end generate;

        -- VHDL before 2008 does not support else generate
        StepCheckElse: if step > NBIT_PER_BLOCK generate
            SecondStep: for n in 0 to (NBIT / NBIT_PER_BLOCK) - 1 generate
                constant idx_sym: integer := (n * NBIT_PER_BLOCK) mod step;
            begin
                Bypass: if idx_sym < step / 2 generate
                    temp_p(layer)(n) <= temp_p(layer - 1)(n);
                    temp_g(layer)(n) <= temp_g(layer - 1)(n);
                end generate;

                NotBypass: if idx_sym >= step / 2 generate
                    constant last: integer := n * NBIT_PER_BLOCK - idx_sym + (step / 2);
                    constant last_idx: integer := last / NBIT_PER_BLOCK - 1;
                begin
                    Original: if (n * NBIT_PER_BLOCK) < step generate
                        CurBlock: BlockG
                        port map (
                             Pik  => temp_p(layer-1)(n),
                             Gik  => temp_g(layer-1)(n),

                             Gkpj => temp_g(layer-1)(last_idx),

                             Gij  => temp_g(layer)(n)
                         );
                    end generate;

                    Copies: if (n * NBIT_PER_BLOCK) >= step generate
                        CurBlock: BlockPG
                        port map (
                             Pik  => temp_p(layer-1)(n),
                             Gik  => temp_g(layer-1)(n),

                             Pkpj => temp_p(layer-1)(last_idx),
                             Gkpj => temp_g(layer-1)(last_idx),

                             Pij  => temp_p(layer)(n),
                             Gij  => temp_g(layer)(n)
                         );
                    end generate;
                end generate;
            end generate;
        end generate;
    end generate;

    Co <= temp_g(layers)((NBIT/NBIT_PER_BLOCK)-1 downto 0);

end Structural;

