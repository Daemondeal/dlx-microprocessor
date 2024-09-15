library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package constants is
    type InstructionType   is (RType, IType, JType);
    type ForwardType is (NoForward, ForwardMemoryStage, ForwardWritebackStage);

    type AluOperationType is (alu_nop, alu_add, alu_sub, alu_sll, alu_srl, alu_sra, alu_and, alu_xor, alu_or, alu_seq, alu_sne, alu_sge, alu_sgeu, alu_sgt, alu_sgtu, alu_sle, alu_sleu, alu_slt, alu_sltu, alu_lhi);

    type ShiftType is (shift_left_l, shift_right_l, shift_right_a);

    -- Size of the instrucition
    constant I_SIZE: integer  := 32;

    -- Number bits needed to address instructions in the IRAM
    constant IRAM_ADDR_WIDTH: integer:= 8;

    -- Bits needed for addressing registers 
    constant REG_ADDR_SIZE: integer := 5;

    -- Bits for the opcode
    constant OPCODE_SIZE: integer := 6;

    -- Bits for the immediate (I-Type)
    constant IMM_I_SIZE: integer := 16;

    -- Bits for the immediate (J-Type)
    constant IMM_J_SIZE: integer := 26;

    -- Bits for the func (R-Type)
    constant FUNC_SIZE: integer := 11;

    constant DATAMEM_ADDR_SIZE: integer := 8;

    -- Full NOP instruction
    constant NOP_INSTR: std_logic_vector(I_SIZE-1 downto 0) := x"54000000";
end constants;

