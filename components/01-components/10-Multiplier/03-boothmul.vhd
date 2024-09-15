library ieee;
use ieee.std_logic_1164.all;

entity BOOTHMUL is 
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
end BOOTHMUL;

architecture behavior of BOOTHMUL is

    component booth_add 
        generic (NBIT: integer:= 32);
        port (a: in std_logic_vector(NBIT-1 downto 0); -- multiplicand
                b: in std_logic_vector(2 downto 0);  -- Booth multiplier
                sum_in: in std_logic_vector(NBIT-1 downto 0); -- sum input
                sum_out: out std_logic_vector(NBIT-1 downto 0); -- sum output
                p: out std_logic_vector(1 downto 0)); -- 2 bits of final result
    end component;
    
    component FlipFlop is
        port (
            input: in std_logic;
            output: out std_logic;
            clk, rst_n: in std_logic);
    end component FlipFlop;

    component generic_reg 
    generic (NBIT: integer:= 32);
      port (input: in std_logic_vector(NBIT-1 downto 0); 
              output: out std_logic_vector(NBIT-1 downto 0); -- multiplier
              clk, rst_n: in std_logic); 
    end component;
    
    signal     start : std_logic_vector(NBIT downto 0); -- start sum value
    signal     mul0: std_logic_vector(2 downto 0); -- start 3 bit x algorithm (Booth multiplier)
    type         sum_array is array(0 to (NBIT/2)-1) of std_logic_vector(NBIT downto 0);
    signal     sum : sum_array; -- partial sums signals
    
    type       sum_reg_type is array(0 to (NBIT/2)) of std_logic_vector(NBIT downto 0);
    type       product_type is array(0 to (NBIT/2)) of std_logic_vector(NBIT-1 downto 0);

    signal     prev_reg : sum_reg_type;

    signal     nxt_reg : sum_reg_type;

    signal     a_in_reg : sum_reg_type;
    signal     a_out_reg : sum_reg_type;
    signal     b_in_reg : product_type;
    signal     b_out_reg : product_type;

    signal skew_product_reg: product_type;
    signal skew_product_reg_out: product_type;

    signal last_reg_in: std_logic_vector(NBIT*2-1 downto 0);

    signal first_adder_input: std_logic_vector(NBIT downto 0);

    signal valid_chain: std_logic_vector(NBIT/2-1 downto 0);

    begin 

        start <= (others => '0'); -- start sum value is all 0s

        mul0 <= b(1 downto 0) & '0'; --set first parameter of algorithm with first 2 bit of b and 0 

        skew_product_reg(0)(NBIT-1 downto 2) <= (others => '0');

        first_adder_input <= a(NBIT-1) & a;

        valid_chain(0) <= mult_request;

        ADDER0: booth_add 
            generic map ( NBIT => NBIT + 1)
            port map(
                a=> first_adder_input,
                b=>mul0,
                sum_in=> start,
                sum_out =>sum(0),
                p=>skew_product_reg(0)(1 downto 0) -- first adder/encoder/mux
            ); 

        prev_reg(0) <= sum(0);
        a_in_reg(0) <= first_adder_input;
        b_in_reg(0) <= b;

        ADDER: for i in 1 to (NBIT/2)-1 generate 
            FF_valid_chain: FlipFlop
                port map (
                    input => valid_chain(i-1),
                    output => valid_chain(i),
                    clk => clk,
                    rst_n =>  rst_n
                );

            REG_PREV: generic_reg
                generic map (NBIT=>NBIT + 1)
                port map (
                    input=>prev_reg(i-1),
                    output=>nxt_reg(i-1),
                    clk=>clk, 
                    rst_n=>rst_n
                );

            REG_a_N: generic_reg 
                generic map (NBIT => NBIT + 1)
                port map (
                    input=>a_in_reg(i-1), 
                    output=>a_out_reg(i-1), 
                    clk=>clk, 
                    rst_n=>rst_n
                );

            REG_b_N: generic_reg 
                generic map (NBIT => NBIT) 
                port map (
                    input=>b_in_reg(i-1), 
                    output=>b_out_reg(i-1), 
                    clk=>clk, 
                    rst_n=>rst_n
                );

            REG_product: generic_reg 
                generic map (NBIT => NBIT)
                port map (
                    input => skew_product_reg(i-1),
                    output => skew_product_reg_out(i),
                    clk => clk,
                    rst_n => rst_n
                );


            skew_product_reg(i)(2*i-1 downto 0) <= skew_product_reg_out(i)(2*i-1 downto 0);

            BOOTHADD:  booth_add 
                generic map (NBIT => NBIT + 1)
                port map(
                    a => a_out_reg(i-1),
                    b => b_out_reg(i-1)((1+2*i) downto (2*i-1)),
                    sum_in => nxt_reg(i-1),
                    sum_out => sum(i),
                    p => skew_product_reg(i)((1+2*i) downto (2*i))
                );

            a_in_reg(i) <= a_out_reg(i-1);
            b_in_reg(i) <= b_out_reg(i-1);
            prev_reg(i) <= sum(i);

        end generate;

        FF_LastValid: FlipFlop
            port map (
                input => valid_chain(NBIT/2-1),
                output => valid,
                clk => clk,
                rst_n =>  rst_n
            );


        last_reg_in <= sum(NBIT/2-1)(NBIT-1 downto 0) & skew_product_reg(NBIT/2-1);

        REG_output: generic_reg 
            generic map (NBIT => 2*NBIT)
            port map (
                input =>  last_reg_in,
                output => p,
                clk => clk,
                rst_n => rst_n
            );
end behavior;  
