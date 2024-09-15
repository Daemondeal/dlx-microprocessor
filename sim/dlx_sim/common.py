import dlx_instructions as inst
import re

ANSI_RED = "\033[31m"
ANSI_GREEN = "\033[32m"
ANSI_YELLOW = "\033[33m"

ANSI_RESET = "\033[0m"

class StallCharacteristics:
    def __init__(self, min_stall, max_stall, min_wait, max_wait):
        self.min_stall = min_stall
        self.max_stall = max_stall
        self.min_wait = min_wait
        self.max_wait = max_wait

    def __str__(self):
        return f"Stall(min_stall = {self.min_stall}, max_stall = {self.max_stall}, min_wait = {self.min_wait}, max_wait = {self.max_wait})"

class CacheSize:
    def __init__(self, sets, ways, line_size):
        self.sets = sets
        self.ways = ways
        self.line_size = line_size

    def __str__(self):
        return f"CacheSize(sets = {self.sets}, ways = {self.ways}, line_size = {self.line_size})"

class CpuSimulationConfig:
    def __init__(self, stall, icache, dcache):
        self.stall = stall
        self.icache = icache
        self.dcache = dcache

    @staticmethod
    def default():
        stall = StallCharacteristics(min_stall=1, max_stall=3, min_wait=1, max_wait=3)
        icache = CacheSize(sets=2, ways=4, line_size=8)
        dcache = CacheSize(sets=2, ways=4, line_size=8)

        return CpuSimulationConfig(stall=stall, icache=icache, dcache=dcache)

    def get_parameters(self):
        stall = [
            f"MIN_STALL_CYCLES={self.stall.min_stall}",
            f"MAX_STALL_CYCLES={self.stall.max_stall}",
            f"MIN_WAIT_CYCLES={self.stall.min_wait}",
            f"MAX_WAIT_CYCLES={self.stall.max_wait}",
        ]

        icache = [
            f"INSTRUCTION_CACHE_NSETS={self.icache.sets}",
            f"INSTRUCTION_CACHE_WAYS={self.icache.ways}",
            f"INSTRUCTION_CACHE_LINE_SIZE={self.icache.line_size}",
        ]

        dcache = [
            f"DATA_CACHE_NSETS={self.dcache.sets}",
            f"DATA_CACHE_WAYS={self.dcache.ways}",
            f"DATA_CACHE_LINE_SIZE={self.dcache.line_size}",
        ]

        return ",".join(stall + icache + dcache)

def warn(message):
    print(ANSI_YELLOW + str(message) + ANSI_RESET)

def error(message):
    print(ANSI_RED + str(message) + ANSI_RESET)

def success(message):
    print(ANSI_GREEN + str(message) + ANSI_RESET)

class InstructionTrace:
    def __init__(
            self,
            opcode,
            func,
            instruction_index,
            registers=None,
            pc=None,
            itype=None,
            rtype=None,
            jtype=None):

        self.opcode = opcode
        self.func = func
        self.instruction_index = instruction_index
        self.registers = registers
        self.pc = pc

        self.itype_info = itype
        self.rtype_info = rtype
        self.jtype_info = jtype

    def get_name(self):
        if self.opcode in inst.OPS_NAME:
            return inst.OPS_NAME[self.opcode]
        elif self.opcode == 0 and self.func in inst.FUNC_NAME:
            return inst.FUNC_NAME[self.func]
        else:
            return "invalid"

# Returns (opcode, func)
def instruction_reverse_lookup(instruction_name):
    for opcode, name in inst.OPS_NAME.items():
        if opcode != inst.RTYPE_OP and name == instruction_name:
            return opcode, 0

    for func, name in inst.FUNC_NAME.items():
        if name == instruction_name:
            return inst.RTYPE_OP, func

    return 0, 0

def write_trace_to_file(trace, path):
    with open(path, "w") as trace_file:
        for instruction in trace:
            opname = instruction.get_name()
            opcode = instruction.opcode

            trace_file.write(f"[{instruction.instruction_index}]: {opname:<5} ")

            if instruction.registers is not None:
                if opcode == inst.JTYPE_J or opcode == inst.JTYPE_JAL:
                    trace_file.write(f"jmp_imm = {instruction.jtype_info[0]:08X}")
                elif opcode == inst.RTYPE_OP:
                    rd, rs1, rs2 = instruction.rtype_info
                    rd_val = instruction.registers[rd]
                    rs1_val = instruction.registers[rs1]
                    rs2_val = instruction.registers[rs2]
                    trace_file.write(f"r{rd}[{rd_val:08X}], r{rs1}[{rs1_val:08X}], r{rs2}[{rs2_val:08X}]")
                else:
                    rd, rs1, imm = instruction.itype_info
                    rd_val = instruction.registers[rd]
                    rs1_val = instruction.registers[rs1]
                    trace_file.write(f"r{rd}[{rd_val:08X}], r{rs1}[{rs1_val:08X}], {imm:08X}")

            if instruction.pc is not None:
                trace_file.write(f" (pc = {instruction.pc:08X})")

            trace_file.write("\n")

def load_symbols(path_symbols):
    symbols = {}
    with open(path_symbols, "r") as symfile:
        for line in symfile:
            key, val = re.split(r"\s+", line.strip())
            symbols[key] = int(val, 16)

    return symbols

def load_memory(dump_path):
    memory = {}
    with open(dump_path, "r") as dump:
        for line in dump:
            addr_hex, value_hex = line.strip().split(": ") 

            addr = int(addr_hex, 16)
            try:
                value = int(value_hex, 16)
            except:
                value = -1

            memory[addr] = value

    return memory
