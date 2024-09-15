class MemoryBus:
    def __init__(self, memory):
        self.memory = [0] * 2**12

        for i, word in enumerate(memory):
            self.memory[i] = word

        self.finished = False

    def is_finished(self):
        return self.finished

    def read(self, addr):
        if addr/4 > len(self.memory) or addr//4 < 0:
            print(f"Invalid memory address {addr:08X}")
            return 0
        return self.memory[addr//4]

    def read_byte(self, addr):
        if addr//4 > len(self.memory) or addr//4 < 0:
            print(f"Invalid memory address {addr:08X}")
            return 0

        return (self.memory[addr//4] >> ((addr % 4) * 8)) & 0xFF

    def read_halfword(self, addr):
        if addr//4 > len(self.memory) or addr//4 < 0:
            print(f"Invalid memory address {addr:08X}")
            return 0
        memval = self.memory[addr//4]
        shift = (addr % 4) * 8
        read_value = (memval >> shift) & 0xFFFF

        return read_value

    def write(self, addr, value):
        if (addr & 0xFFFF0000) == 0xFFFF0000:
            self.finished = True
            return

        if addr//4 > len(self.memory) or addr//4 < 0:
            print(f"Invalid memory address {addr:08X}")
        self.memory[addr//4] = value
