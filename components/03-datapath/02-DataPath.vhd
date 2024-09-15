library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.control_word.all;

-- Acronyms:
--  if = instruction fetch
--  id = instruction decode
--  ex = execute
--  mm = memory
--  wb = write back
--  ic = instruction cache
--  dc = data cache
entity DataPath is
    generic (
        NBIT: integer := 32;
        ADDR_WIDTH: integer := 32;
        BTB_LINES_WIDTH: integer := 4;
        RESET_ADDR: std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        i_clk, i_rst_n: in std_logic;
        -- Control signals coming from CU
        -- Fetch
        i_if_sel_pc_btb_npc_n: in std_logic;

        -- Decode
        i_id_cw: in DecodeControlWord;

        -- Execute
        i_ex_forward_a_sel: in ForwardType;
        i_ex_forward_b_sel: in ForwardType;

        i_ex_cw: in ExecuteControlWord;

        -- Memory
        i_mm_cw: in MemoryControlWord;

        -- Write Back
        i_wb_cw: in WriteBackControlWord;

        -- Pipeline Signals
        i_if_stall: in std_logic;
        i_id_stall: in std_logic;
        i_ex_stall: in std_logic;
        i_mm_stall: in std_logic;
        i_wb_stall: in std_logic;

        i_ex_multicycle_stall: in std_logic;

        i_if_flush: in std_logic;
        i_id_flush: in std_logic;
        i_ex_flush: in std_logic;
        i_mm_flush: in std_logic;
        i_wb_flush: in std_logic;

        -- Status signals towards CU
        o_if_btb_predict_will_branch: out std_logic;
        o_if_ic_hit: out std_logic;

        o_id_ir_opcode: out std_logic_vector(OPCODE_SIZE-1 downto 0);
        o_id_ir_func:   out std_logic_vector(FUNC_SIZE-1 downto 0);

        o_ex_ir_rs1: out std_logic_vector(REG_ADDR_SIZE-1 downto 0);
        o_ex_ir_rs2: out std_logic_vector(REG_ADDR_SIZE-1 downto 0);

        o_mm_ir_rd: out std_logic_vector(REG_ADDR_SIZE-1 downto 0);
        o_ex_multicycle_busy: out std_logic;

        o_mm_btb_mispredict: out std_logic;

        o_mm_dc_stall: out std_logic;

        o_wb_ir_rd: out std_logic_vector(REG_ADDR_SIZE-1 downto 0);

        -- Signals between Memory System and Datapath
        o_ic_address: out std_logic_vector(ADDR_WIDTH-1 downto 0);

        o_ic_rd_request: out std_logic;
        i_ic_rd_data:    in std_logic_vector(NBIT-1 downto 0);

        i_ic_hit: in std_logic;

        o_dc_address: out std_logic_vector(ADDR_WIDTH-1 downto 0);

        o_dc_rd_request: out  std_logic;
        i_dc_rd_data:    in std_logic_vector(NBIT-1 downto 0);

        o_dc_wr_request:  out std_logic;
        o_dc_wr_data:     out std_logic_vector(NBIT-1 downto 0);
        o_dc_wr_data_sel: out std_logic_vector((NBIT/8)-1 downto 0);

        i_dc_hit: in std_logic
    );
end DataPath;

architecture Structural of DataPath is
    component ALU is
        generic (
            NBIT: integer := 32);
        port (
            i_operation: in AluOperationType;
            i_in1, i_in2: in std_logic_vector(NBIT-1 downto 0);
            o_result: out std_logic_vector(NBIT-1 downto 0)
        );
    end component ALU;

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

    component RegisterFile is
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
    end component RegisterFile;

    component MulticycleUnit is
        generic (NBIT: integer := 32);
        port (
            i_clk, i_rst_n: in std_logic;
            i_in1, i_in2: in std_logic_vector(NBIT-1 downto 0);

            i_flush: in std_logic;
            i_stall: in std_logic;

            i_multicycle_op: in MulticycleOpType;
            o_result: out std_logic_vector(NBIT-1 downto 0);
            o_busy: out std_logic
        );
    end component MulticycleUnit;

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
            sel_mux_next_pc: out std_logic; --0 for normal execution, 1 for jump

            flush: out std_logic
        );
    end component BTB;

    -- Pipeline registers
    -- NOTE: The stage name inside the signal refers to the name
    --       of the pipeline stage it's going into.
    --       e.g. reg_id_ir is the pipeline signal of the IR going
    --       into the decode stage and coming from fetch

    signal reg_if_pc, reg_if_pc_next: std_logic_vector(NBIT-1 downto 0);

    signal reg_id_ir, reg_id_ir_next: std_logic_vector(I_SIZE-1 downto 0);
    signal reg_id_npc, reg_id_npc_next: std_logic_vector(NBIT-1 downto 0);

    signal reg_ex_rs1, reg_ex_rs1_next: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal reg_ex_rs2, reg_ex_rs2_next: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal reg_ex_rd, reg_ex_rd_next: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal reg_ex_imm, reg_ex_imm_next: std_logic_vector(NBIT-1 downto 0);
    signal reg_ex_a: std_logic_vector(NBIT-1 downto 0);
    signal reg_ex_b: std_logic_vector(NBIT-1 downto 0);
    signal reg_ex_npc, reg_ex_npc_next: std_logic_vector(NBIT-1 downto 0);

    signal reg_mm_rd, reg_mm_rd_next: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal reg_mm_arith_out, reg_mm_arith_out_next: std_logic_vector(NBIT-1 downto 0);
    signal reg_mm_b, reg_mm_b_next: std_logic_vector(NBIT-1 downto 0);
    signal reg_mm_branch_taken, reg_mm_branch_taken_next: std_logic;
    signal reg_mm_npc, reg_mm_npc_next: std_logic_vector(NBIT-1 downto 0);

    signal reg_wb_rd, reg_wb_rd_next: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal reg_wb_arith_out, reg_wb_arith_out_next: std_logic_vector(NBIT-1 downto 0);
    signal reg_wb_mem_out, reg_wb_mem_out_next: std_logic_vector(NBIT-1 downto 0);
    signal reg_wb_npc, reg_wb_npc_next: std_logic_vector(NBIT-1 downto 0);

    -- Other Signals
    signal s_if_btb_write_enable: std_logic;
    signal s_if_btb_predicted_address: std_logic_vector(NBIT-1 downto 0);
    signal s_if_npc: std_logic_vector(NBIT-1 downto 0);

    signal s_id_rf_enable: std_logic;

    -- I-Type
    signal s_id_ir_i_rs1: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal s_id_ir_i_rd:  std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal s_id_ir_i_imm: std_logic_vector(IMM_I_SIZE-1 downto 0);

    -- R-Type
    signal s_id_ir_r_rs1:  std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal s_id_ir_r_rs2:  std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal s_id_ir_r_rd:   std_logic_vector(REG_ADDR_SIZE-1 downto 0);

    -- J-Type
    signal s_id_ir_j_imm:  std_logic_vector(IMM_J_SIZE-1 downto 0);

    signal s_id_rs1:  std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal s_id_rs2:  std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal s_id_rd:   std_logic_vector(REG_ADDR_SIZE-1 downto 0);


    signal s_ex_forwarded_a: std_logic_vector(NBIT-1 downto 0);
    signal s_ex_forwarded_b: std_logic_vector(NBIT-1 downto 0);
    signal s_ex_alu_in1: std_logic_vector(NBIT-1 downto 0);
    signal s_ex_alu_in2: std_logic_vector(NBIT-1 downto 0);
    signal s_ex_alu_out: std_logic_vector(NBIT-1 downto 0);
    signal s_ex_mult_out: std_logic_vector(NBIT-1 downto 0);

    signal ex_multicycle_busy: std_logic;

    signal s_wb_rf_input: std_logic_vector(NBIT-1 downto 0);
    signal s_wb_rf_rd: std_logic_vector(REG_ADDR_SIZE-1 downto 0);


    -- Traps
    -- NOTE: While exceptions are not implemented, these are
    --       signals that would trigger them, if they ever get
    --       implemented.
    signal s_trap_wb_misaligned_data: std_logic;
begin

    -- Fetch Stage
    Fetch_Pipeline: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' or i_if_flush = '1' then
                reg_if_pc <= RESET_ADDR;
            elsif i_if_stall = '0' then
                reg_if_pc <= reg_if_pc_next;
            end if;
        end if;
    end process Fetch_Pipeline;

    -- icache control
    o_if_ic_hit <= i_ic_hit;
    o_ic_address <= reg_if_pc;
    o_ic_rd_request <= '1';

    reg_id_ir_next <= i_ic_rd_data;



    s_if_btb_write_enable <= not i_if_stall;
    BranchPredictor: BTB
        generic map (
            NBIT => 32,
            LINE_ADDR_WIDTH => BTB_LINES_WIDTH)
        port map (
            clk => i_clk,
            enable => '1',
            write_en => s_if_btb_write_enable,
            reset_n => i_rst_n,

            next_addr_computed => reg_mm_arith_out,

            next_pc_mem_stage => reg_mm_npc,
            next_pc => s_if_npc,

            jump_address => s_if_btb_predicted_address,
            sel_mux_next_pc => o_if_btb_predict_will_branch,

            taken_branch => reg_mm_branch_taken,

            flush => o_mm_btb_mispredict
        );

    s_if_npc <= std_logic_vector(unsigned(reg_if_pc) + 4);

    reg_if_pc_next <= s_if_npc when i_if_sel_pc_btb_npc_n = '0' else
    s_if_btb_predicted_address;

    reg_id_npc_next <= s_if_npc;


    -- Decode Stage
    Decode_Pipeline: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' or i_id_flush = '1' then
                reg_id_ir <= NOP_INSTR;
                reg_id_npc <= RESET_ADDR;
            elsif i_id_stall = '0' then
                reg_id_ir <= reg_id_ir_next;
                reg_id_npc <= reg_id_npc_next;
            end if;
        end if;
    end process Decode_Pipeline;

    o_id_ir_opcode <= reg_id_ir(31 downto 26);
    o_id_ir_func   <= reg_id_ir(10 downto 0);

    s_id_ir_r_rs1  <= reg_id_ir(25 downto 21);
    s_id_ir_r_rs2  <= reg_id_ir(20 downto 16);
    s_id_ir_r_rd   <= reg_id_ir(15 downto 11);

    s_id_ir_i_rs1  <= reg_id_ir(25 downto 21);
    s_id_ir_i_rd   <= reg_id_ir(20 downto 16);
    s_id_ir_i_imm  <= reg_id_ir(15 downto 0);


    s_id_ir_j_imm  <= reg_id_ir(25 downto 0);

    DecodeIR: process (
            i_id_cw,
            s_id_ir_r_rs1, s_id_ir_r_rs2, s_id_ir_r_rd,
            s_id_ir_i_rs1, s_id_ir_i_rd
        )
    begin
        case i_id_cw.instruction_type is
            when RType =>
                s_id_rs1 <= s_id_ir_r_rs1;
                s_id_rs2 <= s_id_ir_r_rs2;
                s_id_rd  <= s_id_ir_r_rd;
            when IType =>
                s_id_rs1 <= s_id_ir_i_rs1;
                s_id_rs2 <= s_id_ir_i_rd;
                s_id_rd  <= s_id_ir_i_rd;
            when JType =>
                s_id_rs1 <= (others => '0');
                s_id_rs2 <= (others => '0');
                s_id_rd  <= (others => '0');
            when others =>
                s_id_rs1 <= (others => '0');
                s_id_rs2 <= (others => '0');
                s_id_rd  <= (others => '0');
        end case;
    end process DecodeIR;

    s_id_rf_enable <= not i_ex_stall;
    RegisterFileInstance:  RegisterFile
        generic map (
            NBIT => NBIT,
            NREG_SELECT => REG_ADDR_SIZE,
            NREG => 2 ** REG_ADDR_SIZE)
        port map (
            clk => i_clk,
            rst_n => i_rst_n,

            enable => s_id_rf_enable,
            write_enable => i_wb_cw.rf_wr_enable,

            select_out1 => s_id_rs1,
            select_out2 => s_id_rs2,

            select_in => s_wb_rf_rd,

            input => s_wb_rf_input,
            output1 => reg_ex_a,
            output2 => reg_ex_b
        );

    SignExtension: process (
            i_id_cw,
            s_id_ir_i_imm, s_id_ir_j_imm)
    begin
        if i_id_cw.instruction_type = JType then
            if i_id_cw.sel_imm_unsigned_signed_n = '0' then
                reg_ex_imm_next <= std_logic_vector(resize(signed(s_id_ir_j_imm), NBIT));
            else
                reg_ex_imm_next <= std_logic_vector(resize(unsigned(s_id_ir_j_imm), NBIT));
            end if;
        else -- I-Type
            if i_id_cw.sel_imm_unsigned_signed_n = '0' then
                reg_ex_imm_next <= std_logic_vector(resize(signed(s_id_ir_i_imm), NBIT));
            else
                reg_ex_imm_next <= std_logic_vector(resize(unsigned(s_id_ir_i_imm), NBIT));
            end if;
        end if;
    end process SignExtension;

    reg_ex_rs1_next <= s_id_rs1;
    reg_ex_rs2_next <= s_id_rs2;
    reg_ex_rd_next  <= s_id_rd;

    reg_ex_npc_next <= reg_id_npc;

    -- Execute Stage
    Execute_Pipeline: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' or i_ex_flush = '1' then
                reg_ex_rs1 <= (others => '0');
                reg_ex_rs2 <= (others => '0');
                reg_ex_rd  <= (others => '0');
                reg_ex_imm <= (others => '0');
                reg_ex_npc <= RESET_ADDR;
            elsif i_ex_stall = '0' then
                reg_ex_rs1 <= reg_ex_rs1_next;
                reg_ex_rs2 <= reg_ex_rs2_next;
                reg_ex_rd  <= reg_ex_rd_next;
                reg_ex_imm <= reg_ex_imm_next;
                reg_ex_npc <= reg_ex_npc_next;
            end if;
        end if;
    end process Execute_Pipeline;

    ForwardMux: process (
            i_ex_forward_a_sel, i_ex_forward_b_sel,
            reg_ex_a, reg_ex_b,
            reg_mm_arith_out, s_wb_rf_input
        )
    begin
        case i_ex_forward_a_sel is
            when NoForward =>
                s_ex_forwarded_a <= reg_ex_a;
            when ForwardMemoryStage =>
                s_ex_forwarded_a <= reg_mm_arith_out;
            when ForwardWritebackStage =>
                s_ex_forwarded_a <= s_wb_rf_input;
            when others =>
                s_ex_forwarded_a <= reg_ex_a;
        end case;

        case i_ex_forward_b_sel is
            when NoForward =>
                s_ex_forwarded_b <= reg_ex_b;
            when ForwardMemoryStage =>
                s_ex_forwarded_b <= reg_mm_arith_out;
            when ForwardWritebackStage =>
                s_ex_forwarded_b <= s_wb_rf_input;
            when others =>
                s_ex_forwarded_b <= reg_ex_b;
        end case;
    end process ForwardMux;

    SelectAluIn: process (
            i_ex_cw,
            reg_ex_npc, s_ex_forwarded_a,
            reg_ex_imm, s_ex_forwarded_b
        )
    begin
        if i_ex_cw.sel_in1_a_npc_n = '0' then
            s_ex_alu_in1 <= reg_ex_npc;
        else
            s_ex_alu_in1 <= s_ex_forwarded_a;
        end if;

        if i_ex_cw.sel_in2_b_imm_n = '0' then
            s_ex_alu_in2 <= reg_ex_imm;
        else
            s_ex_alu_in2 <= s_ex_forwarded_b;
        end if;

    end process SelectAluIn;

    AluInstance: ALU
        generic map (NBIT => NBIT)
        port map (
            i_operation => i_ex_cw.alu_operation,
            i_in1 => s_ex_alu_in1,
            i_in2 => s_ex_alu_in2,
            o_result => s_ex_alu_out
        );

    SelectArithOut: process (
            i_ex_cw,
            s_ex_mult_out, s_ex_alu_out)
    begin
        case i_ex_cw.sel_arithmetic is
            when OutMulticycle =>
                reg_mm_arith_out_next <= s_ex_mult_out;
            when OutALU =>
                reg_mm_arith_out_next <= s_ex_alu_out;
            when others =>
                reg_mm_arith_out_next <= (others => '-');
        end case;
    end process SelectArithOut;

    BranchDecisionUnit: process (i_ex_cw, s_ex_forwarded_a)
        variable branch_taken: boolean;
        variable zero: std_logic_vector(NBIT-1 downto 0);
    begin
        zero := (others => '0');
        case i_ex_cw.branch_type is
            when JumpIfZero =>
                branch_taken := s_ex_forwarded_a = zero;
            when JumpIfNotZero =>
                branch_taken := s_ex_forwarded_a /= zero;
            when Always =>
                branch_taken := true;
            when Never =>
                branch_taken := false;
            when others =>
                branch_taken := false;
        end case;

        if branch_taken then
            reg_mm_branch_taken_next <= '1';
        else
            reg_mm_branch_taken_next <= '0';
        end if;
    end process BranchDecisionUnit;

    Execute_Multicycle: MulticycleUnit
        generic map (NBIT => 32)
        port map (
            i_clk => i_clk,
            i_rst_n => i_rst_n,

            i_in1 => s_ex_forwarded_a,
            i_in2 => s_ex_forwarded_b,

            i_stall => i_ex_multicycle_stall,
            i_flush => i_ex_flush,

            i_multicycle_op => i_ex_cw.multicycle_op,

            o_result => s_ex_mult_out,
            o_busy => ex_multicycle_busy
        );

    o_ex_multicycle_busy <= ex_multicycle_busy;

    reg_mm_b_next <= s_ex_forwarded_b;
    reg_mm_rd_next <= reg_ex_rd;
    reg_mm_npc_next <= reg_ex_npc;

    o_ex_ir_rs1 <= reg_ex_rs1;
    o_ex_ir_rs2 <= reg_ex_rs2;

    -- Memory Stage
    Memory_Pipeline: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' or i_mm_flush = '1' then
                reg_mm_rd <= (others => '0');
                reg_mm_arith_out <= (others => '0');
                reg_mm_b <= (others => '0');
                reg_mm_branch_taken <= '0';
                reg_mm_npc <= RESET_ADDR;
            elsif i_mm_stall = '0' then
                reg_mm_rd <= reg_mm_rd_next;
                reg_mm_arith_out <= reg_mm_arith_out_next;
                reg_mm_b <= reg_mm_b_next;
                reg_mm_branch_taken <= reg_mm_branch_taken_next;
                reg_mm_npc <= reg_mm_npc_next;
            end if;
        end if;
    end process Memory_Pipeline;

    LSU: LoadStoreUnit
        generic map (
            NBIT => NBIT,
            ADDR_WIDTH => ADDR_WIDTH)
        port map (
            i_address => reg_mm_arith_out,

            i_rd_request => i_mm_cw.rd_request,
            i_wr_request => i_mm_cw.wr_request,
            i_wr_data => reg_mm_b,

            i_data_type => i_mm_cw.data_type,

            o_data => reg_wb_mem_out_next,
            o_stall => o_mm_dc_stall,

            o_mem_address => o_dc_address,

            o_mem_rd_request => o_dc_rd_request,

            o_mem_wr_request => o_dc_wr_request,
            o_mem_wr_data => o_dc_wr_data,
            o_mem_wr_byte_sel => o_dc_wr_data_sel,

            i_mem_hit => i_dc_hit,
            i_mem_rd_data => i_dc_rd_data,

            o_misaligned_data => s_trap_wb_misaligned_data
        );

    reg_wb_rd_next <= reg_mm_rd;
    reg_wb_arith_out_next <= reg_mm_arith_out;
    reg_wb_npc_next <= reg_mm_npc;

    o_mm_ir_rd <= reg_mm_rd;


    -- Write Back Stage
    WriteBack_Pipeline: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' or i_wb_flush = '1' then
                reg_wb_rd <= (others => '0');
                reg_wb_arith_out <= (others => '0');
                reg_wb_mem_out <= (others => '0');
                reg_wb_npc <= RESET_ADDR;
            elsif i_wb_stall = '0' then
                reg_wb_rd <= reg_wb_rd_next;
                reg_wb_arith_out <= reg_wb_arith_out_next;
                reg_wb_mem_out <= reg_wb_mem_out_next;
                reg_wb_npc <= reg_wb_npc_next;
            end if;
        end if;
    end process WriteBack_Pipeline;

    with i_wb_cw.rf_wr_data_selection select s_wb_rf_input <=
    reg_wb_arith_out when RFInArithmetic,
    reg_wb_mem_out   when RFInMemory,
    reg_wb_npc       when RFInNextPC,
    reg_wb_mem_out   when others;


    -- When the instruction is jump and link, write to the link register
    -- (31, all ones); otherwise write to the destination register.
    s_wb_rf_rd <= (others => '1') when i_wb_cw.rf_sel_j_jal_n = '0' else
    reg_wb_rd;

    o_wb_ir_rd <= reg_wb_rd;
end Structural;
