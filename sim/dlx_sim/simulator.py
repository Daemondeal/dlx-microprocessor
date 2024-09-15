# Utility to manage vsim simulations

from pathlib import Path

from common import (
    error,
    write_trace_to_file,
    InstructionTrace,
    instruction_reverse_lookup,
    CpuSimulationConfig,
)

import subprocess
import shutil
import re


def add_memory_waves(path_outdir, symbols):
    assert "data_start" in symbols

    waves_setup = Path("./waves_setup/dlx_waves.do")
    modified_wave_setup_path = path_outdir / "waves.do"

    shutil.copy(waves_setup, modified_wave_setup_path)

    with open(modified_wave_setup_path, "a") as outfile:
        outfile.write("\n")

        data_start = symbols["data_start"]
        for name, address in symbols.items():
            if name != "data_start" and address >= data_start:
                outfile.write(
                    f"add wave -hex -group Variables -label {{{name}({address:08X})}} /tb_DLX/DUT_Memory/memory({address//4})\n"
                )

        for i in range(200):
            addr = data_start // 4 + i
            outfile.write(
                f"add wave -hex -group Memory -label {{mem[{addr*4:08X}]}} /tb_DLX/DUT_Memory/memory({addr})\n"
            )

    return modified_wave_setup_path.as_posix()


def simulate_cpu_with_gui(mem_init, dumpfile, max_cycles, start_addr, outdir, symbols):
    if "data_start" in symbols:
        wave_setup_file = add_memory_waves(outdir, symbols)
    else:
        wave_setup_file = "./waves_setup/dlx_waves.do"

    # TODO: IMPLEMENT
    _ = start_addr

    start_sim = f"start_sim -top tb_DLX -generics PROGRAM={mem_init},DUMP={dumpfile},MAX_CYCLES={max_cycles}"
    start_sim += f" -wave_setup {wave_setup_file}"

    args = [
        "vsim",
        "-quiet",
        "-do",
        "simulate.do",
        "-do",
        start_sim,
    ]

    print(" ".join(args))
    subprocess.run(args)


def simulate_cpu(
    mem_init,
    dumpfile,
    max_cycles,
    start_addr,
    outdir,
    quiet=False,
    show_vsim_output=False,
    cpu_config=None,
):

    if cpu_config is None:
        cpu_config = CpuSimulationConfig.default()

    start_sim = f"start_sim -top tb_DLX -generics PROGRAM={mem_init},DUMP={dumpfile},MAX_CYCLES={max_cycles},{cpu_config.get_parameters()}"

    # TODO: IMPLEMENT
    _ = start_addr

    args = [
        "vsim",
        "-c",
        "-quiet",
        "-do",
        "simulate.do",
        "-do",
        start_sim,
        "-do",
        "quit",
    ]

    if not quiet:
        print(" ".join(args))

    print_next = False

    cycle_taken = 0
    instruction_ran = 0

    execution_trace = []

    simulation_success = False
    popen = subprocess.Popen(args, stdout=subprocess.PIPE, universal_newlines=True)
    for line in iter(popen.stdout.readline, ""):
        inst_match = re.search(r"Instructions ran:\s*(\d+)", line)
        cyc_match = re.search(r"Cycles taken:\s*(\d+)", line)

        if inst_match:
            instruction_ran = int(inst_match.group(1))

        if cyc_match:
            cycle_taken = int(cyc_match.group(1))

        if show_vsim_output:
            print(line.strip())

        inst_trace_match = re.search(r"\[(\d+)\] ([a-zA-Z_]+)_op", line)
        if inst_trace_match:
            instruction_number = int(inst_trace_match.group(1))
            instruction = inst_trace_match.group(2)

            opcode, func = instruction_reverse_lookup(instruction)
            execution_trace.append(
                InstructionTrace(
                    opcode=opcode, func=func, instruction_index=instruction_number
                )
            )

            assert instruction_number == len(execution_trace) - 1
            continue

        if not show_vsim_output and not quiet:
            if line.startswith("# **"):
                print(line.strip())
                print_next = True
            elif print_next:
                print(line.strip())
                print_next = False

        # A bit hacky, but it will work
        if "Simulation Finished!" in line:
            simulation_success = True

    if not simulation_success or cycle_taken == 0 or instruction_ran == 0:
        if not quiet:
            error(f"Simulation Failed")
        return False, 0, [], 0

    if cycle_taken != 0 and instruction_ran != 0:
        cpi = float(cycle_taken) / float(instruction_ran)
        if not quiet:
            print(f"\nSimulation Finished!\nCycles per Instruction: {cpi:.2f}")

    write_trace_to_file(execution_trace, outdir / "simulator.trace")

    return True, instruction_ran, execution_trace, cycle_taken
