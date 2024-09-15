library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.control_word.all;

entity tb_LoadStoreUnit is
end tb_LoadStoreUnit;

architecture tb of tb_LoadStoreUnit is
    component LoadStoreUnit is
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
    end component LoadStoreUnit;

    signal s_address: std_logic_vector(31 downto 0) := (others => '0');

    signal s_rd_request: std_logic := '0';

    signal s_wr_request: std_logic := '0';
    signal s_wr_data: std_logic_vector(31 downto 0) := (others => '0');

    signal s_data_type: DataType := Word;

    signal s_data: std_logic_vector(31 downto 0) := (others => '0');
    signal s_stall: std_logic := '0';

    signal s_mem_address: std_logic_vector(31 downto 0) := (others => '0');

    signal s_mem_rd_request:  std_logic := '0';
    signal s_mem_wr_request:  std_logic := '0';
    signal s_mem_wr_data:     std_logic_vector(31 downto 0) := (others => '0');
    signal s_mem_wr_byte_sel: std_logic_vector(3 downto 0) := (others => '0');

    signal s_mem_hit:     std_logic := '0';
    signal s_mem_rd_data: std_logic_vector(31 downto 0) := (others => '0');

    signal s_misaligned_data: std_logic := '0';
begin

    DUT: LoadStoreUnit
        generic map (
            NBIT => 32,
            ADDR_WIDTH => 32
        )
        port map (
            i_address => s_address,

            i_rd_request => s_rd_request,
            i_wr_request => s_wr_request,
            i_wr_data => s_wr_data,

            i_data_type => s_data_type,

            o_data => s_data,
            o_stall => s_stall,

            o_mem_address => s_mem_address,

            o_mem_rd_request => s_mem_rd_request,
            o_mem_wr_request => s_mem_wr_request,
            o_mem_wr_data => s_mem_wr_data,
            o_mem_wr_byte_sel => s_mem_wr_byte_sel,

            i_mem_hit => s_mem_hit,
            i_mem_rd_data => s_mem_rd_data,

            o_misaligned_data => s_misaligned_data
        );

    TestProcess: process
    begin


        wait for 1 ns;

        report "Testing Words";
        s_data_type <= Word;
        s_wr_request <= '1';
        s_wr_data <= x"AAAABBBB";

        -- Aligned word
        s_address <= x"00_00_00_00";

        s_mem_hit <= '1';
        s_mem_rd_data <= x"AAAABBBB";

        wait for 1 ns;
        assert s_data = x"AAAABBBB"
            report "When data type is set to word, it should return the same signal";

        assert s_mem_wr_data = x"AAAABBBB"
            report "When data type is set to word, it should return the same signal";

        assert s_mem_wr_byte_sel = "1111"
            report "All bytes should be selected";
        assert s_misaligned_data = '0'
            report "Data should not be misaligned";

        assert s_mem_address = s_address;

        wait for 1 ns;
        -- Check for data misalignment
        s_address <= x"00_00_00_01";

        wait for 1 ns;
        assert s_misaligned_data = '1';

        wait for 1 ns;
        s_address <= x"00_00_00_02";

        wait for 1 ns;
        assert s_misaligned_data = '1';

        wait for 1 ns;
        s_address <= x"00_00_00_03";


        wait for 1 ns;
        assert s_misaligned_data = '1';

        wait for 1 ns;
        s_address <= x"00_00_00_04";

        wait for 1 ns;
        assert s_misaligned_data = '0';

        wait for 1 ns;
        report "Testing Halfwords";
        s_data_type <= Halfword;
        s_rd_request <= '1';
        s_wr_request <= '0';

        s_address <= x"00_00_00_00";
        s_wr_data <= x"AABBCCDD";
        s_mem_rd_data <= x"AABBCCDD";


        wait for 1 ns;
        assert s_mem_wr_data(15 downto 0) = x"CCDD";
        assert s_mem_wr_byte_sel = "0011";
        assert s_data = x"0000CCDD";

        assert s_mem_address = s_address;


        wait for 1 ns;
        s_address <= x"00_00_00_01";

        wait for 1 ns;
        assert s_misaligned_data = '1';

        wait for 1 ns;
        s_address <= x"00_00_00_02";

        wait for 1 ns;
        assert s_misaligned_data = '0';
        assert s_mem_wr_data(31 downto 16) = x"CCDD";
        assert s_mem_wr_byte_sel = "1100";
        assert s_data = x"0000AABB";
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        s_address <= x"00_00_00_03";

        wait for 1 ns;
        assert s_misaligned_data = '1';


        wait for 1 ns;
        report "Testing Bytes";
        s_data_type <= Byte;
        s_address <= x"00_00_00_00";
        s_wr_data <= x"AABBCCDD";
        s_mem_rd_data <= x"AABBCCDD";

        wait for 1 ns;
        assert s_data = x"000000DD";
        assert s_mem_wr_data(7 downto 0) = x"DD";
        assert s_mem_wr_byte_sel = "0001";
        assert s_misaligned_data = '0';
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        s_address <= x"00_00_00_01";
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        assert s_data = x"000000CC";
        assert s_mem_wr_data(15 downto 8) = x"DD";
        assert s_mem_wr_byte_sel = "0010";
        assert s_misaligned_data = '0';
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        s_address <= x"00_00_00_02";

        wait for 1 ns;
        assert s_data = x"000000BB";
        assert s_mem_wr_data(23 downto 16) = x"DD";
        assert s_mem_wr_byte_sel = "0100";
        assert s_misaligned_data = '0';
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        s_address <= x"00_00_00_03";

        wait for 1 ns;
        assert s_data = x"000000AA";
        assert s_mem_wr_data(31 downto 24) = x"DD";
        assert s_mem_wr_byte_sel = "1000";
        assert s_misaligned_data = '0';
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        report "Testing Signed Halfwords";
        s_data_type <= HalfwordSigned;
        s_rd_request <= '1';
        s_wr_request <= '0';

        s_address <= x"00_00_00_00";
        s_wr_data <= x"AABBCCDD";
        s_mem_rd_data <= x"22BBCCDD";


        wait for 1 ns;
        assert s_mem_wr_data(15 downto 0) = x"CCDD";
        assert s_mem_wr_byte_sel = "0011";
        assert s_data = x"FFFFCCDD";
        assert s_mem_address = x"00000000";


        wait for 1 ns;
        s_address <= x"00_00_00_01";

        wait for 1 ns;
        assert s_misaligned_data = '1';

        wait for 1 ns;
        s_address <= x"00_00_00_02";

        wait for 1 ns;
        assert s_misaligned_data = '0';
        assert s_mem_wr_data(31 downto 16) = x"CCDD";
        assert s_mem_wr_byte_sel = "1100";
        assert s_data = x"000022BB";
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        s_address <= x"00_00_00_03";

        wait for 1 ns;
        assert s_misaligned_data = '1';

        report "Testing Signed Bytes";

        wait for 1 ns;
        s_data_type <= ByteSigned;
        s_address <= x"00_00_00_00";
        s_wr_data <= x"AABBCCDD";
        s_mem_rd_data <= x"11BB22DD";

        wait for 1 ns;
        assert s_data = x"FFFFFFDD";
        assert s_mem_wr_data(7 downto 0) = x"DD";
        assert s_mem_wr_byte_sel = "0001";
        assert s_misaligned_data = '0';
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        s_address <= x"00_00_00_01";

        wait for 1 ns;
        assert s_data = x"00000022";
        assert s_mem_wr_data(15 downto 8) = x"DD";
        assert s_mem_wr_byte_sel = "0010";
        assert s_misaligned_data = '0';
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        s_address <= x"00_00_00_02";

        wait for 1 ns;
        assert s_data = x"FFFFFFBB";
        assert s_mem_wr_data(23 downto 16) = x"DD";
        assert s_mem_wr_byte_sel = "0100";
        assert s_misaligned_data = '0';
        assert s_mem_address = x"00000000";

        wait for 1 ns;
        s_address <= x"00_00_00_03";

        wait for 1 ns;
        assert s_data = x"00000011";
        assert s_mem_wr_data(31 downto 24) = x"DD";
        assert s_mem_wr_byte_sel = "1000";
        assert s_misaligned_data = '0';
        assert s_mem_address = x"00000000";


        report "Check Stalls";

        s_rd_request <= '0';
        s_wr_request <= '0';
        s_mem_hit <= '0';

        wait for 1 ns;
        assert s_stall = '0';

        s_rd_request <= '1';
        s_wr_request <= '0';
        s_mem_hit <= '0';

        wait for 1 ns;
        assert s_stall = '1'
            report "Invalid stall in rd request";

        assert s_mem_rd_request = '1';
        assert s_mem_wr_request = '0';


        s_rd_request <= '0';
        s_wr_request <= '1';
        s_mem_hit <= '0';

        wait for 1 ns;
        assert s_stall = '1';

        assert s_mem_rd_request = '0';
        assert s_mem_wr_request = '1';

        s_rd_request <= '1';
        s_wr_request <= '0';
        s_mem_hit <= '1';

        wait for 1 ns;
        assert s_stall = '0';

        assert s_mem_rd_request = '1';
        assert s_mem_wr_request = '0';

        s_rd_request <= '0';
        s_wr_request <= '1';
        s_mem_hit <= '1';

        wait for 1 ns;
        assert s_stall = '0';

        assert s_mem_rd_request = '0';
        assert s_mem_wr_request = '1';




        report "Simulation Finished!";
        wait;
    end process TestProcess;

end tb;

