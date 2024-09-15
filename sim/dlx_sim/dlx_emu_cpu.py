from common import warn, InstructionTrace
from dlx_instructions import *

def sign_extend(value, bits):
    sign_bit = 1 << (bits-1)
    return (value & (sign_bit - 1)) - (value & sign_bit)

def to_signed(n, byte_count=4): 
    return int.from_bytes(n.to_bytes(byte_count, 'little', signed=False), 'little', signed=True)


class DLXCpu:
    def __init__(self, bus, start_pc):
        self.bus = bus

        self.registers = [0] * 32
        self.pc = start_pc

        self.cycle = 0
        self.instructions_run = 0

    def run_one_instruction(self, verbose):
        instruction = self.bus.read(self.pc)

        prev_pc = self.pc
        self.pc += 4

        opcode = (instruction & 0xFC000000) >> (32-6)


        itype_rs1 = (instruction & 0x03E00000) >> (32-6-5)
        itype_rd  = (instruction & 0x001F0000) >> (32-6-5-5)
        itype_imm = (instruction & 0x0000FFFF)

        rtype_rs1  = (instruction & 0x03E00000) >> (32-6-5)
        rtype_rs2  = (instruction & 0x001F0000) >> (32-6-5-5)
        rtype_rd   = (instruction & 0x0000FC00) >> (32-6-5-5-5)
        rtype_func = (instruction & 0x000003FF)

        jtype_jmp = (instruction & 0x03FFFFFF)


        regs = self.registers
        MASK = 0xFFFF_FFFF # Used to do word-length ops

        unsigned_imm = (itype_imm) & MASK
        signed_imm = sign_extend(itype_imm, 16)

        jmp_imm = sign_extend(jtype_jmp, 26) & MASK


        LINK_REGISTER = 31

        if opcode != ITYPE_NOP:
            self.instructions_run += 1

        if opcode == ITYPE_ADDI:
            regs[itype_rd] = (regs[itype_rs1] + signed_imm) & MASK
        elif opcode == ITYPE_ADDUI:
            regs[itype_rd] = (regs[itype_rs1] + unsigned_imm) & MASK
        elif opcode == ITYPE_SUBI:
            regs[itype_rd] = (regs[itype_rs1] - signed_imm) & MASK
        elif opcode == ITYPE_SUBUI:
            regs[itype_rd] = (regs[itype_rs1] - unsigned_imm) & MASK
        elif opcode == ITYPE_BEQZ:
            if regs[itype_rs1] == 0:
                self.pc += signed_imm
        elif opcode == ITYPE_BNEZ:
            if regs[itype_rs1] != 0:
                self.pc += signed_imm
        elif opcode == ITYPE_JALR:
            regs[LINK_REGISTER] = self.pc
            self.pc = regs[itype_rs1]
        elif opcode == ITYPE_JR:
            self.pc = regs[itype_rs1]
        elif opcode == ITYPE_SEQI:
            regs[itype_rd] = int(regs[itype_rs1] == unsigned_imm)
        elif opcode == ITYPE_SGEI:
            regs[itype_rd] = int(to_signed(regs[itype_rs1]) >= signed_imm)
        elif opcode == ITYPE_SGEUI:
            regs[itype_rd] = int(regs[itype_rs1] >= unsigned_imm)
        elif opcode == ITYPE_SGTI:
            regs[itype_rd] = int(to_signed(regs[itype_rs1]) > signed_imm)
        elif opcode == ITYPE_SGTUI:
            regs[itype_rd] = int(to_signed(regs[itype_rs1]) > unsigned_imm)
        elif opcode == ITYPE_SLEI:
            regs[itype_rd] = int(to_signed(regs[itype_rs1]) <= signed_imm)
        elif opcode == ITYPE_SLEUI:
            regs[itype_rd] = int(regs[itype_rs1] <= unsigned_imm)
        elif opcode == ITYPE_SLTI:
            regs[itype_rd] = int(to_signed(regs[itype_rs1]) < signed_imm)
        elif opcode == ITYPE_SLTUI:
            regs[itype_rd] = int(regs[itype_rs1] < unsigned_imm)
        elif opcode == ITYPE_SNEI:
            regs[itype_rd] = int(regs[itype_rs1] != unsigned_imm)
        elif opcode == ITYPE_ANDI:
            regs[itype_rd] = regs[itype_rs1] & unsigned_imm
        elif opcode == ITYPE_ORI:
            regs[itype_rd] = regs[itype_rs1] | unsigned_imm
        elif opcode == ITYPE_XORI:
            regs[itype_rd] = regs[itype_rs1] ^ unsigned_imm
        elif opcode == ITYPE_LB:
            regs[itype_rd] = sign_extend(self.bus.read_byte(regs[itype_rs1] + signed_imm), 8) & MASK
        elif opcode == ITYPE_LBU:
            regs[itype_rd] = self.bus.read_byte(regs[itype_rs1] + signed_imm) & MASK
        elif opcode == ITYPE_LH:
            regs[itype_rd] = sign_extend(self.bus.read_halfword(regs[itype_rs1] + signed_imm), 16) & MASK
        elif opcode == ITYPE_LHU:
            regs[itype_rd] = self.bus.read_halfword(regs[itype_rs1] + signed_imm) & MASK
        elif opcode == ITYPE_LW:
            regs[itype_rd] = self.bus.read(regs[itype_rs1] + signed_imm) & MASK
        elif opcode == ITYPE_SB:
            addr = regs[itype_rs1] + signed_imm
            byte_index = addr % 4
            prev_value = self.bus.read(addr)
            mask = 0xFF << (byte_index * 8)
            new_value = (prev_value & ~mask) | ((regs[itype_rd] & 0xFF) << (byte_index * 8))
            self.bus.write(addr, new_value)
        elif opcode == ITYPE_SH:
            addr = regs[itype_rs1] + signed_imm
            halfword_index = addr % 2
            prev_value = self.bus.read(addr)
            mask = 0xFFFF << (halfword_index * 16)
            new_value = (prev_value & ~mask) | ((regs[itype_rd] & 0xFFFF) << (halfword_index * 16))
            self.bus.write(addr, new_value)
        elif opcode == ITYPE_SW:
            self.bus.write(regs[itype_rs1] + signed_imm, regs[itype_rd])
        elif opcode == ITYPE_LHI:
            regs[itype_rd] = (itype_imm << 16) & MASK
        elif opcode == ITYPE_NOP:
            pass
        elif opcode == ITYPE_SLLI:
            regs[itype_rd] = (regs[itype_rs1] << (itype_imm & 0x1F)) & MASK
        elif opcode == ITYPE_SRAI:
            regs[itype_rd] = (to_signed(regs[itype_rs1]) >> (signed_imm & 0x1F)) & MASK
        elif opcode == ITYPE_SRLI:
            regs[itype_rd] = (regs[itype_rs1] >> (unsigned_imm & 0x1F)) & MASK
        elif opcode == JTYPE_J:
            self.pc = (self.pc + jmp_imm) & MASK
        elif opcode == JTYPE_JAL:
            regs[LINK_REGISTER] = self.pc
            self.pc = (self.pc + jmp_imm) & MASK
        elif opcode == 0: # Rtype
            if rtype_func == FUNC_ADD:
                regs[rtype_rd] = (to_signed(regs[rtype_rs1]) + to_signed(regs[rtype_rs2])) & MASK
            elif rtype_func == FUNC_ADDU:
                regs[rtype_rd] = (regs[rtype_rs1] + regs[rtype_rs2]) & MASK
            elif rtype_func == FUNC_SUB:
                regs[rtype_rd] = (to_signed(regs[rtype_rs1]) - to_signed(regs[rtype_rs2])) & MASK
            elif rtype_func == FUNC_SUBU:
                regs[rtype_rd] = (regs[rtype_rs1] - regs[rtype_rs2]) & MASK
            elif rtype_func == FUNC_SEQ:
                regs[rtype_rd] = int(regs[rtype_rs1] == regs[rtype_rs2])
            elif rtype_func == FUNC_SGE:
                regs[rtype_rd] = int(to_signed(regs[rtype_rs1]) >= to_signed(regs[rtype_rs2]))
            elif rtype_func == FUNC_SGEU:
                regs[rtype_rd] = int(regs[rtype_rs1] >= regs[rtype_rs2])
            elif rtype_func == FUNC_SGT:
                regs[rtype_rd] = int(to_signed(regs[rtype_rs1]) > to_signed(regs[rtype_rs2]))
            elif rtype_func == FUNC_SGTU:
                regs[rtype_rd] = int(regs[rtype_rs1] > regs[rtype_rs2])
            elif rtype_func == FUNC_SLE:
                regs[rtype_rd] = int(to_signed(regs[rtype_rs1]) <= to_signed(regs[rtype_rs2]))
            elif rtype_func == FUNC_SLEU:
                regs[rtype_rd] = int(regs[rtype_rs1] <= regs[rtype_rs2])
            elif rtype_func == FUNC_SLT:
                regs[rtype_rd] = int(to_signed(regs[rtype_rs1]) < to_signed(regs[rtype_rs2]))
            elif rtype_func == FUNC_SLTU:
                regs[rtype_rd] = int(regs[rtype_rs1] < regs[rtype_rs2])
            elif rtype_func == FUNC_SNE:
                regs[rtype_rd] = int(to_signed(regs[rtype_rs1]) != to_signed(regs[rtype_rs2]))
            elif rtype_func == FUNC_AND:
                regs[rtype_rd] = regs[rtype_rs1] & regs[rtype_rs2]
            elif rtype_func == FUNC_OR:
                regs[rtype_rd] = regs[rtype_rs1] | regs[rtype_rs2]
            elif rtype_func == FUNC_XOR:
                regs[rtype_rd] = regs[rtype_rs1] ^ regs[rtype_rs2]
            elif rtype_func == FUNC_SLL:
                regs[rtype_rd] = (regs[rtype_rs1] << (regs[rtype_rs2] & 0x1F )) & MASK
            elif rtype_func == FUNC_SRA:
                regs[rtype_rd] = (to_signed(regs[rtype_rs1]) >> to_signed(regs[rtype_rs2] & 0x1F)) & MASK
            elif rtype_func == FUNC_SRL:
                regs[rtype_rd] = (regs[rtype_rs1] >> (regs[rtype_rs2] & 0x1F)) & MASK
            elif rtype_func == FUNC_IMUL:
                regs[rtype_rd] = (to_signed(regs[rtype_rs1]) * to_signed(regs[rtype_rs2])) & MASK
            elif rtype_func == FUNC_IDIV:
                # Division by zero saturates
                if regs[rtype_rs2] == 0:
                    regs[rtype_rd] = 0xFFFF_FFFF
                    warn("Division by zero detected, result is undefined")
                else:
                    regs[rtype_rd] = (to_signed(regs[rtype_rs1]) // to_signed(regs[rtype_rs2])) & MASK
            elif rtype_func == FUNC_IMOD:
                if regs[rtype_rs2] == 0:
                    warn("Modulo by zero detected, result is undefined")
                    regs[rtype_rd] = regs[rtype_rs1]
                else:
                    regs[rtype_rd] = abs(to_signed(regs[rtype_rs1]) % to_signed(regs[rtype_rs2])) & MASK
            else:
                print(f"[{self.pc:08X}] Unknown function {rtype_func:03X}")
                return
        else:
            print(f"[{self.pc:08X}] Unknown opcode {opcode:02X}")
            return

        self.cycle += 1

        if verbose:
            print(f"(op = {opcode:02X}, func = {rtype_func:03X}) ", end="")
            if opcode in OPS_NAME:
                name = OPS_NAME[opcode]
                print(
                    f"[{prev_pc:08X}] {name+',':<5}" + 
                    f" rs1 = r{itype_rs1:02}[{regs[itype_rs1]:08X}]" + 
                    f", rd  = r{itype_rd:02}[{regs[itype_rd]:08X}]" +
                    f", imm = {itype_imm:04X}"
                )

            elif opcode == 0 and rtype_func in FUNC_NAME:
                name = FUNC_NAME[rtype_func]
                print(
                    f"[{prev_pc:08X}] {name+',':<5}" + 
                    f" rs1 = r{rtype_rs1:02}[{regs[rtype_rs1]:08X}]" +
                    f", rs2 = r{rtype_rs2:02}[{regs[rtype_rs2]:08X}]" +
                    f", rd = r{rtype_rd:02}[{regs[rtype_rd]:08X}]"
                )
            elif opcode == JTYPE_J or opcode == JTYPE_JAL:
                name = OPS_NAME[opcode]
                print(f"[{prev_pc:08X}] {name+',':<5}, jmp = {jmp_imm}") 
            else:
                print(f"[{prev_pc:08X}] invalid instruction")

            print(f"  cur_inst = {self.instructions_run}")
            print(f"  lr = {self.registers[31]:08X}")
            print(f"  sp = {self.registers[30]:08X}")
            for i in range(10):
                print(f"  r{i} = {self.registers[i]:08X}")
            print(f"  r29 = {self.registers[29]:08X}")

        itype = (itype_rd, itype_rs1, itype_imm)
        rtype = (rtype_rd, rtype_rs1, rtype_rs2)
        jtype = (jtype_jmp, )
        func = rtype_func if opcode == RTYPE_OP else 0
        return InstructionTrace(
                opcode=opcode,
                func=func,
                instruction_index=self.instructions_run-1,
                registers=self.registers,
                pc=prev_pc,
                itype=itype,
                rtype=rtype,
                jtype=jtype
        )


