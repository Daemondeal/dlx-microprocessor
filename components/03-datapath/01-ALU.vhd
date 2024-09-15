library ieee;

use ieee.std_logic_1164.all;

use work.constants.all;

entity ALU is
    generic (
        NBIT: integer := 32);
    port (
        i_operation: in AluOperationType;
        i_in1, i_in2: in std_logic_vector(NBIT-1 downto 0);
        o_result: out std_logic_vector(NBIT-1 downto 0)
    );
end entity ALU;

architecture Structural of ALU is
    component Shifter is
        generic (
            NBIT:               integer := 32;
            NBIT_MASKS:         integer := 40;
            NBIT_BASIC_SHIFT:   integer := 8
        );
        port (
            data_in:          in std_logic_vector(NBIT-1 downto 0);
            selection_signal: in std_logic_vector(NBIT-1 downto 0);
            type_of_shift:    in ShiftType;

            data_out:         out std_logic_vector(NBIT-1 downto 0)
        );
    end component Shifter;

    component AdderSubtractor is
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
    end component AdderSubtractor;

    signal add_sub_res: std_logic_vector(NBIT-1 downto 0);
    signal shifter_res: std_logic_vector(NBIT-1 downto 0);
    signal sub_add_n: std_logic;
    signal shift_op: ShiftType;

    signal flag_cout, flag_overflow, flag_zero, flag_negative: std_logic;
begin

    AddSub: AdderSubtractor
        generic map (
            NBIT => NBIT,
            NBIT_PER_BLOCK => 4
        )
        port map (
            i_operand_a => i_in1,
            i_operand_b => i_in2,

            o_result => add_sub_res,

            i_sub_add_n => sub_add_n,

            o_carry_out => flag_cout,
            o_overflow => flag_overflow,
            o_zero => flag_zero,
            o_negative => flag_negative
        );

    Shift: Shifter
        generic map(
            NBIT => NBIT,
            NBIT_MASKS => 40,
            NBIT_BASIC_SHIFT => 8
        )
        port map(
            data_in => i_in1,
            selection_signal => i_in2,
            type_of_shift => shift_op,
            data_out => shifter_res
        );

    process (add_sub_res, flag_cout, flag_overflow, flag_zero, flag_negative, i_operation, i_in1, i_in2, shifter_res)
    begin
        sub_add_n <= '0';
        o_result <= (others => '0');
        shift_op <= shift_left_l;

        case i_operation is
            when alu_nop =>
                o_result <= i_in1;
            when alu_add =>
                o_result <= add_sub_res;
            when alu_sub =>
                sub_add_n <= '1';
                o_result <= add_sub_res;
            when alu_sll =>
                shift_op <= shift_left_l;
                o_result <= shifter_res;
            when alu_srl =>
                shift_op <= shift_right_l;
                o_result <= shifter_res;
            when alu_sra =>
                shift_op <= shift_right_a;
                o_result <= shifter_res;
            when alu_and =>
                o_result <= i_in1 and i_in2;
            when alu_xor =>
                o_result <= i_in1 xor i_in2;
            when alu_or =>
                o_result <= i_in1 or  i_in2;
            when alu_seq =>
                sub_add_n <= '1';
                o_result(0) <= flag_zero;
            when alu_sne =>
                sub_add_n <= '1';
                o_result(0) <= not flag_zero;
            when alu_sge =>
                sub_add_n <= '1';
                o_result(0) <= not (flag_negative xor flag_overflow);
            when alu_sgeu =>
                sub_add_n <= '1';
                o_result(0) <= flag_cout;
            when alu_sgt =>
                sub_add_n <= '1';
                o_result(0) <= (not flag_zero) and (not (flag_negative xor flag_overflow));
            when alu_sgtu =>
                sub_add_n <= '1';
                o_result(0) <= flag_cout and (not flag_zero);
            when alu_sle =>
                sub_add_n <= '1';
                o_result(0) <= flag_zero or (flag_negative xor flag_overflow);
            when alu_sleu =>
                sub_add_n <= '1';
                o_result(0) <= (not flag_cout) or (flag_zero);
            when alu_slt =>
                sub_add_n <= '1';
                o_result(0) <= flag_negative xor flag_overflow;
            when alu_sltu =>
                sub_add_n <= '1';
                o_result(0) <= not flag_cout;
            when alu_lhi =>
                o_result(NBIT/2-1 downto 0) <= (others => '0');
                -- Need to take in in2 since this op works with immediates
                o_result(NBIT-1 downto NBIT/2) <= i_in2(NBIT/2-1 downto 0);
            when others =>

        end case;
    end process;


end Structural;
