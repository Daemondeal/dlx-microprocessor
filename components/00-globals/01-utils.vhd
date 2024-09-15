library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package utils is
    function clog2(x: integer) return integer;
    function max(x: integer; y: integer) return integer;

end package;

package body utils is
    function max(x: integer; y: integer) return integer is
    begin
        if x > y then
            return x;
        else
            return y;
        end if;
    end max;

    function clog2(x: integer) return integer is
    begin
        return integer(ceil(log2(real(x))));
    end clog2;

end utils;

