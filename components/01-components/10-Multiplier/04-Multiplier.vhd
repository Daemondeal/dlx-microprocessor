library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Multiplier is
    generic (
        NBIT: integer := 32
    );
    port (
        i_clk, i_rst_n: in std_logic;
        i_in1, i_in2: in std_logic_vector(NBIT-1 downto 0);
        i_mult_request: in std_logic;
        o_product: out std_logic_vector(NBIT-1 downto 0);
        o_mult_busy: out std_logic
    );
end Multiplier;

architecture Behavioral of Multiplier is
    type StateType is (Zero, One);
    signal state, state_next: StateType;

    signal booth_prod: std_logic_vector(2*NBIT-1 downto 0);
    signal booth_request: std_logic;
    signal booth_valid: std_logic;

    component BOOTHMUL is 
        generic (
            NBIT: integer:= 32
        );

        port (
            a: in std_logic_vector(NBIT-1 downto 0); -- multiplicand
            b: in std_logic_vector(NBIT-1 downto 0); -- multiplier
            p: out std_logic_vector(2*NBIT-1 downto 0); -- result
            mult_request: in std_logic;
            valid: out std_logic;
            clk, rst_n: in std_logic
        );
    end component BOOTHMUL;
begin

    inst_BoothMul: BOOTHMUL
        generic map (NBIT => NBIT)
        port map (
            a => i_in1,
            b => i_in2,
            p => booth_prod,
            mult_request => booth_request,
            valid => booth_valid,
            clk => i_clk,
            rst_n => i_rst_n
        );

    o_product <= booth_prod(NBIT-1 downto 0);
    o_mult_busy <= not booth_valid;

    proc_FlipFlop:
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                state <= Zero;
            else
                state <= state_next;
            end if;
        end if;
    end process;

    proc_FallingEdgeDetectorFSM:
    process (state, i_mult_request, booth_valid)
    begin
        state_next <= state;
        booth_request <= '0';

        case state is
            when Zero =>
                if i_mult_request = '1' then
                    booth_request <= '1';
                    state_next <= One;
                else
                    state_next <= Zero;
                end if;
            when One =>
                if i_mult_request = '1' and booth_valid = '0' then
                    state_next <= One;
                else
                    state_next <= Zero;
                end if;
            when others =>
        end case;
    end process;

end Behavioral;

