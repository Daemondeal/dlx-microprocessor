library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegisterFile is
    generic (
        NBIT: integer := 32;
        NREG_SELECT: integer := 5;
        NREG: integer := 32
    );

    port (
        clk, enable, rst_n, write_enable: in std_logic;
        input: in std_logic_vector(NBIT-1 downto 0);
        select_in: in std_logic_vector(NREG_SELECT-1 downto 0);
        select_out1, select_out2: in std_logic_vector(NREG_SELECT-1 downto 0);
        output1, output2: out std_logic_vector(NBIT-1 downto 0)
    );
end RegisterFile;

architecture Behavioral of RegisterFile is
    type RegisterArray is array(0 to NREG-1) of std_logic_vector(NBIT-1 downto 0);
    signal registers: RegisterArray;
begin
    process (clk) 
        variable sel_out1, sel_out2, sel_in: integer;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                registers <= (others => (others => '0'));
                output1 <= (others => '0');
                output2 <= (others => '0');
            else
                sel_out1 := to_integer(unsigned(select_out1));
                sel_out2 := to_integer(unsigned(select_out2));
                sel_in   := to_integer(unsigned(select_in));
                if write_enable = '1' then 
                    registers(sel_in) <= input;
                end if;
                if enable = '1' then
                    output1 <= registers(sel_out1);
                    output2 <= registers(sel_out2);

                    if write_enable = '1' then
                        if sel_out1 = sel_in then
                            output1 <= input;
                        end if;
                        if sel_out2 = sel_in then
                            output2 <= input;
                        end if;
                    end if;
                else
                    -- If enable = '0', then register is stalled, 
                    -- so the output must not change
                    -- output1 <= (others => '0');
                    -- output2 <= (others => '0');
                end if;
            end if;
        end if;
    end process;
end Behavioral;

