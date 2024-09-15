library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_utils.all;
use work.constants.all;

entity tb_Shifter is
end entity tb_Shifter;

architecture tb of tb_Shifter is
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
    end component;

    constant NBIT: integer := 32;

    signal s_shift_op: ShiftType;
    signal s_in1, s_in2, s_result: std_logic_vector(NBIT-1 downto 0);

    signal integer_selection: integer;

    constant TEST_CYCLES: integer := 1000;
begin

    integer_selection <= to_integer(unsigned(s_in2(4 downto 0)));

    ShifterInstance: Shifter
        generic map (
            NBIT => 32,
            NBIT_MASKS => 40,
            NBIT_BASIC_SHIFT => 8
        )
        port map  (
            type_of_shift => s_shift_op,
            data_in => s_in1,
            selection_signal => s_in2,
            data_out => s_result
        );

    TestProc: process
    begin
        s_shift_op <= shift_left_l;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_result = std_logic_vector(unsigned(s_in1) sll integer_selection)
            report "Wrong shift left";
            wait for 1 ns;
        end loop;

        s_shift_op <= shift_right_l;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_result = std_logic_vector(unsigned(s_in1) srl integer_selection)
            report "Wrong shift right logical";
            wait for 1 ns;
        end loop;

        s_shift_op <= shift_right_a;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_result = to_stdlogicvector(to_bitvector(s_in1) sra integer_selection)
            report "Wrong shift right arithmetic";
            wait for 1 ns;
        end loop;

        wait;
    end process TestProc;

end tb;
