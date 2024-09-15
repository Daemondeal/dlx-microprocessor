library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity  addsub_generic is      --add a xor chain to RCA, implementing addition (0) or subtraction (1)
  generic (NBIT: integer := 32);
  port(  in_1 : in std_logic_vector(NBIT-1 downto 0); 
            in_2 : in std_logic_vector(NBIT-1 downto 0);
            addsub : in std_logic_vector(0 downto 0);
            sum : out std_logic_vector(NBIT-1 downto 0);
            cout: out std_logic);
end addsub_generic;

architecture behavior of addsub_generic is
    signal input1,input2: signed(NBIT downto 0);
    signal somma: std_logic_vector(NBIT downto 0);

    begin
        input1 <= signed('0' & in_1);
        input2 <= signed('0' & in_2);

        process (input1, input2, addsub)
        begin
          if addsub(0) = '0' then
            somma <= std_logic_vector(input1 + input2);
          else
            somma <= std_logic_vector(input1 - input2);
          end if;
        end process;

        sum<=somma(NBIT-1 downto 0);
        cout<=somma(NBIT);
end behavior;
