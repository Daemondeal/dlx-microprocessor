library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_utils.all;

entity tb_Boothmul is
end tb_Boothmul;


architecture TEST of tb_Boothmul is


    signal clk, rst_n: std_logic;

  --  input	 
    signal A_mp_i : std_logic_vector(31 downto 0) := (others => '0');
    signal B_mp_i : std_logic_vector(31 downto 0) := (others => '0');
    signal mult_request: std_logic;

  -- output
    signal Y_mp_i : std_logic_vector(63 downto 0);
    signal valid: std_logic;


  -- MUL component declaration
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


    signal sim_stopped: std_logic := '0';
    constant ClockPeriod: time := 1 ns;
begin

  -- MUL instantiation
  --
  --
    DUT: BOOTHMUL
    port map (
         clk => clk,
         rst_n => rst_n,

         A => A_mp_i,
         B => B_mp_i,
         P => Y_mp_i,

         mult_request =>  mult_request,
         valid => valid
     );

    process
    begin
        if sim_stopped = '0' then
            clk <= '0';
            wait for ClockPeriod/2;
            clk <= '1';
            wait for ClockPeriod/2;
        else
            wait;
        end if;
    end process;


  -- PROCESS FOR TESTING TEST - COMLETE CYCLE ---------
    test: process
        variable in1, in2: signed(31 downto 0);
        variable product: signed(63 downto 0);
    begin
        mult_request <= '0';
        rst_n <= '0';
        wait for ClockPeriod;
        rst_n <= '1';
        wait for ClockPeriod;

        A_mp_i <= x"00_00_00_04";
        B_mp_i <= x"00_00_00_18";
        mult_request <= '1';
        wait until rising_edge(clk);

        A_mp_i <= x"00_00_00_14";
        B_mp_i <= x"00_00_00_18";
        mult_request <= '1';
        wait until rising_edge(clk);

        A_mp_i <= x"00_00_00_24";
        B_mp_i <= x"00_00_00_18";
        mult_request <= '1';
        wait until rising_edge(clk);

        mult_request <= '0';

        while valid /= '1' loop
            wait until falling_edge(clk);
        end loop;

        assert_FirstPipe:
        assert Y_mp_i = x"00_00_00_00_00_00_00_60"; -- 0x04 * 0x18
        assert_Valid1:
        assert valid = '1';
        wait until falling_edge(clk);

        assert_SecondPipe:
        assert Y_mp_i = x"00_00_00_00_00_00_01_E0"; -- 0x14 * 0x18
        assert_Valid2:
        assert valid = '1';
        wait until falling_edge(clk);

        assert_ThirdPipe:
        assert Y_mp_i = x"00_00_00_00_00_00_03_60"; -- 0x24 * 0x18
        assert_Valid3:
        assert valid = '1';
        wait until falling_edge(clk);

        assert_ValidZero:
        assert valid = '0';



        for i in 0 to 100 loop
            if i = 0 then
                in1 := x"FF_FF_FF_F9";
                in2 := x"FF_FF_FF_F3";
            else
                in1 := signed(random_stdvec(32));
                in2 := signed(random_stdvec(32));
            end if;

            product := in1 * in2;

            A_mp_i <= std_logic_vector(in1);
            B_mp_i <= std_logic_vector(in2);

            for i in 0 to 40 loop
                wait until rising_edge(clk);  
            end loop;

            assert_ProductWorks:
            assert Y_mp_i = std_logic_vector(product)
                report "Invalid Multiplication: got "
                & integer'image(to_integer(signed(Y_mp_i))) & " but expected "
                & integer'image(to_integer(product));

        end loop;

        report "Simulation Finished!";
        sim_stopped <= '1';
        wait;
    end process test;


end TEST;
