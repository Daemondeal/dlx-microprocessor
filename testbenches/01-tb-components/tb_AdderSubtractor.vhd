library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_utils.all;

entity tb_AdderSubtractor is
end entity tb_AdderSubtractor;

architecture tb of tb_AdderSubtractor is
    constant NBIT: integer := 32;
    constant LOOPS: integer := 20000;

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

    signal s_operand_a, s_operand_b, s_result: std_logic_vector(NBIT-1 downto 0);

    signal s_sub_add_n: std_logic;
    signal s_cout, s_overflow, s_zero, s_negative: std_logic;
begin

    DUT: AdderSubtractor
        generic map (
            NBIT => NBIT,
            NBIT_PER_BLOCK => 4)
        port map (
            i_operand_a => s_operand_a,
            i_operand_b => s_operand_b,
            o_result => s_result,

            i_sub_add_n => s_sub_add_n,

            o_carry_out => s_cout,
            o_overflow => s_overflow,
            o_zero => s_zero,
            o_negative => s_negative
        );

    TestProc: process
        variable a, b: unsigned(NBIT-1 downto 0);
        variable res: unsigned(NBIT downto 0);

        variable signed_a, signed_b, signed_res: signed(NBIT-1 downto 0);
    begin
        s_sub_add_n <= '0';
        for i in 0 to LOOPS loop
            a := unsigned(random_stdvec(NBIT));
            b := unsigned(random_stdvec(NBIT));


            s_operand_a <= std_logic_vector(a);
            s_operand_b <= std_logic_vector(b);

            if random_bool then
                s_sub_add_n <= '0';
                res := ('0' & a) + ('0' & b);
            else
                s_sub_add_n <= '1';
                res := ('0' & a) - ('0' & b);
            end if;

            wait for 1 ns;
            signed_a   := signed(s_operand_a);
            signed_b   := signed(s_operand_b);
            signed_res := signed(s_result);


            if res(NBIT-1 downto 0) = 0 then
                assert s_zero = '1'
                    report "Zero flag should be set";
            else
                assert s_zero = '0'
                    report "Zero flag should not be set";
            end if;

            assert unsigned(s_result) = res(NBIT-1 downto 0)
                report "Invalid result. Expected """ 
                    & to_hex_string(std_logic_vector(res(NBIT-1 downto 0)))
                    & """ but got """ & to_hex_string(s_result) & """";

            assert s_cout = (res(NBIT) xor s_sub_add_n)
                report "Invalid Carry Out";

            if signed_res < 0 then
                assert s_negative = '1'
                    report "Expected negative flag to be set for signed negative results";
            else
                assert s_negative = '0'
                    report "Expected negative flag to be clear for signed positive results";
            end if;

            if s_sub_add_n = '0' then
                if ((signed_a < 0) and (signed_b < 0) and (signed_res > 0))
                    or ((signed_a > 0) and (signed_b > 0) and (signed_res < 0)) then
                    assert s_overflow = '1'
                        report """" & to_hex_string(std_logic_vector(signed_a)) & """ + """ 
                         & to_hex_string(std_logic_vector(signed_b)) & """ should give the overfow flag, but didn't";
                else
                    assert s_overflow = '0'
                        report "Invalid overflow flag (shuold be zero)";
                end if;
            else
                if (signed_a < 0 and signed_b > 0 and signed_res > 0)
                    or (signed_a > 0 and signed_b < 0 and signed_res < 0) then

                    assert s_overflow = '1'
                        report "Invalid overflow flag (should be one)";
                else
                    assert s_overflow = '0'
                        report "Invalid overflow flag (shuold be zero)";
                end if;
            end if;
        wait for 1 ns;


        end loop;


        report "Simulation Finshed";
        wait;
    end process TestProc;
end tb;

