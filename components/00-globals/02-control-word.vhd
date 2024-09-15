library ieee;

use ieee.std_logic_1164.all;

use work.constants.all;

package control_word is
    type JumpConditionType is (JumpIfZero, JumpIfNotZero, Always, Never);
    type DataType          is (Word, Halfword, Byte, HalfwordSigned, ByteSigned);

    type ArithmeticOutputType is (OutALU, OutMulticycle);
    type RFInputType is (RFInArithmetic, RFInMemory, RFInNextPC);
    type MulticycleOpType is (MulticycleNone, MulticycleMultiply, MulticycleDivide, MulticycleModulo);

    type DecodeControlWord is record
        sel_imm_unsigned_signed_n: std_logic;
        instruction_type: InstructionType;
    end record DecodeControlWord;

    type ExecuteControlWord is record
        sel_in1_a_npc_n: std_logic;
        sel_in2_b_imm_n: std_logic;

        sel_arithmetic: ArithmeticOutputType;
        multicycle_op: MulticycleOpType;

        alu_operation: AluOperationType;
        branch_type: JumpConditionType;

    end record ExecuteControlWord;

    type MemoryControlWord is record
        rd_request: std_logic;
        wr_request: std_logic;

        data_type: DataType;
    end record MemoryControlWord;

    type WriteBackControlWord is record
        rf_wr_enable: std_logic;
        rf_wr_data_selection: RFInputType;
        rf_sel_j_jal_n: std_logic;
    end record WriteBackControlWord;

end package;

