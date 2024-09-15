from dlx_emu_cpu import DLXCpu
from dlx_emu_bus import MemoryBus
from dlx_instructions import ITYPE_NOP

from common import error

def hexfile_to_memory(filename):
    memory = []
    with open(filename, "r") as infile:
        for line in infile:
            memory.append(int(line, 16))

    return memory

def emulate(progfile, starting_pc, max_cycles, dumpfile, verbose=False):
    memory = hexfile_to_memory(progfile)

    membus = MemoryBus(memory)
    cpu = DLXCpu(membus, starting_pc)
    was_stopped = False

    emulator_trace = []

    for _ in range(max_cycles):
        trace = cpu.run_one_instruction(verbose)
        if trace.opcode != ITYPE_NOP:
            emulator_trace.append(trace)

        if membus.is_finished():
            was_stopped = True
            break


    if not was_stopped:
        error(f"ERROR: The simulation went over {max_cycles} cycles.")
        return False, cpu.instructions_run, []

    if dumpfile != "":
        with open(dumpfile, "w") as dump:
            for i, val in enumerate(membus.memory):
                print(f"{i*4:08X}: {val:08X}", file=dump)

    return True, cpu.instructions_run, emulator_trace

