#!/bin/python3

from codegen_lib import *
import csv


class Opcode:
    def __init__(self, name, itype, code, control_word):
        self.name = name
        self.itype = itype
        self.code = code
        self.control_word = control_word

    def __repr__(self):
        return f"Opcode(name={self.name},itype={self.itype},code={self.code})"

    def full_name(self):
        if self.itype == "RType":
            return f"FUNC_{self.name}".upper()
        else:
            return f"{self.itype}_{self.name}".upper()

    def op_name(self):
        return f"{self.name}_op"


mappings = {
    "id_immediate_type": {
        "name": "o_cw_id.sel_imm_unsigned_signed_n",
        "type": StandardLogic(),
        "values": {
            "Don't Care": "'-'",
            "Signed": "'0'",
            "Unsigned": "'1'",
            "Default": "'0'",
        },
    },
    "Instruction Type": {
        "name": "o_cw_id.instruction_type",
        "type": VhdlType("InstructionType"),
        "values": {
            "R-Type": "RType",
            "I-Type": "IType",
            "J-Type": "JType",
            "Default": "RType",
        },
    },
    "ex_in1_a_npc_n": {
        "name": "o_cw_ex.sel_in1_a_npc_n",
        "type": StandardLogic(),
        "values": {"Don't Care": "'-'", "A": "'1'", "NPC": "'0'", "Default": "'0'"},
    },
    "ex_in2_b_imm_n": {
        "name": "o_cw_ex.sel_in2_b_imm_n",
        "type": StandardLogic(),
        "values": {
            "Don't Care": "'-'",
            "B": "'1'",
            "Immediate": "'0'",
            "Default": "'0'",
        },
    },
    "ex_sel_arith": {
        "name": "o_cw_ex.sel_arithmetic",
        "type": VhdlType("ArithmeticOutputType"),
        "values": {
            "Don't Care": "OutALU",
            "Multicycle": "OutMulticycle",
            "ALU": "OutALU",
            "Default": "OutALU",
        },
    },
    "ex_multicycle_op": {
        "name": "o_cw_ex.multicycle_op",
        "type": VhdlType("MulticycleOpType"),
        "values": {
            "None": "MulticycleNone",
            "Multiply": "MulticycleMultiply",
            "Divide": "MulticycleDivide",
            "Modulo": "MulticycleModulo",
            "Default": "MulticycleNone",
        },
    },
    "ex_alu_op": {
        "name": "o_cw_ex.alu_operation",
        "type": VhdlType("AluOperationType"),
        "values": {
            "nop": "alu_nop",
            "add": "alu_add",
            "sub": "alu_sub",
            "sll": "alu_sll",
            "srl": "alu_srl",
            "sra": "alu_sra",
            "and": "alu_and",
            "xor": "alu_xor",
            "or": "alu_or",
            "seq": "alu_seq",
            "sne": "alu_sne",
            "sge": "alu_sge",
            "sgeu": "alu_sgeu",
            "sgt": "alu_sgt",
            "sgtu": "alu_sgtu",
            "sle": "alu_sle",
            "sleu": "alu_sleu",
            "slt": "alu_slt",
            "sltu": "alu_sltu",
            "lhi": "alu_lhi",
            "Default": "alu_nop",
        },
    },
    "ex_branch_type": {
        "name": "o_cw_ex.branch_type",
        "type": VhdlType("JumpConditionType"),
        "values": {
            "JumpIfZero": "JumpIfZero",
            "JumpIfNotZero": "JumpIfNotZero",
            "Never": "Never",
            "Always": "Always",
            "Default": "Never",
        },
    },
    "mm_rd_request": {
        "name": "o_cw_mm.rd_request",
        "type": StandardLogic(),
        "values": {
            "TRUE": "'1'",
            "FALSE": "'0'",
            "Default": "'0'",
        },
    },
    "mm_wr_request": {
        "name": "o_cw_mm.wr_request",
        "type": StandardLogic(),
        "values": {
            "TRUE": "'1'",
            "FALSE": "'0'",
            "Default": "'0'",
        },
    },
    "mm_data_type": {
        "name": "o_cw_mm.data_type",
        "type": VhdlType("DataType"),
        "values": {
            "Word": "Word",
            "Halfword": "Halfword",
            "Byte": "Byte",
            "Signed Halfword": "HalfwordSigned",
            "Signed Byte": "ByteSigned",
            "Default": "Word",
        },
    },
    "wb_rf_wr_enable": {
        "name": "o_cw_wb.rf_wr_enable",
        "type": StandardLogic(),
        "values": {
            "TRUE": "'1'",
            "FALSE": "'0'",
            "Default": "'0'",
        },
    },
    "wb_rf_datain": {
        "name": "o_cw_wb.rf_wr_data_selection",
        "type": VhdlType("RFInputType"),
        "values": {
            "Don't Care": "RFInArithmetic",
            "Arithmetic": "RFInArithmetic",
            "Memory": "RFInMemory",
            "NPC": "RFInNextPC",
            "Default": "RFInArithmetic",
        },
    },
    "wb_is_jal": {
        "name": "o_cw_wb.rf_sel_j_jal_n",
        "type": StandardLogic(),
        "values": {
            "TRUE": "'0'",
            "FALSE": "'1'",
            "Default": "'0'",
        },
    },
}


def get_ops(instructions_filename):
    ops = []
    with open(instructions_filename, "r") as ifile:
        reader = csv.DictReader(ifile)
        for row in reader:
            if row["Category"] == "Unimplemented" or row["Category"] == "":
                continue

            skip = False
            control_word = []
            for category in mappings:
                row_val = row[category]
                if row_val not in mappings[category]["values"].keys():
                    print(f"WARNING: Skipping [{row['Mnemonic']}] (missing {category})")
                    skip = True
                    break

                signal_name = mappings[category]["name"]
                value = mappings[category]["values"][row_val]
                control_word.append((signal_name, value))

            if skip:
                continue

            itype = mappings["Instruction Type"]["values"][row["Instruction Type"]]

            op = Opcode(
                row["Mnemonic"],
                itype,
                int(row["Opcode/Func"], 16),
                control_word=control_word,
            )
            ops.append(op)
    return ops


def codegen_decoder(ops):
    ports = [
        PortSignal("i_opcode", StandardLogicVector("OPCODE_SIZE"), "in"),
        PortSignal("i_func", StandardLogicVector("FUNC_SIZE"), "in"),
        PortSignal("o_cw_id", VhdlType("DecodeControlWord"), "out"),
        PortSignal("o_cw_ex", VhdlType("ExecuteControlWord"), "out"),
        PortSignal("o_cw_mm", VhdlType("MemoryControlWord"), "out"),
        PortSignal("o_cw_wb", VhdlType("WriteBackControlWord"), "out"),
    ]

    for control_signal_name in mappings:
        signal = mappings[control_signal_name]
        # ports.append(PortSignal(signal["name"], signal["type"], "out"))

    cases = []
    cases_rtype = []

    for op in ops:
        if op.itype != "RType":
            cases.append(
                (op.full_name(), [SignalAssignment(s, v) for s, v in op.control_word])
            )
        else:
            cases_rtype.append(
                (op.full_name(), [SignalAssignment(s, v) for s, v in op.control_word])
            )

    defaults = []
    for category in mappings:
        name = mappings[category]["name"]
        value = mappings[category]["values"]["Default"]
        defaults.append(SignalAssignment(name, value))

    rtype_decode_case = Case(signal="i_func", cases=cases_rtype, others=defaults)
    decode_case = Case(
        signal="i_opcode",
        cases=[("RTYPE_OP", [rtype_decode_case])] + cases,
        others=defaults,
    )

    decoder = Module(
        name="InstructionDecoder",
        libraries=[
            Library("ieee.std_logic_1164"),
            Library("work.constants"),
            Library("work.instructions"),
            Library("work.control_word"),
        ],
        ports=ports,
        defines=[],
        body=[Process(sensitivity=["i_opcode", "i_func"], body=[decode_case])],
    )
    return decoder.codegen()


def codegen_instructions(ops):
    rtype = Statement(
        'constant RTYPE_OP: std_logic_vector(OPCODE_SIZE-1 downto 0) := "000000"; -- (0x00)'
    )

    constants = [rtype]
    for op in ops:
        if op.itype == "RType":
            stmt = (
                f"constant {op.full_name()}: std_logic_vector(FUNC_SIZE-1 downto 0) := "
            )
            stmt += f'"{op.code:011b}";'
        else:
            stmt = f"constant {op.full_name()}: std_logic_vector(OPCODE_SIZE-1 downto 0) := "
            stmt += f'"{op.code:06b}";'

        stmt += f" -- (0x{op.code:02X})"

        constants.append(Statement(stmt))

    opcodes = ", ".join([op.op_name() for op in ops] + ["invalid_op"])
    opcode_type_def = Statement(f"type OpcodeType is ({opcodes})")

    cases_rtype = []
    cases = []

    for op in ops:
        if op.itype != "RType":
            cases.append((op.full_name(), [Statement(f"return {op.op_name()}")]))
        else:
            cases_rtype.append((op.full_name(), [Statement(f"return {op.op_name()}")]))

    rtype_decode_case = Case(
        signal="i_func", cases=cases_rtype, others=[Statement("return invalid_op")]
    )
    decode_case = Case(
        signal="i_opcode",
        cases=[("RTYPE_OP", [rtype_decode_case])] + cases,
        others=[Statement("return invalid_op")],
    )

    slv_to_opcode = Function(
        name="slv_to_opcode",
        inputs=[
            PortSignal("i_opcode", StandardLogicVector("OPCODE_SIZE"), "in"),
            PortSignal("i_func", StandardLogicVector("FUNC_SIZE"), "in"),
        ],
        retval=VhdlType("OpcodeType"),
        body=[decode_case],
    )

    package = Package(
        libraries=[Library("ieee.std_logic_1164"), Library("work.constants")],
        name="instructions",
        header=constants + [opcode_type_def] + [slv_to_opcode.get_header()],
        body=[slv_to_opcode],
    )

    return package.codegen()


def codegen_emulator_opcodes(ops):
    result = ""

    for op in ops:
        result += f"{op.full_name()} = 0x{op.code:02X}\n"

    result += f"RTYPE_OP = 0x0\n"

    result += "\n"

    result += "OPS_NAME = {\n"
    for op in ops:
        if op.itype != "RType":
            result += f'    {op.code}: "{op.name}",\n'

    result += "}\nFUNC_NAME = {\n"
    for op in ops:
        if op.itype == "RType":
            result += f'    {op.code}: "{op.name}",\n'
    result += "}\n"

    return result


def main():
    ops = get_ops("./dlx-uops.csv")

    with open(
        "../components/04-control-unit/01-InstructionDecoder.vhd", "w"
    ) as decoder_file:
        decoder_file.write(codegen_decoder(ops))

    with open("../components/00-globals/02-instructions.vhd", "w") as instructions_file:
        instructions_file.write(codegen_instructions(ops))

    with open("../sim/emulator/dlx_instructions.py", "w") as python_em_file:
        python_em_file.write(codegen_emulator_opcodes(ops))


if __name__ == "__main__":
    main()
