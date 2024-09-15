library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.constants.all;

entity Shifter is
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
end Shifter;

architecture Structural of Shifter is


    signal sel_1_mux:           std_logic_vector(1 downto 0);
    signal sel_1_mux_integer:   integer := 0;
    signal sel_2_mux:           std_logic_vector(2 downto 0);
    signal sel_2_mux_integer:   integer := 0;

    type MaskType is array(0 to 3) of std_logic_vector(NBIT_MASKS-1 downto 0);
    signal masks_left, masks_right_log, masks_right_arith: MaskType := (others => (others => '0')); 

    signal chosen_mask: std_logic_vector(NBIT_MASKS-1 downto 0) := (others => '0');

begin

    sel_1_mux           <= selection_signal(4 downto 3);
    sel_1_mux_integer   <= to_integer(unsigned(sel_1_mux));
    sel_2_mux           <= selection_signal(2 downto 0);
    sel_2_mux_integer   <= to_integer(unsigned(sel_2_mux));

    Masks_preparation:
    process(data_in)
        variable MSB: std_logic;
    begin
        --masks_left          <= (others => (others => '0'));
        --masks_right_log     <= (others => (others => '0'));
        --masks_right_arith   <= (others => (others => '0'));
        
        --This is mask0: the operand is not shifted
        --Only 8 zeros are added to the left
        masks_left(0) <= (others => '0');
        masks_left(0)(NBIT_MASKS-1 downto NBIT_BASIC_SHIFT) <= data_in;
        --This is mask8: the operand is shifted by 8 to the left
        --So 16 zeros are added to the left 
        masks_left(1) <= (others => '0');
        masks_left(1)(NBIT_MASKS-1 downto 2*NBIT_BASIC_SHIFT) <= data_in(NBIT-(NBIT_BASIC_SHIFT+1) downto 0);
        --This is mask16: the operand is shifted by 16 to the left
        --So 24 zeros are added to the left 
        masks_left(2) <= (others => '0');
        masks_left(2)(NBIT_MASKS-1 downto 3*NBIT_BASIC_SHIFT) <= data_in(NBIT-(2*NBIT_BASIC_SHIFT+1) downto 0);
        --This is mask24: the operand is shifted by 24 to the left
        --So 32 zeros are added to the left 
        masks_left(3) <= (others => '0');
        masks_left(3)(NBIT_MASKS-1 downto 4*NBIT_BASIC_SHIFT) <= data_in(NBIT-(3*NBIT_BASIC_SHIFT+1) downto 0);
        --This is mask8: the operand is shifted by 8 to the right
        --Only 8 zeros are added to the right
        masks_right_log(0) <= (others => '0');
        masks_right_log(0)(NBIT_MASKS-(NBIT_BASIC_SHIFT+1) downto 0) <= data_in;
        --This is mask16: the operand is shifted by 16 to the left
        --So 16 zeros are added to the right
        masks_right_log(1) <= (others => '0');
        masks_right_log(1)(NBIT_MASKS-(2*NBIT_BASIC_SHIFT+1) downto 0) <= data_in(NBIT-1 downto NBIT_BASIC_SHIFT);
        --This is mask24: the operand is shifted by 24 to the right
        --So 24 zeros are added to the right 
        masks_right_log(2) <= (others => '0');
        masks_right_log(2)(NBIT_MASKS-(3*NBIT_BASIC_SHIFT+1) downto 0) <= data_in(NBIT-1 downto 2*NBIT_BASIC_SHIFT);
        --This is mask32: the operand is shifted by 32 to the right
        --So 32 zeros are added to the right 
        masks_right_log(3) <= (others => '0');
        masks_right_log(3)(NBIT_MASKS-(4*NBIT_BASIC_SHIFT+1) downto 0) <= data_in(NBIT-1 downto 3*NBIT_BASIC_SHIFT);
        if (data_in(NBIT-1) = '0') then
            MSB := '0';
        else
            MSB := '1';
        end if;
        --This is mask8: the operand is shifted by 8 to the right
        --Only 8 zeros/ones are added to the right
        masks_right_arith(0) <= (others => MSB);
        masks_right_arith(0)(NBIT_MASKS-(NBIT_BASIC_SHIFT+1) downto 0) <= data_in;
        --This is mask16: the operand is shifted by 16 to the left
        --So 16 zeros/ones are added to the right
        masks_right_arith(1) <= (others => MSB);
        masks_right_arith(1)(NBIT_MASKS-(2*NBIT_BASIC_SHIFT+1) downto 0) <= data_in(NBIT-1 downto NBIT_BASIC_SHIFT);
        --This is mask24: the operand is shifted by 24 to the right
        --So 24 zeros/ones are added to the right 
        masks_right_arith(2) <= (others => MSB);
        masks_right_arith(2)(NBIT_MASKS-(3*NBIT_BASIC_SHIFT+1) downto 0) <= data_in(NBIT-1 downto 2*NBIT_BASIC_SHIFT);
        --This is mask32: the operand is shifted by 32 to the right
        --So 32 zeros/ones are added to the right 
        masks_right_arith(3) <= (others => MSB);
        masks_right_arith(3)(NBIT_MASKS-(4*NBIT_BASIC_SHIFT+1) downto 0) <= data_in(NBIT-1 downto 3*NBIT_BASIC_SHIFT);
    end process;

    Mask_choice:
    process(type_of_shift, masks_left, masks_right_log, masks_right_arith, sel_1_mux_integer)
    begin
        -- sel_1_mux_integer selects the mask to be used
        -- we have 4 masks for every type of shift, so 2 bits are needed
        -- sel_1_mux_integer is literally the translation of the 
        -- std_logic_vector sel_1_mux that comes as an input inside
        -- the second operand (which we called in this case 
        -- selection_signal) into the corresponding integer
        if (type_of_shift = shift_left_l) then
            chosen_mask <= masks_left(sel_1_mux_integer);
        elsif (type_of_shift = shift_right_l) then
            chosen_mask <= masks_right_log(sel_1_mux_integer);
        elsif (type_of_shift = shift_right_a) then
            chosen_mask <= masks_right_arith(sel_1_mux_integer);
        else
            chosen_mask <= masks_left(sel_1_mux_integer);
        end if;
    end process;

    Shift_from_0_to_7:
    process(type_of_shift, chosen_mask, sel_2_mux_integer)
    begin
        if (type_of_shift = shift_left_l) then
            data_out <= chosen_mask(NBIT_MASKS-1-(sel_2_mux_integer) downto (NBIT_BASIC_SHIFT-(sel_2_mux_integer)));
        else
            data_out <= chosen_mask(NBIT_MASKS-1-(NBIT_BASIC_SHIFT-(sel_2_mux_integer)) downto sel_2_mux_integer);
        end if;
    end process;

end Structural;
