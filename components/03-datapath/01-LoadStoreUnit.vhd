library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.control_word.all;
use work.utils.all;

entity LoadStoreUnit is
    generic (
        NBIT:       integer := 32;
        ADDR_WIDTH: integer := 32
    );
    port (
        i_address: in std_logic_vector(ADDR_WIDTH-1 downto 0);

        i_rd_request: in std_logic;

        i_wr_request: in std_logic;
        i_wr_data:    in std_logic_vector(NBIT-1 downto 0);

        i_data_type:  in DataType;

        o_data: out std_logic_vector(NBIT-1 downto 0);
        o_stall: out std_logic;

        o_mem_address: out std_logic_vector(NBIT-1 downto 0);

        o_mem_rd_request:  out std_logic;
        o_mem_wr_request:  out std_logic;
        o_mem_wr_data:     out std_logic_vector(NBIT-1 downto 0);
        o_mem_wr_byte_sel: out std_logic_vector((NBIT/8)-1 downto 0);

        i_mem_hit:     in std_logic;
        i_mem_rd_data: in std_logic_vector(NBIT-1 downto 0);

        o_misaligned_data: out std_logic
    );
end LoadStoreUnit;

architecture Behavioral of LoadStoreUnit is
    signal shift_amount: std_logic_vector(1 downto 0);

    signal shifted_output_to_mem: std_logic_vector(NBIT-1 downto 0);
    signal shifted_input_from_mem: std_logic_vector(NBIT-1 downto 0);
begin
    o_mem_address <= i_address(ADDR_WIDTH-1 downto 2) & "00";
    o_mem_address(1 downto 0) <= "00";

    o_mem_wr_request <= i_wr_request;
    o_mem_rd_request <= i_rd_request;

    StallProc: process (i_rd_request, i_wr_request, i_mem_hit)
    begin
        if (i_rd_request = '1' or i_wr_request = '1') and i_mem_hit = '0' then
            o_stall <= '1';
        else
            o_stall <= '0';
        end if;
    end process StallProc;

    ShiftProc: process (i_wr_data, i_mem_rd_data, shift_amount)
        variable shamt: integer;
    begin
        shamt := to_integer(unsigned(shift_amount));

        shifted_output_to_mem <= (others => '0');
        shifted_input_from_mem <= (others => '0');

        -- Ugly code mandated by synopsys
        for i in 0 to 3 loop
            if i = shamt then
                shifted_output_to_mem(NBIT-1 downto i*8) <= i_wr_data(NBIT-i*8-1 downto 0);
                shifted_input_from_mem(NBIT-1-i*8 downto 0) <= i_mem_rd_data(NBIT-1 downto i*8);
            end if;
        end loop;
    end process ShiftProc;


    process (i_address, i_data_type, shifted_input_from_mem, shifted_output_to_mem)
    begin
        o_mem_wr_byte_sel <= (others => '0');
        o_misaligned_data <= '0';
        o_data <= (others => '0');
        o_mem_wr_data <= (others => '0');
        shift_amount <= (others => '0');

        case i_data_type is
            when Word =>
                -- A Word is 4 bytes long
                o_mem_wr_byte_sel(3 downto 0) <= (others => '1');
                if i_address(1 downto 0) /= "00" then
                    o_misaligned_data <= '1';
                else
                    o_misaligned_data <= '0';
                end if;

                shift_amount <= (others => '0');

                o_data <= shifted_input_from_mem;
                o_mem_wr_data <= shifted_output_to_mem;
            when Halfword =>
                shift_amount(1) <= i_address(1);
                shift_amount(0) <= '0';

                if i_address(0) /= '0' then
                    o_misaligned_data <= '1';
                else
                    o_misaligned_data <= '0';
                end if;

                o_mem_wr_data <= shifted_output_to_mem;

                o_data <= (others => '0');
                o_data(15 downto 0) <= shifted_input_from_mem(15 downto 0);

                if i_address(1) = '1' then
                    o_mem_wr_byte_sel <= "1100";
                else
                    o_mem_wr_byte_sel <= "0011";
                end if;

            when Byte =>
                -- Byte addresses are never misaligned
                o_misaligned_data <= '0';

                shift_amount <= i_address(1 downto 0);

                o_mem_wr_data <= shifted_output_to_mem;

                o_data <= (others => '0');
                o_data(7 downto 0) <= shifted_input_from_mem(7 downto 0);

                o_mem_wr_byte_sel <= (others => '0');
                o_mem_wr_byte_sel(to_integer(unsigned(i_address(1 downto 0)))) <= '1';

            when HalfwordSigned =>
                shift_amount(1) <= i_address(1);
                shift_amount(0) <= '0';

                if i_address(0) /= '0' then
                    o_misaligned_data <= '1';
                else
                    o_misaligned_data <= '0';
                end if;

                o_mem_wr_data <= shifted_output_to_mem;

                o_data <= (others => shifted_input_from_mem(15));
                o_data(15 downto 0) <= shifted_input_from_mem(15 downto 0);

                if i_address(1) = '1' then
                    o_mem_wr_byte_sel <= "1100";
                else
                    o_mem_wr_byte_sel <= "0011";
                end if;
            when ByteSigned =>
                -- Byte addresses are never misaligned
                o_misaligned_data <= '0';

                shift_amount <= i_address(1 downto 0);

                o_mem_wr_data <= shifted_output_to_mem;

                -- Sign extend
                o_data <= (others => shifted_input_from_mem(7));
                o_data(7 downto 0) <= shifted_input_from_mem(7 downto 0);

                o_mem_wr_byte_sel <= (others => '0');
                o_mem_wr_byte_sel(to_integer(unsigned(i_address(1 downto 0)))) <= '1';
            when others =>
        end case;
    end process;
end Behavioral;

