library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package tb_utils is
    function to_bin_string (lvec: in std_logic_vector) return string;
    function to_hex_string (lvec: in std_logic_vector) return string;

    shared variable tb_util_seed1, tb_util_seed2: integer := 1;

    impure function random_stdvec(length: in integer) return std_logic_vector;
    impure function random_bool return boolean;
    impure function random_int(min: in integer; max: in integer) return integer;
end package;

package body tb_utils is
    impure function random_bool return boolean is
        variable r: real;
    begin
        uniform(tb_util_seed1, tb_util_seed2, r);

        return r > 0.5;
    end random_bool;

    impure function random_int(min: in integer; max: in integer) return integer is
        variable r: real;
    begin
        uniform(tb_util_seed1, tb_util_seed2, r);

        return integer(floor(r * real(max-min))) + min;
    end random_int;

    impure function random_stdvec(length: in integer) return std_logic_vector is
        variable r: real;
        variable vec: std_logic_vector(length-1 downto 0);
    begin
        for i in vec'range loop
            uniform(tb_util_seed1, tb_util_seed2, r);
            if r < 0.5 then
                vec(i) := '0';
            else
                vec(i) := '1';
            end if;
        end loop;
        return vec;
    end random_stdvec;

    function to_bin_string (lvec: in std_logic_vector) return string is
            variable text: string(1 to lvec'length) := (others => '9');
        begin
            for k in 1 to lvec'length loop
                case lvec(lvec'length - k) is
                    when '0' => text(k) := '0';
                    when '1' => text(k) := '1';
                    when 'U' => text(k) := 'U';
                    when 'X' => text(k) := 'X';
                    when 'Z' => text(k) := 'Z';
                    when '-' => text(k) := '-';
                    when others => text(k) := '?';
                end case;
            end loop;
        return text;
    end function;

    function to_hex_string (lvec: in std_logic_vector) return string is
        constant text_length: integer := integer(ceil(real(lvec'length) / 4.0));

        variable padded_vec: std_logic_vector(text_length*4-1 downto 0);

        variable text: string(1 to text_length) := (others => '9');
        subtype halfbyte is std_logic_vector(4-1 downto 0);

        variable nibble: std_logic_vector(3 downto 0); 
    begin
        padded_vec := std_logic_vector(resize(unsigned(lvec), text_length*4));

        for k in text'range loop
            nibble := padded_vec(4*(text'length-k)+3 downto 4*(text'length-k));
            case halfbyte'(nibble) is
                when "0000" => text(k) := '0';
                when "0001" => text(k) := '1';
                when "0010" => text(k) := '2';
                when "0011" => text(k) := '3';
                when "0100" => text(k) := '4';
                when "0101" => text(k) := '5';
                when "0110" => text(k) := '6';
                when "0111" => text(k) := '7';
                when "1000" => text(k) := '8';
                when "1001" => text(k) := '9';
                when "1010" => text(k) := 'A';
                when "1011" => text(k) := 'B';
                when "1100" => text(k) := 'C';
                when "1101" => text(k) := 'D';
                when "1110" => text(k) := 'E';
                when "1111" => text(k) := 'F';
                when others => text(k) := '!';
            end case;
        end loop;
        return text;
    end function;
end tb_utils;
