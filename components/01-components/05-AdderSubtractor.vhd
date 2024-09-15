library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AdderSubtractor is
    generic (
        NBIT: integer := 32;
        NBIT_PER_BLOCK: integer := 4
    );
    port (
        i_operand_a: in  std_logic_vector(NBIT-1 downto 0);
        i_operand_b: in  std_logic_vector(NBIT-1 downto 0);
        o_result:    out std_logic_vector(NBIT-1 downto 0);

        i_sub_add_n: in  std_logic;

        o_carry_out: out std_logic;
        o_overflow:  out std_logic;
        o_zero:      out std_logic;
        o_negative:  out std_logic
    );
end AdderSubtractor;

architecture Structural of AdderSubtractor is
    component AdderP4 is
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
    end component AdderP4;

    signal result, modified_b: std_logic_vector(NBIT-1 downto 0);
    signal carry_out: std_logic;
begin
    XorLayer: for i in 0 to NBIT-1 generate
        modified_b(i) <= i_operand_b(i) xor i_sub_add_n;
    end generate;

    Adder: AdderP4
        generic map (
            NBIT => NBIT,
            NBIT_PER_BLOCK => NBIT_PER_BLOCK
        )
        port map (
            A => i_operand_a,
            B => modified_b,
            Ci => i_sub_add_n,

            S => result,
            Cout => carry_out
        );


    o_result    <= result;
    o_carry_out <= carry_out;
    o_zero      <= '1' when (unsigned(result) = 0) else '0';
    o_overflow  <= carry_out xor i_operand_a(NBIT-1) xor modified_b(NBIT-1) xor result(NBIT-1);
    o_negative  <= result(NBIT-1);
end Structural;

