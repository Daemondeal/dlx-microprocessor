library ieee;

use ieee.std_logic_1164.all;

use work.constants.all;
use work.control_word.all;

entity DLX is
    generic (
        NBIT: integer := 32;
        ADDR_WIDTH: integer := 32;
        RESET_ADDR: std_logic_vector(31 downto 0) := (others => '0');

        BTB_LINES_WIDTH: integer := 4;

        INSTRUCTION_CACHE_NSETS: integer := 2;
        INSTRUCTION_CACHE_WAYS: integer := 4;
        INSTRUCTION_CACHE_LINE_SIZE: integer := 16;

        DATA_CACHE_NSETS: integer := 2;
        DATA_CACHE_WAYS: integer := 4;
        DATA_CACHE_LINE_SIZE: integer := 16
    );
    port (
        -- synthesis translate_off
        i_debug_dump: in std_logic;
        -- synthesis translate_on

        i_wb_clk:  in std_logic;
        i_wb_rst:  in std_logic;

        i_wb_stall: in std_logic;
        i_wb_ack:   in std_logic;
        i_wb_err:   in std_logic;
        i_wb_data:  in std_logic_vector(NBIT-1 downto 0);

        o_wb_cyc:  out std_logic;
        o_wb_stb:  out std_logic;
        o_wb_we:   out std_logic;

        o_wb_addr: out std_logic_vector(ADDR_WIDTH-1 downto 0);
        o_wb_data: out std_logic_vector(NBIT-1 downto 0)
    );
end DLX;

architecture Structural of DLX is

    component MemorySystem is
        generic (
            NBIT: integer       := 32;
            ADDR_WIDTH: integer := 32;

            INSTRUCTION_CACHE_NSETS: integer := 2;
            INSTRUCTION_CACHE_WAYS: integer := 4;
            INSTRUCTION_CACHE_LINE_SIZE: integer := 16;

            DATA_CACHE_NSETS: integer := 2;
            DATA_CACHE_WAYS: integer := 4;
            DATA_CACHE_LINE_SIZE: integer := 16
        );

        port (
            -- Interface with the environment
            i_wb_clk: in std_logic;
            i_wb_rst: in std_logic;

            i_wb_stall: in std_logic;
            i_wb_ack:   in std_logic;
            i_wb_err:   in std_logic;
            i_wb_data:  in std_logic_vector(NBIT-1 downto 0);

            o_wb_cyc:  out std_logic;
            o_wb_stb:  out std_logic;
            o_wb_we:   out std_logic;

            o_wb_addr: out std_logic_vector(ADDR_WIDTH-1 downto 0);
            o_wb_data: out std_logic_vector(NBIT-1 downto 0);

            -- Interface with the datapath

            -- ic: Instruction Cache
            i_ic_addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);

            i_ic_rd_request: in  std_logic;
            o_ic_rd_data:    out std_logic_vector(NBIT-1 downto 0);

            o_ic_hit: out std_logic;

            -- dc: Data Cache
            i_dc_addr: in std_logic_vector(ADDR_WIDTH-1 downto 0);

            i_dc_rd_request: in  std_logic;
            o_dc_rd_data:    out std_logic_vector(NBIT-1 downto 0);

            i_dc_wr_request:  in std_logic;
            i_dc_wr_data:     in std_logic_vector(NBIT-1 downto 0);
            i_dc_wr_data_sel: in std_logic_vector((NBIT/8)-1 downto 0);

            o_dc_hit: out std_logic
        );
    end component MemorySystem;

    component DataPath is
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
    end component DataPath;

    component ControlUnit is
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
    end component ControlUnit;

    signal rst_n: std_logic;

    -- Fetch
    signal s_if_sel_pc_btb_npc_n: std_logic;

    signal s_id_cw: DecodeControlWord;
    signal s_ex_cw: ExecuteControlWord;
    signal s_mm_cw: MemoryControlWord;
    signal s_wb_cw: WriteBackControlWord;

    -- Execute
    signal s_ex_forward_a_sel: ForwardType;
    signal s_ex_forward_b_sel: ForwardType;

    -- Pipeline Signals
    signal s_if_stall: std_logic;
    signal s_id_stall: std_logic;
    signal s_ex_stall: std_logic;
    signal s_mm_stall: std_logic;
    signal s_wb_stall: std_logic;

    signal s_ex_multicycle_stall: std_logic;

    signal s_if_flush: std_logic;
    signal s_id_flush: std_logic;
    signal s_ex_flush: std_logic;
    signal s_mm_flush: std_logic;
    signal s_wb_flush: std_logic;

    -- Status Signals
    signal s_if_btb_predict_will_branch: std_logic;
    signal s_if_ic_hit: std_logic;

    signal s_id_ir_opcode: std_logic_vector(OPCODE_SIZE-1 downto 0);
    signal s_id_ir_func:   std_logic_vector(FUNC_SIZE-1 downto 0);


    signal s_ex_multicycle_busy: std_logic;
    signal s_ex_ir_rs1: std_logic_vector(REG_ADDR_SIZE-1 downto 0);
    signal s_ex_ir_rs2: std_logic_vector(REG_ADDR_SIZE-1 downto 0);

    signal s_mm_ir_rd: std_logic_vector(REG_ADDR_SIZE-1 downto 0);

    signal s_mm_btb_mispredict: std_logic;

    signal s_mm_dc_stall: std_logic;

    signal s_wb_ir_rd: std_logic_vector(REG_ADDR_SIZE-1 downto 0);


    -- Signals between Memory System and Datapath
    signal s_ic_address: std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal s_ic_rd_request: std_logic;
    signal s_ic_rd_data:    std_logic_vector(NBIT-1 downto 0);

    signal s_ic_hit: std_logic;

    signal s_dc_address: std_logic_vector(ADDR_WIDTH-1 downto 0);

    signal s_dc_rd_request: std_logic;
    signal s_dc_rd_data:    std_logic_vector(NBIT-1 downto 0);

    signal s_dc_wr_request:  std_logic;
    signal s_dc_wr_data:     std_logic_vector(NBIT-1 downto 0);
    signal s_dc_wr_data_sel: std_logic_vector((NBIT/8)-1 downto 0);

    signal s_dc_hit: std_logic;
begin
    rst_n <= not i_wb_rst;

    CU_Instance: ControlUnit
        port map (
            i_clk => i_wb_clk,
            i_rst_n => rst_n,

            o_if_sel_pc_btb_npc_n => s_if_sel_pc_btb_npc_n,

            o_ex_forward_a_sel => s_ex_forward_a_sel,
            o_ex_forward_b_sel => s_ex_forward_b_sel,

            o_id_cw => s_id_cw,
            o_ex_cw => s_ex_cw,
            o_mm_cw => s_mm_cw,
            o_wb_cw => s_wb_cw,

            -- Pipeline Signals
            o_if_stall => s_if_stall,
            o_id_stall => s_id_stall,
            o_ex_stall => s_ex_stall,
            o_mm_stall => s_mm_stall,
            o_wb_stall => s_wb_stall,

            o_ex_multicycle_stall => s_ex_multicycle_stall,

            o_if_flush => s_if_flush,
            o_id_flush => s_id_flush,
            o_ex_flush => s_ex_flush,
            o_mm_flush => s_mm_flush,
            o_wb_flush => s_wb_flush,

            -- Debug Signals

            -- synthesis translate_off
            i_debug_dump => i_debug_dump,
            -- synthesis translate_on

            -- Status Signals
            i_if_btb_predict_will_branch => s_if_btb_predict_will_branch,
            i_if_ic_hit => s_if_ic_hit,

            i_id_ir_opcode => s_id_ir_opcode,
            i_id_ir_func => s_id_ir_func,


            i_ex_multicycle_busy => s_ex_multicycle_busy,
            i_ex_ir_rs1 => s_ex_ir_rs1,
            i_ex_ir_rs2 => s_ex_ir_rs2,

            i_mm_ir_rd => s_mm_ir_rd,

            i_mm_btb_mispredict => s_mm_btb_mispredict,

            i_mm_dc_stall => s_mm_dc_stall,

            i_wb_ir_rd => s_wb_ir_rd
        );


    DP_Instance: DataPath
        generic map (
            NBIT => NBIT,
            ADDR_WIDTH => ADDR_WIDTH,
            BTB_LINES_WIDTH => BTB_LINES_WIDTH,
            RESET_ADDR => RESET_ADDR
        )
        port map (
            i_clk => i_wb_clk,
            i_rst_n => rst_n,

            -- Control signals coming from CU
            i_if_sel_pc_btb_npc_n => s_if_sel_pc_btb_npc_n,

            i_id_cw => s_id_cw,
            i_ex_cw => s_ex_cw,
            i_mm_cw => s_mm_cw,
            i_wb_cw => s_wb_cw,

            i_ex_forward_a_sel => s_ex_forward_a_sel,
            i_ex_forward_b_sel => s_ex_forward_b_sel,

            -- Pipeline Signals
            i_if_stall => s_if_stall,
            i_id_stall => s_id_stall,
            i_ex_stall => s_ex_stall,
            i_mm_stall => s_mm_stall,
            i_wb_stall => s_wb_stall,

            i_ex_multicycle_stall => s_ex_multicycle_stall,

            i_if_flush => s_if_flush,
            i_id_flush => s_id_flush,
            i_ex_flush => s_ex_flush,
            i_mm_flush => s_mm_flush,
            i_wb_flush => s_wb_flush,

            -- Status signals towards CU
            o_if_btb_predict_will_branch => s_if_btb_predict_will_branch,
            o_if_ic_hit => s_if_ic_hit,

            o_id_ir_opcode => s_id_ir_opcode,
            o_id_ir_func => s_id_ir_func,


            o_ex_ir_rs1 => s_ex_ir_rs1,
            o_ex_ir_rs2 => s_ex_ir_rs2,

            o_mm_ir_rd => s_mm_ir_rd,
            o_ex_multicycle_busy => s_ex_multicycle_busy,

            o_mm_btb_mispredict => s_mm_btb_mispredict,

            o_mm_dc_stall => s_mm_dc_stall,

            o_wb_ir_rd => s_wb_ir_rd,

            -- Signals between Memory System and Datapath
            o_ic_address => s_ic_address,

            o_ic_rd_request => s_ic_rd_request,
            i_ic_rd_data => s_ic_rd_data,

            i_ic_hit => s_ic_hit,

            o_dc_address => s_dc_address,

            o_dc_rd_request => s_dc_rd_request,
            i_dc_rd_data => s_dc_rd_data,

            o_dc_wr_request => s_dc_wr_request,
            o_dc_wr_data => s_dc_wr_data,
            o_dc_wr_data_sel => s_dc_wr_data_sel,

            i_dc_hit => s_dc_hit
        );

    MS_Instance: MemorySystem
        generic map (
            NBIT => NBIT,
            ADDR_WIDTH => ADDR_WIDTH,

            INSTRUCTION_CACHE_NSETS => INSTRUCTION_CACHE_NSETS,
            INSTRUCTION_CACHE_WAYS => INSTRUCTION_CACHE_WAYS,
            INSTRUCTION_CACHE_LINE_SIZE => INSTRUCTION_CACHE_LINE_SIZE,

            DATA_CACHE_NSETS => DATA_CACHE_NSETS,
            DATA_CACHE_WAYS => DATA_CACHE_WAYS,
            DATA_CACHE_LINE_SIZE => DATA_CACHE_LINE_SIZE
        )
        port map (
            -- Interface with the environment
            i_wb_clk => i_wb_clk,
            i_wb_rst => i_wb_rst,

            i_wb_stall => i_wb_stall,
            i_wb_ack => i_wb_ack,
            i_wb_err => i_wb_err,
            i_wb_data => i_wb_data,

            o_wb_cyc => o_wb_cyc,
            o_wb_stb => o_wb_stb,
            o_wb_we => o_wb_we,

            o_wb_addr => o_wb_addr,
            o_wb_data => o_wb_data,

            -- Interface with the datapath

            -- ic: Instruction Cache
            i_ic_addr => s_ic_address,

            i_ic_rd_request => s_ic_rd_request,
            o_ic_rd_data => s_ic_rd_data,

            o_ic_hit => s_ic_hit,

            -- dc: Data Cache
            i_dc_addr => s_dc_address,

            i_dc_rd_request => s_dc_rd_request,
            o_dc_rd_data => s_dc_rd_data,

            i_dc_wr_request => s_dc_wr_request,
            i_dc_wr_data => s_dc_wr_data,
            i_dc_wr_data_sel => s_dc_wr_data_sel,

            o_dc_hit => s_dc_hit
        );

end Structural;
