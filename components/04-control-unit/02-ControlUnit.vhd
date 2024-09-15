library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.instructions.all;
use work.control_word.all;

entity ControlUnit is
    port (
        i_clk, i_rst_n: in std_logic;

        -- Control Signals

        -- Fetch
        o_if_sel_pc_btb_npc_n: out std_logic;

        -- Decode
        o_id_cw: out DecodeControlWord;

        -- Execute
        o_ex_forward_a_sel: out ForwardType;
        o_ex_forward_b_sel: out ForwardType;

        o_ex_cw: out ExecuteControlWord;

        -- Memory
        o_mm_cw: out MemoryControlWord;

        -- Write Back
        o_wb_cw: out WriteBackControlWord;

        -- Pipeline Signals
        o_if_stall: out std_logic;
        o_id_stall: out std_logic;
        o_ex_stall: out std_logic;
        o_mm_stall: out std_logic;
        o_wb_stall: out std_logic;

        o_ex_multicycle_stall: out std_logic;

        o_if_flush: out std_logic;
        o_id_flush: out std_logic;
        o_ex_flush: out std_logic;
        o_mm_flush: out std_logic;
        o_wb_flush: out std_logic;

        -- Debug Signals

        -- synthesis translate_off
        i_debug_dump: in std_logic;
        -- synthesis translate_on

        -- Status Signals
        i_if_btb_predict_will_branch: in std_logic;
        i_if_ic_hit: in std_logic;

        i_id_ir_opcode: in std_logic_vector(OPCODE_SIZE-1 downto 0);
        i_id_ir_func:   in std_logic_vector(FUNC_SIZE-1 downto 0);


        i_ex_multicycle_busy: in std_logic;
        i_ex_ir_rs1: in std_logic_vector(REG_ADDR_SIZE-1 downto 0);
        i_ex_ir_rs2: in std_logic_vector(REG_ADDR_SIZE-1 downto 0);

        i_mm_ir_rd: in std_logic_vector(REG_ADDR_SIZE-1 downto 0);

        i_mm_btb_mispredict: in std_logic;

        i_mm_dc_stall: in std_logic;

        i_wb_ir_rd: in std_logic_vector(REG_ADDR_SIZE-1 downto 0)
    );
end entity ControlUnit;

architecture Behavioral of ControlUnit is

    component InstructionDecoder is
        port (
            i_opcode: in  std_logic_vector(OPCODE_SIZE-1 downto 0);
            i_func: in  std_logic_vector(FUNC_SIZE-1 downto 0);
            o_cw_id: out DecodeControlWord;
            o_cw_ex: out ExecuteControlWord;
            o_cw_mm: out MemoryControlWord;
            o_cw_wb: out WriteBackControlWord);
    end component InstructionDecoder;

    signal s_if_stall: std_logic;
    signal s_id_stall: std_logic;
    signal s_ex_stall: std_logic;
    signal s_mm_stall: std_logic;
    signal s_wb_stall: std_logic;

    signal s_if_flush: std_logic;
    signal s_id_flush: std_logic;
    signal s_ex_flush: std_logic;
    signal s_mm_flush: std_logic;
    signal s_wb_flush: std_logic;


    -- Decode Stage
    signal id_cw: DecodeControlWord;

    -- Skewing signals for further control words
    signal id_skew_cw_ex: ExecuteControlWord;
    signal id_skew_cw_mm: MemoryControlWord;
    signal id_skew_cw_wb: WriteBackControlWord;

    -- Execute Stage
    signal ex_cw: ExecuteControlWord;

    signal ex_skew_cw_mm: MemoryControlWord;
    signal ex_skew_cw_wb: WriteBackControlWord;

    -- Memory Stage
    signal mm_cw: MemoryControlWord;

    signal mm_skew_cw_wb: WriteBackControlWord;

    -- WriteBack Stage
    signal wb_cw: WriteBackControlWord;

    -- STALL: After we do a load we cannot forward the result
    --        until the load is actually done, so we have to stall
    --        while the load is still in the memory stage.
    signal s_stall_mem_dest_in_mm: std_logic;


    -- synthesis translate_off
    signal s_debug_id_op: OpcodeType;
    signal s_debug_ex_op: OpcodeType;
    signal s_debug_mm_op: OpcodeType;
    signal s_debug_wb_op: OpcodeType;

    signal s_debug_instructions_ran: integer := 0;
-- synthesis translate_on
begin

    HazardControl: process (
            i_mm_dc_stall,
            i_if_ic_hit,
            i_mm_btb_mispredict,
            i_ex_multicycle_busy,
            s_stall_mem_dest_in_mm
        )
    begin
        s_if_stall <= '0';
        s_id_stall <= '0';
        s_ex_stall <= '0';
        s_mm_stall <= '0';
        s_wb_stall <= '0';

        o_ex_multicycle_stall <= '0';

        s_if_flush <= '0';
        s_id_flush <= '0';
        s_ex_flush <= '0';
        s_mm_flush <= '0';
        s_wb_flush <= '0';

        if (i_mm_dc_stall = '1') then
            s_if_stall <= '1';
            s_id_stall <= '1';
            s_ex_stall <= '1';
            s_mm_stall <= '1';

            o_ex_multicycle_stall <= '1';

            -- We must stall wb and not let it go through because
            -- otherwise forwarding in ex stage would fail.
            -- (If we're forwarding from wb in the cycle the d$ misses,
            --  then flushing wb would lose the operand for the ex stage)
            s_wb_stall <= '1';
        else
            if (i_if_ic_hit = '0') then
                if (i_mm_btb_mispredict = '1') then
                    s_if_stall <= '1';
                    s_id_stall <= '1';
                    s_ex_stall <= '1';
                    s_mm_stall <= '1';
                    s_wb_stall <= '1';

                    o_ex_multicycle_stall <= '1';
                else
                    if (s_stall_mem_dest_in_mm = '1' or i_ex_multicycle_busy = '1') then
                        s_if_stall <= '1';
                        s_id_stall <= '1';
                        s_ex_stall <= '1';
                        s_mm_stall <= '1';
                        s_wb_stall <= '1';

                        o_ex_multicycle_stall <= '0';

                    else
                        s_if_stall <= '1';
                        s_id_flush <= '1';
                    end if;
                end if;
            elsif (i_mm_btb_mispredict = '1') then
                -- WHEN EX FLUSH CLEAR THE MULTIPLIER
                s_id_flush <= '1';
                s_ex_flush <= '1';
                s_mm_flush <= '1';
            elsif (s_stall_mem_dest_in_mm = '1') then
                -- Stall caused by memory loads
                s_if_stall <= '1';
                s_id_stall <= '1';
                s_ex_stall <= '1';
                s_mm_flush <= '1';

                o_ex_multicycle_stall <= '1';
            elsif (i_ex_multicycle_busy = '1') then
                s_if_stall <= '1';
                s_id_stall <= '1';
                s_ex_stall <= '1';
                s_mm_stall <= '1';
                s_wb_stall <= '1';

                o_ex_multicycle_stall <= '0';

            end if;
        end if;
    end process HazardControl;


    ForwardUnit: process (
            i_ex_ir_rs1, i_ex_ir_rs2,
            i_mm_ir_rd, i_wb_ir_rd,
            mm_skew_cw_wb, wb_cw, mm_cw
        )
        variable is_mm_writing_to_rf, is_wb_writing_to_rf: boolean;
        variable is_load_from_mem_happening: boolean;

        variable effective_mm_reg: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
        variable effective_wb_reg: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
        variable link_register_addr: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    begin
        s_stall_mem_dest_in_mm <= '0';
        is_mm_writing_to_rf := mm_skew_cw_wb.rf_wr_enable = '1';
        is_wb_writing_to_rf := wb_cw.rf_wr_enable = '1';
        is_load_from_mem_happening := mm_cw.rd_request = '1';

        link_register_addr := (others => '1');

        if mm_skew_cw_wb.rf_sel_j_jal_n = '0' then
            effective_mm_reg := link_register_addr;
        else
            effective_mm_reg := i_mm_ir_rd;
        end if;

        if wb_cw.rf_sel_j_jal_n = '0' then
            effective_wb_reg := link_register_addr;
        else
            effective_wb_reg := i_wb_ir_rd;
        end if;

        if i_ex_ir_rs1 = effective_mm_reg and is_mm_writing_to_rf then
            if is_load_from_mem_happening then
                -- We cannot forward, since we need to wait for the memory
                s_stall_mem_dest_in_mm <= '1';
            end if;

            o_ex_forward_a_sel <= ForwardMemoryStage;
        elsif i_ex_ir_rs1 = effective_wb_reg and is_wb_writing_to_rf then
            o_ex_forward_a_sel <= ForwardWritebackStage;
        else
            o_ex_forward_a_sel <= NoForward;
        end if;

        if i_ex_ir_rs2 = effective_mm_reg and is_mm_writing_to_rf then
            if is_load_from_mem_happening then
                -- We cannot forward, since we need to wait for the memory
                s_stall_mem_dest_in_mm <= '1';
            end if;
            o_ex_forward_b_sel <= ForwardMemoryStage;
        elsif i_ex_ir_rs2 = effective_wb_reg and is_wb_writing_to_rf then
            o_ex_forward_b_sel <= ForwardWritebackStage;
        else
            o_ex_forward_b_sel <= NoForward;
        end if;
    end process ForwardUnit;

    DecoderInstance: InstructionDecoder
        port map (
            i_opcode => i_id_ir_opcode,
            i_func => i_id_ir_func,

            o_cw_id => id_cw,
            o_cw_ex => id_skew_cw_ex,
            o_cw_mm => id_skew_cw_mm,
            o_cw_wb => id_skew_cw_wb
        );


    -- Control Signal Assignments
    o_if_stall <= s_if_stall;
    o_id_stall <= s_id_stall;
    o_ex_stall <= s_ex_stall;
    o_mm_stall <= s_mm_stall;
    o_wb_stall <= s_wb_stall;

    o_if_flush <= s_if_flush;
    o_id_flush <= s_id_flush;
    o_ex_flush <= s_ex_flush;
    o_mm_flush <= s_mm_flush;
    o_wb_flush <= s_wb_flush;

    o_if_sel_pc_btb_npc_n <= (i_if_btb_predict_will_branch or i_mm_btb_mispredict);

    o_id_cw <= id_cw;
    o_ex_cw <= ex_cw;
    o_mm_cw <= mm_cw;
    o_wb_cw <= wb_cw;

    -- synthesis translate_off
    s_debug_id_op <= slv_to_opcode(i_id_ir_opcode, i_id_ir_func);
    -- synthesis translate_on

    Pipe_Execute: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if (s_ex_flush = '1' or i_rst_n = '0') then
                ex_cw <= (
                    sel_in1_a_npc_n => '1',
                    sel_in2_b_imm_n => '1',

                    sel_arithmetic => OutALU,
                    multicycle_op => MulticycleNone,

                    alu_operation => alu_add,
                    branch_type => Never
                );

                ex_skew_cw_mm <= (
                    rd_request => '0',
                    wr_request => '0',
                    data_type => Word
                );

                ex_skew_cw_wb <= (
                    rf_wr_enable => '0',
                    rf_wr_data_selection => RFInArithmetic,
                    rf_sel_j_jal_n => '0'
                );

                -- synthesis translate_off
                s_debug_ex_op <= nop_op;
            -- synthesis translate_on

            elsif (s_ex_stall = '0') then
                ex_cw <= id_skew_cw_ex;
                ex_skew_cw_mm <= id_skew_cw_mm;
                ex_skew_cw_wb <= id_skew_cw_wb;

                -- synthesis translate_off
                s_debug_ex_op <= s_debug_id_op;
            -- synthesis translate_on
            end if;
        end if;
    end process Pipe_Execute;

    Pipe_Memory: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if s_mm_flush = '1' or i_rst_n = '0' then
                mm_cw <= (
                    rd_request => '0',
                    wr_request => '0',
                    data_type => Word
                );

                mm_skew_cw_wb <= (
                    rf_wr_enable => '0',
                    rf_wr_data_selection => RFInArithmetic,
                    rf_sel_j_jal_n => '0'
                );

                -- synthesis translate_off
                s_debug_mm_op <= nop_op;
            -- synthesis translate_on
            elsif s_mm_stall = '0' then
                mm_cw <= ex_skew_cw_mm;
                mm_skew_cw_wb <= ex_skew_cw_wb;

                -- synthesis translate_off
                s_debug_mm_op <= s_debug_ex_op;
            -- synthesis translate_on
            end if;
        end if;
    end process Pipe_Memory;

    Pipe_WriteBack: process (i_clk)
    begin
        if rising_edge(i_clk) then

            -- synthesis translate_off
            -- We count instructions ran as instructions that
            -- get outside the Write Back stage and are not nops
            if i_rst_n = '1' and s_wb_stall = '0' and s_debug_wb_op /= nop_op then
                s_debug_instructions_ran <= s_debug_instructions_ran + 1;
                report "[" & integer'image(s_debug_instructions_ran) & "] "
                & OpcodeType'image(s_debug_wb_op);
            end if;
            -- synthesis translate_on

            if s_wb_flush = '1' or i_rst_n = '0' then
                wb_cw <= (
                    rf_wr_enable => '0',
                    rf_wr_data_selection => RFInArithmetic,
                    rf_sel_j_jal_n => '0'
                );

                -- synthesis translate_off
                s_debug_wb_op <= nop_op;
            -- synthesis translate_on
            elsif s_wb_stall = '0' then
                wb_cw <= mm_skew_cw_wb;

                -- synthesis translate_off

                s_debug_wb_op <= s_debug_mm_op;
            -- synthesis translate_on
            end if;
        end if;
    end process Pipe_WriteBack;

    -- synthesis translate_off
    DumpProc: process (i_debug_dump)
        variable instruction_count: integer;
    begin
        if rising_edge(i_debug_dump) then
            -- NOTE: The last instruction that writes to the bus the stop address won't be counted, so we do +1.
            instruction_count := s_debug_instructions_ran + 1;

            -- The instruction following the sw won't be counted as well,
            -- so we must count it here if it's not a nop
            if s_debug_wb_op /= nop_op then
                instruction_count := instruction_count + 1;
            end if;

            report "Instructions ran: " & integer'image(instruction_count);
        end if;
    end process DumpProc;
-- synthesis translate_on

end Behavioral;
