ITYPE_ADDI = 0x08
ITYPE_ADDUI = 0x09
ITYPE_SUBI = 0x0A
ITYPE_SUBUI = 0x0B
ITYPE_BEQZ = 0x04
ITYPE_BNEZ = 0x05
ITYPE_JALR = 0x13
ITYPE_JR = 0x12
ITYPE_SEQI = 0x18
ITYPE_SGEI = 0x1D
ITYPE_SGEUI = 0x3D
ITYPE_SGTI = 0x1B
ITYPE_SGTUI = 0x3B
ITYPE_SLEI = 0x1C
ITYPE_SLEUI = 0x3C
ITYPE_SLTI = 0x1A
ITYPE_SLTUI = 0x3A
ITYPE_SNEI = 0x19
ITYPE_ANDI = 0x0C
ITYPE_ORI = 0x0D
ITYPE_XORI = 0x0E
ITYPE_LB = 0x20
ITYPE_LBU = 0x24
ITYPE_LH = 0x21
ITYPE_LHU = 0x25
ITYPE_LW = 0x23
ITYPE_SB = 0x28
ITYPE_SH = 0x29
ITYPE_SW = 0x2B
ITYPE_LHI = 0x0F
ITYPE_NOP = 0x15
ITYPE_SLLI = 0x14
ITYPE_SRAI = 0x17
ITYPE_SRLI = 0x16
JTYPE_J = 0x02
JTYPE_JAL = 0x03
FUNC_ADD = 0x20
FUNC_ADDU = 0x21
FUNC_SUB = 0x22
FUNC_SUBU = 0x23
FUNC_SEQ = 0x28
FUNC_SGE = 0x2D
FUNC_SGEU = 0x3D
FUNC_SGT = 0x2B
FUNC_SGTU = 0x3B
FUNC_SLE = 0x2C
FUNC_SLEU = 0x3C
FUNC_SLT = 0x2A
FUNC_SLTU = 0x3A
FUNC_SNE = 0x29
FUNC_AND = 0x24
FUNC_OR = 0x25
FUNC_XOR = 0x26
FUNC_SLL = 0x04
FUNC_SRA = 0x07
FUNC_SRL = 0x06
FUNC_IMUL = 0x3F
FUNC_IDIV = 0x38
FUNC_IMOD = 0x39
RTYPE_OP = 0x0

OPS_NAME = {
    8: "addi",
    9: "addui",
    10: "subi",
    11: "subui",
    4: "beqz",
    5: "bnez",
    19: "jalr",
    18: "jr",
    24: "seqi",
    29: "sgei",
    61: "sgeui",
    27: "sgti",
    59: "sgtui",
    28: "slei",
    60: "sleui",
    26: "slti",
    58: "sltui",
    25: "snei",
    12: "andi",
    13: "ori",
    14: "xori",
    32: "lb",
    36: "lbu",
    33: "lh",
    37: "lhu",
    35: "lw",
    40: "sb",
    41: "sh",
    43: "sw",
    15: "lhi",
    21: "nop",
    20: "slli",
    23: "srai",
    22: "srli",
    2: "j",
    3: "jal",
}
FUNC_NAME = {
    32: "add",
    33: "addu",
    34: "sub",
    35: "subu",
    40: "seq",
    45: "sge",
    61: "sgeu",
    43: "sgt",
    59: "sgtu",
    44: "sle",
    60: "sleu",
    42: "slt",
    58: "sltu",
    41: "sne",
    36: "and",
    37: "or",
    38: "xor",
    4: "sll",
    7: "sra",
    6: "srl",
    63: "imul",
    56: "idiv",
    57: "imod",
}
