library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_utils.all;
use work.constants.all;

entity tb_Alu is
end entity tb_Alu;

architecture tb of tb_Alu is
    component ALU is
        generic (
            NBIT: integer := 32);
        port (
            i_operation: in AluOperationType;
            i_in1, i_in2: in std_logic_vector(NBIT-1 downto 0);
            o_result: out std_logic_vector(NBIT-1 downto 0)
        );
    end component ALU;

    constant NBIT: integer := 32;

    signal s_op: AluOperationType;
    signal s_in1, s_in2, s_res: std_logic_vector(NBIT-1 downto 0);

    signal in1_unsigned, in2_unsigned, res_unsigned: unsigned(NBIT-1 downto 0);
    signal in1_signed, in2_signed, res_signed: signed(NBIT-1 downto 0);

    constant TEST_CYCLES: integer := 1000;
begin

    in1_unsigned <= unsigned(s_in1);
    in2_unsigned <= unsigned(s_in2);
    res_unsigned <= unsigned(s_res);

    in1_signed <= signed(s_in1);
    in2_signed <= signed(s_in2);
    res_signed <= signed(s_res);

    AluInstance: ALU
        generic map (
            NBIT => 32
        )
        port map  (
            i_operation => s_op,
            i_in1 => s_in1,
            i_in2 => s_in2,
            o_result => s_res
        );

    TestProc: process
        variable zeros: std_logic_vector(30 downto 0) := (others => '0');
        function to_sl(input: in boolean) return std_logic is
        begin
            if input then
                return '1';
            else
                return '0';
            end if;
        end function to_sl;

        variable shift_amount: integer;
    begin
        zeros := (others => '0');
        s_op <= alu_nop;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res = s_in1
                report "Invalid nop op";
            wait for 1 ns;
        end loop;

        s_op <= alu_add;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert res_signed = in1_signed + in2_signed
                report "Invalid add op";
            wait for 1 ns;
        end loop;

        s_op <= alu_sub;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert res_signed = in1_signed - in2_signed
                report "Invalid sub op";
            wait for 1 ns;
        end loop;

        s_op <= alu_sll;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            shift_amount := to_integer(in2_unsigned(4 downto 0));
            assert res_unsigned = in1_unsigned sll shift_amount
                report "Invalid sll op";
            wait for 1 ns;
        end loop;

        s_op <= alu_srl;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            shift_amount := to_integer(in2_unsigned(4 downto 0));
            assert res_unsigned = in1_unsigned srl shift_amount
                report "Invalid srl op";
            wait for 1 ns;
        end loop;

        s_op <= alu_sra;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            shift_amount := to_integer(in2_unsigned(4 downto 0));
            -- NOTE: sra is unsupported for unsigned numbers, but supported
            --       for bit vectors.
            assert res_unsigned = unsigned(to_stdlogicvector(to_bitvector(s_in1) sra shift_amount))
                report "Invalid sra op";
            wait for 1 ns;
        end loop;

        s_op <= alu_and;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res = (s_in1 and s_in2)
                report "Invalid and op";
            wait for 1 ns;
        end loop;

        s_op <= alu_xor;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res = (s_in1 xor s_in2)
                report "Invalid xor op";
            wait for 1 ns;
        end loop;

        s_op <= alu_or;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res = (s_in1 or s_in2)
                report "Invalid or op";
            wait for 1 ns;
        end loop;

        s_op <= alu_seq;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(s_in1 = s_in2)
                report "Invalid seq op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_sne;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(s_in1 /= s_in2)
                report "Invalid sne op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_sge;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(in1_signed >= in2_signed)
                report "Invalid sge op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_sgeu;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(in1_unsigned >= in2_unsigned)
                report "Invalid sgeu op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_sgt;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(in1_signed > in2_signed)
                report "Invalid sgt op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_sgtu;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(in1_unsigned > in2_unsigned)
                report "Invalid sgtu op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_sle;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(in1_signed <= in2_signed)
                report "Invalid sle op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_sleu;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(in1_unsigned <= in2_unsigned)
                report "Invalid sleu op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_slt;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(in1_signed < in2_signed)
                report "Invalid slt op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_sltu;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(0) = to_sl(in1_unsigned < in2_unsigned)
                report "Invalid sltu op";
            assert s_res(31 downto 1) = zeros;
            wait for 1 ns;
        end loop;

        s_op <= alu_lhi;

        for i in 0 to TEST_CYCLES loop
            s_in1 <= random_stdvec(32);
            s_in2 <= random_stdvec(32);
            wait for 1 ns;

            assert s_res(15 downto 0) = x"00_00"
                report "Invalid lhi";
            assert s_res(31 downto 16) = s_in2(15 downto 0)
                report "Invalid lhi";
            wait for 1 ns;
        end loop;
        wait;
    end process TestProc;


end tb;
