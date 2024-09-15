library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_BTB is
end tb_BTB;

architecture behavioral of tb_BTB is
    component BTB is
        generic (
            NBIT: integer := 32;
            LINE_ADDR_WIDTH: integer := 4 
        );
        port (
            enable, clk, reset_n, write_en: in std_logic;
            taken_branch: in std_logic;
            next_addr_computed: in std_logic_vector(NBIT-1 downto 0);
            next_pc: in std_logic_vector(NBIT-1 downto 0);
            next_pc_mem_stage: in std_logic_vector(NBIT-1 downto 0);
    
            jump_address: out std_logic_vector(NBIT-1 downto 0);
            sel_mux_next_pc: out std_logic; --when 0 it selects the normal execution address, when 1 it
                                   --selects the address where it has to jump
            flush: out std_logic
        );
    end component;

    signal clk, enable, reset_n, taken_b, sel_mux, flush, write_en: std_logic;
    signal pc, pc_mem, next_addr_c, jump_to: std_logic_vector(31 downto 0);

    constant ClockPeriod: time := 20 ns;
    signal sim_stopped: std_logic := '0';

begin
    DUT: BTB
        generic map (
            NBIT => 32, LINE_ADDR_WIDTH => 4
        )
        port map (
            enable => enable, clk => clk, reset_n => reset_n, write_en => write_en, 
            taken_branch => taken_b, next_addr_computed => next_addr_c, next_pc => pc, 
            next_pc_mem_stage => pc_mem, jump_address => jump_to, 
            sel_mux_next_pc => sel_mux, flush => flush
        );

    CLK_PROC: process
    begin
        if sim_stopped = '0' then
            clk <= '0';
            wait for ClockPeriod/2;
            clk <= '1';
            wait for ClockPeriod/2;
        else
            wait;
        end if;
    end process CLK_PROC;

    TEST_PROC: process
    begin
        --reset
        taken_b <= '0';
        pc <= x"00000000";
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        enable <= '1';
        write_en <= '1';
        reset_n <= '0';
        pc <= (others => '0');
        wait for ClockPeriod * 3;

        reset_n <= '1';

        wait until rising_edge(clk);

        --Beginning: the BTB is empty

        --J1 in fetch stage
        taken_b <= '0';
        pc <= x"ABCABCAC"; --A1
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        --the outputs must be immediately computed, so I check them right after inputs have changed
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);

        --J2 in fetch stage; J1 in decode
        taken_b <= '0';
        pc <= x"ABCABCB0"; --A2
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);

        --nop in fetch; J2 in decode; J1 in execute
        taken_b <= '0';
        pc <= x"ABCABCB4"; --A3
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);

        --nop in fetch; nop in decode; J2 in execute; J1 in memory: it is taken
        --mispredicted branch: it is taken, but the matching was 0
        taken_b <= '1';
        pc <= x"ABCABCB8"; --A4
        pc_mem <= x"ABCABCAC";
        next_addr_c <= x"2939FFF0";
        wait for ClockPeriod * 1/8;
        assert flush = '1' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux"; 
        assert jump_to = x"2939FFF0" report "Wrong address in output";
        wait until rising_edge(clk);


        --Now curr_addr(0) = ABCABCAC; next_addr(0) = 2939FFF0

        --J1 in writeback
        taken_b <= '0';
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait until rising_edge(clk);


        --nop in fetch
        taken_b <= '0';
        pc <= x"2939FFF4"; --B1 (because it is the next pc that enters the BTB)
        pc_mem <= x"00000000"; 
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --nop in fetch; nop in decode
        taken_b <= '0';
        pc <= x"2939FFF8"; --B2 
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --J3 in fetch; nop in decode; nop in execute
        taken_b <= '0';
        pc <= x"2939FFFC"; --B3 (it is not inside the BTB)
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);
        


        --nop in fetch; J3 in decode; nop in execute; nop in memory
        taken_b <= '0';
        pc <= x"293A0000"; --B4 
        pc_mem <= x"2939FFF4";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --nop in fetch; nop in decode; J3 in execute; nop in memory; nop in writeback
        taken_b <= '0';
        pc <= x"293A0004"; --B5 
        pc_mem <= x"2939FFF8";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --nop in fetch; nop in decode; nop in execute; J3 in memory: it is taken; nop in writeback
        --mispredicted branch: it is taken, but the matching was 0
        taken_b <= '1';
        pc <= x"293A0008"; --B6 
        pc_mem <= x"2939FFFC";
        next_addr_c <= x"ABCABCA8";
        wait for ClockPeriod * 1/8;
        assert flush = '1' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = x"ABCABCA8" report "Wrong address in output";
        wait until rising_edge(clk);


        --Now:
        -- curr_addr(0) = ABCABCAC; next_addr(0) = 2939FFF0
        -- curr_addr(1) = 2939FFFC; next_addr(1) = ABCABCA8

        --J3 in writeback
        taken_b <= '0';
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait until rising_edge(clk);

        --J4 in fetch
        taken_b <= '0';
        pc <= x"ABCABCAC"; --C1 
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = x"2939FFF0" report "Wrong address in output";
        wait until rising_edge(clk);


        --nop in fetch; J4 in decode
        taken_b <= '0';
        pc <= x"2939FFF4"; --D1
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --nop in fetch; nop in decode; J4 in execute
        taken_b <= '0';
        pc <= x"2939FFF8"; --D2
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --J5 in fetch; nop in decode; nop in execute; J4 in memory: it is taken
        --and the target is the same => branch J4 predicted correctly
        taken_b <= '1';
        pc <= x"2939FFFC"; --D3
        pc_mem <= x"ABCABCAC";
        next_addr_c <= x"2939FFF0";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = x"ABCABCA8" report "Wrong address in output";
        wait until rising_edge(clk);


        -- Still:
        -- curr_addr(0) = ABCABCAC; next_addr(0) = 2939FFF0
        -- curr_addr(1) = 2939FFFC; next_addr(1) = ABCABCA8

        --J6 in fetch; J5 in decode; nop in execute; nop in memory; J4 in writeback
        taken_b <= '0';
        pc <= x"ABCABCAC"; --E1
        pc_mem <= x"2939FFF4";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = x"2939FFF0" report "Wrong address in output";
        wait until rising_edge(clk);


        --nop in fetch; J6 in decode; J5 in execute; nop in memory; nop in writeback
        taken_b <= '0';
        pc <= x"ABCABCB0"; --E2
        pc_mem <= x"2939FFF8";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --nop in fetch; nop in decode; J6 in execute; J5 in memory: it is not taken; nop in writeback
        --branch J5 mispredicted
        taken_b <= '0';
        pc <= x"ABCABCB4"; --E3
        pc_mem <= x"2939FFFC";
        next_addr_c <= x"ABCABCA8";
        wait for ClockPeriod * 1/8;
        assert flush = '1' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = x"2939FFFC" report "Wrong address in output";
        wait until rising_edge(clk);

        wait until rising_edge(clk);

        -- Now:
        -- curr_addr(0) = ABCABCAC; next_addr(0) = 2939FFF0

        --Now we check the replacement algorithm
        --We give 18 addresses that are not in the BTB but are taken branch
        --so that they are saved inside the BTB during the memory stage

        --The available (valid bit = 0) entries at the beginning are 15, 
        --because in the second entry we have: 
        --curr_addr(0) = ABCABCAC; next_addr(0) = 2939FFF0

        --We expect 3 entries to be replaced (first, second and third)
        --because the BTB was full

        for i in 0 to 17 loop
            for j in 1 to 4 loop
                taken_b <= '0';
                pc_mem <= x"00000000";
                next_addr_c <= x"00000000";
                pc <= std_logic_vector(to_unsigned(i*3+j, 32));
                wait for ClockPeriod * 1/8;
                assert flush = '0' report "Wrong flush";
                wait until rising_edge(clk);
            end loop;
            pc <= x"00000037"; 
            pc_mem <= std_logic_vector(to_unsigned(3*i+1, 32));
            next_addr_c <= std_logic_vector(to_unsigned(50*i+1, 32));
            taken_b <= '1';
            wait for ClockPeriod * 1/8;
            assert flush = '1' report "Wrong flush";
            wait until rising_edge(clk);
        end loop;

        --Now we check if last_replaced_mem works correctly
        --Once all entries have been replaced, it should go to 
        --zero again

        for i in 0 to 17 loop
            for j in 1 to 4 loop
                taken_b <= '0';
                pc_mem <= x"00000000";
                next_addr_c <= x"00000000";
                pc <= std_logic_vector(to_unsigned(i*5+j*1000, 32));
                wait for ClockPeriod * 1/8;
                assert flush = '0' report "Wrong flush";
                wait until rising_edge(clk);
            end loop;
            pc <= x"00000037"; 
            pc_mem <= std_logic_vector(to_unsigned(5*i+1000, 32));
            next_addr_c <= std_logic_vector(to_unsigned(50*i+6000, 32));
            taken_b <= '1';
            wait for ClockPeriod * 1/8;
            assert flush = '1' report "Wrong flush";
            wait until rising_edge(clk);
        end loop;


            

        wait for ClockPeriod * 1/8;

        wait until rising_edge(clk);

        --the branch is mispredicted also when, even if we have a hit inside the BTB and the branch
        --is taken, the address computed during the memory stage is different from the one stored
        --inside the BTB. We have to check this situation

        --fetch: matching inside the BTB
        taken_b <= '0';
        pc <= std_logic_vector(to_unsigned(1030, 32)); --pc = x"406"
        pc_mem <= x"87587597";
        next_addr_c <= x"00000005";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = x"0000189C" report "Wrong address in output";
        wait until rising_edge(clk);

        --decode
        taken_b <= '0';
        pc <= x"AAAEEE55";
        pc_mem <= x"87587599";
        next_addr_c <= x"00000005";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);

        --execute
        taken_b <= '0';
        pc <= x"AAAEEE59";
        pc_mem <= x"87587571";
        next_addr_c <= x"00000005";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);

        --memory: different next_addr_computed
        taken_b <= '1';
        pc <= x"AAAEFE59";
        pc_mem <= std_logic_vector(to_unsigned(1030, 32));
        next_addr_c <= x"00000015";
        wait for ClockPeriod * 1/8;
        assert flush = '1' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = x"00000015" report "Wrong address in output";
        wait until rising_edge(clk);

        --writeback
        taken_b <= '0';
        pc <= x"00000019";
        pc_mem <= x"00000000";
        next_addr_c <= x"00000005";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);

        --Now the address is not taken and, moreover, the next_address_computed is different
        
        --fetch
        taken_b <= '0';
        pc <= std_logic_vector(to_unsigned(1050, 32));
        pc_mem <= x"00000000";
        next_addr_c <= x"00000900";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = std_logic_vector(to_unsigned(6500, 32)) report "Wrong address in output";
        wait until rising_edge(clk);

        --decode
        taken_b <= '0';
        pc <= x"00001968";
        pc_mem <= x"87587599";
        next_addr_c <= x"00000905";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);

        --execute
        taken_b <= '0';
        pc <= x"0000196B";
        pc_mem <= x"87587571";
        next_addr_c <= x"00000905";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);

        --memory
        taken_b <= '0';
        pc <= x"00001970";
        pc_mem <= std_logic_vector(to_unsigned(1050, 32));
        next_addr_c <= x"00110015";
        wait for ClockPeriod * 1/8;
        assert flush = '1' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = std_logic_vector(to_unsigned(1050, 32)) report "Wrong address in output";
        wait until rising_edge(clk);

        --writeback
        taken_b <= '0';
        pc <= x"00000000";
        pc_mem <= x"00000000";
        next_addr_c <= x"00000005";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);

        --now we want to check che correct behavior of the BTB when the write_enable
        --is low: the BTB should provide the correct outputs, but it should not update
        --itself


        --fetch
        taken_b <= '0';
        pc <= x"FFFFCCAA";
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --decode
        taken_b <= '0';
        pc <= x"FFFFCCAE"; 
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --execute
        taken_b <= '0';
        pc <= x"FFFFCCB2"; 
        pc_mem <= x"00000000";
        next_addr_c <= x"00000000";
        wait for ClockPeriod * 1/8;
        assert flush = '0' report "Wrong flush";
        assert sel_mux = '0' report "Wrong sel_mux";
        assert jump_to = x"00000000" report "Wrong address in output";
        wait until rising_edge(clk);


        --memory
        taken_b <= '1';
        write_en <= '0';
        pc <= x"FFFFCCB6"; 
        pc_mem <= x"FFFFCCAA";
        next_addr_c <= x"0000ABCD";
        wait for ClockPeriod * 1/8;
        assert flush = '1' report "Wrong flush";
        assert sel_mux = '1' report "Wrong sel_mux";
        assert jump_to = x"0000ABCD" report "Wrong address in output";
        wait until rising_edge(clk);

        write_en <= '1';



        report "Simulation Finished!";
        sim_stopped <= '1';
        wait;
    end process TEST_PROC;

end behavioral;