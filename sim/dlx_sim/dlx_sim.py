#!/bin/python3

import subprocess
import argparse
import shutil
import re
import time

import dlx_emulator as emulator
import simulator
import checker

from common import error, success, write_trace_to_file, load_memory, load_symbols, CpuSimulationConfig
from pathlib import Path

ASSEMBLER_PATH = "./assembler/dlxasm.pl"

def run_gui_simulation(program_source, outdir, start_address, max_cycles):
    path_asm_source = Path(program_source)

    progname = path_asm_source.stem
    path_outdir = Path(outdir) / f"{progname}_gui"

    path_dumpfile_mem_init = path_outdir / f"{progname}.mem"
    path_dumpfile_cpu = path_outdir / f"{progname}_sim_dump.mem"
    path_symbols = path_outdir / f"{progname}.sym"

    if not path_asm_source.exists():
        error(f"ERROR: {path_asm_source} does not exist")
        return False

    # Remove outdir if it exists, makes sure that no previous result is used
    if path_outdir.exists():
        shutil.rmtree(path_outdir)

    path_outdir.mkdir(parents=True, exist_ok=True)

    assemble(path_asm_source, path_outdir)

    simulator.simulate_cpu_with_gui(
            mem_init=path_dumpfile_mem_init,
            dumpfile=path_dumpfile_cpu,
            max_cycles=max_cycles,
            start_addr=start_address,
            outdir=path_outdir,
            symbols=load_symbols(path_symbols))


def load_symbols(path_symbols):
    symbols = {}
    with open(path_symbols, "r") as symfile:
        for line in symfile:
            key, val = re.split(r"\s+", line.strip())
            symbols[key] = int(val, 16)

    return symbols

def print_variables_from_dump(path_symbols, path_dump):
    symbols = load_symbols(path_symbols)
    if "data_start" not in symbols:
        print("No variables to show")
        return

    mem = load_memory(path_dump)

    data_start = symbols["data_start"]
    for name, address in symbols.items():
        if name != "data_start" and address >= data_start:
            print(f"{name} = 0x{mem[address]:08X} ({mem[address]})")


def run_test(program_source, outdir, max_cycles=30_000):
    return run_program(
        program_source,
        outdir,
        max_cycles=max_cycles,
        should_emulate=True,
        should_simulate=True,
        quiet=True
    )

def run_test_suite(tests_file_path, outdir, max_cycles=30_000):
    path_tests_file = Path(tests_file_path)

    if not path_tests_file.exists():
        error(f"File {path_tests_file} not found")
        return False

    failing_tests = []
    successful_tests = []

    print("### STARTING TESTS ###")
    time_start_tests = time.perf_counter()

    with open(tests_file_path, "r") as tests_file:
        tests_array = tests_file.readlines()
        total_tests = len(tests_array)
        for i, line in enumerate(tests_array):
            line = line.strip().split("#")[0]

            if line == "":
                continue

            path_program = Path(line)

            print(f"[{i+1:03}/{total_tests:03}] Running {path_program}")

            start = time.perf_counter()

            test_success, instructions_ran, cycles_taken = run_test(path_program, outdir, max_cycles=max_cycles)

            if instructions_ran > 0:
                cpi = float(cycles_taken) / float(instructions_ran)
            else:
                cpi = 0

            if not test_success:
                failing_tests.append((path_program.name, cpi))
                error("Test Failed.")
            else:
                successful_tests.append((path_program.name, cpi))
                success("Test Succeded!")

            print(f"Instructions ran: {instructions_ran}, Cycles Taken: {cycles_taken}")
            if instructions_ran > 0:
                print(f"Clocks per instruction: {cpi:.2f}")


            end = time.perf_counter()

            print(f"Done! Took {(end - start):.2f} s.")
            print()

    time_end_tests = time.perf_counter()
    elapsed = time_end_tests - time_start_tests

    successful = len(successful_tests)
    failing = len(failing_tests)
    total = successful + failing
    percentage = float(successful)/float(total) * 100.0

    print()
    print("### RESULTS ###")
    print(f"Tests Passed: {successful}/{total} ({percentage:.2f} %).")
    print(f"Elapsed time: {elapsed:.2f} s.")
    if failing == 0:
        success("All tests passed!")
    else:
        error("Some tests failed")

    if successful > 0:
        print("\nSuccessful tests:")
        for test, cpi in successful_tests:
            success(f" {test} (Clocks per instruction = {cpi:.2f})")
    if failing > 0:
        print("\nFailing tests:")
        for test, cpi in failing_tests:
            error(f" {test} (CLocks per instruction = {cpi:.2f})")



# Returns (success: bool, reason_for_failure: string | None)
def run_program(
        program_source,
        outdir="./build",
        start_address=0,
        max_cycles=30_000,
        should_emulate=False,
        should_simulate=False,
        should_check=False,
        echo_variables=False,
        quiet=False,
        verbose=False,
        cpu_config=None
    ):

    if cpu_config is None:
        cpu_config = CpuSimulationConfig.default()

    path_asm_source = Path(program_source)

    progname = path_asm_source.stem
    path_outdir = Path(outdir) / progname

    path_dumpfile_mem_init = path_outdir / f"{progname}.mem"
    path_dumpfile_cpu = path_outdir / f"{progname}_sim_dump.mem"
    path_dumpfile_emu = path_outdir / f"{progname}_emu_dump.mem"
    path_symbols = path_outdir / f"{progname}.sym"
    path_sim_trace = path_outdir / f"simulator.trace"
    path_emu_trace = path_outdir / f"emulator.trace"

    if not path_asm_source.exists():
        error(f"ERROR: {path_asm_source} does not exist")
        return False, 0, 0

    # Remove outdir if it exists, makes sure that no previous result is used
    if path_outdir.exists():
        shutil.rmtree(path_outdir)

    path_outdir.mkdir(parents=True, exist_ok=True)

    assemble(path_asm_source, path_outdir, quiet=quiet)

    emulator_success = True
    emu_instructions_ran = 0
    emulator_trace = []

    if should_emulate:
        if not quiet:
            print("### EMULATING ###\n")
        else:
            print("Emulating...")

        emulator_success, emu_instructions_ran, emulator_trace = emulator.emulate(
            progfile=path_dumpfile_mem_init,
            starting_pc=start_address,
            max_cycles=max_cycles,
            dumpfile=path_dumpfile_emu,
            verbose=verbose)

        if not emulator_success:
            error("Emulator failure")
            return False, 0, 0
        else:
            write_trace_to_file(emulator_trace, path_emu_trace)

        if not should_simulate and echo_variables:
            print("### ECHOING EMULATOR VARIABLES ###\n")
            print_variables_from_dump(path_symbols, path_dumpfile_emu)

    simulator_success = True
    sim_instructions_ran = 0
    simulator_trace = []
    cycles_taken = 0

    if should_simulate:
        if not quiet:
            print("### SIMULATING ###\n")
        else:
            print("Simulating...")
        simulator_success, sim_instructions_ran, simulator_trace, cycles_taken = simulator.simulate_cpu(
            mem_init=path_dumpfile_mem_init,
            dumpfile=path_dumpfile_cpu,
            max_cycles=max_cycles,
            start_addr=start_address,
            outdir=path_outdir,
            quiet=quiet,
            show_vsim_output=verbose,
            cpu_config=cpu_config
        )

        if not simulator_success:
            error("Simulator failure")
            return False, 0, 0
        else:
            write_trace_to_file(simulator_trace, path_sim_trace)

        if echo_variables:
            print("### ECHOING SIMULATOR VARIABLES ###\n")
            print_variables_from_dump(path_symbols, path_dumpfile_cpu)

    if should_emulate and should_simulate:
        check_success = True

        if emu_instructions_ran != sim_instructions_ran:
            error("Number of instructions ran does not match between cpu and emulator.")
            error(f"cpu = {emu_instructions_ran}, emu = {sim_instructions_ran}")
            check_success = False
        elif not quiet:
            success("Number of instructions matches between cpu and emulator!")

        traces_success = compare_traces(emulator_trace, simulator_trace)
        if traces_success and not quiet:
            success("Traces match equal between cpu and emulator!")

        dumps_success = compare_dumps(path_dumpfile_emu, path_dumpfile_cpu)
        if dumps_success and not quiet:
            success("Memories are equal between cpu and emulator!")

        if not check_success or not traces_success or not dumps_success:
            return False, 0, 0


    if should_check:
        if should_simulate:
            print("### CHECKING CPU ###\n")
            checker.check(path_asm_source, path_dumpfile_cpu, path_symbols)
        elif should_emulate:
            print("### CHECKING EMULATOR ###\n")
            checker.check(path_asm_source, path_dumpfile_emu, path_symbols)

    return True, sim_instructions_ran, cycles_taken

def compare_traces(emu_trace, sim_trace):
    check_success = True

    different_traces = []

    # NOTE: This should not count the final lhi and sw
    for emu_instr in emu_trace[:-2]:
        if len(sim_trace) <= emu_instr.instruction_index:
            error(f"Simulator stops at instruction {len(sim_trace)}.")
            check_success = False
            break

        sim_instr = sim_trace[emu_instr.instruction_index]
        if sim_instr.opcode != emu_instr.opcode or sim_instr.func != emu_instr.func:
            different_traces.append((emu_instr, sim_instr))

    if len(different_traces) > 0:
        error("Traces differ between emulator and simulator. First ten differing traces:")
        for emu_instr, sim_instr in different_traces[:10]:
            error(f" [{emu_instr.instruction_index}] emu: {emu_instr.get_name()} sim: {sim_instr.get_name()}")

        check_success = False

    return check_success


def load_dump(path):
    dump = {}
    with open(path, "r") as dumpfile:
        for line in dumpfile:
            match = re.search(r"([0-9ABCDEF]+): ([0-9ABCDEFZ]+)", line.upper().strip())
            if match:
                dump[int(match.group(1), 16)] = int(match.group(2).replace("Z", "0"), 16)
    return dump



def compare_dumps(emu_dump_path, sim_dump_path):
    emu_dump = load_dump(emu_dump_path)
    sim_dump = load_dump(sim_dump_path)

    errors = []
    for addr, val in emu_dump.items():
        if addr in sim_dump and sim_dump[addr] != val:
            errors.append((addr, val, sim_dump[addr]))

    for addr, emu_val, sim_val in errors:
        error(f" memory mismatch at address \"{addr:08X}\": \n")
        error(f"  emu = {emu_val:08X}")
        error(f"  sim = {sim_val:08X}")

    return len(errors) == 0


def assemble(program_path, outdir, quiet=False):
    if not quiet:
        print("### ASSEMBLING ###\n")
    else:
        print("Assembling...")

    progname = program_path.stem

    assembler_args = [
        "perl", ASSEMBLER_PATH,
        "-o", outdir / Path(f"{progname}.bin"),
        "-list", outdir / f"{progname}.list",
        "-sym", outdir / f"{progname}.sym",
        program_path

    ]

    result = subprocess.run(assembler_args)

    if result.returncode != 0:
        error("ERROR: Assembler failed, exiting")
        exit(-1)

    with open(outdir / f"{progname}.bin", "rb") as outfile:
        program_output = list(outfile.read())

    with open(outdir / f"{progname}.mem", "w") as dumpfile:
        for i in range(len(program_output)//4):
            word = 0
            for j in range(4):
                word += program_output[i * 4 + j] << ((3-j) * 8)
            dumpfile.write(f"{word:08X}\n")

def parse_args():
    parser = argparse.ArgumentParser(
        prog="dlx_sim", description="An utility for managing running programs for the DLX processor"
    )

    subparsers = parser.add_subparsers(help="operation to run")

    gui_parser = subparsers.add_parser("gui")
    single_parser = subparsers.add_parser("single")
    all_parser = subparsers.add_parser("all")

    gui_parser.add_argument("program_source")

    gui_parser.add_argument("-o", "--outdir", type=str, default="build",
                        help="the folder where to save the output")

    gui_parser.add_argument("-a", "--start-address", type=int, default=0,
                        help="the address where to start loading instructions")

    gui_parser.add_argument("-m", "--max-cycles", type=int, default=30_000,
                        help="the maximum cycles to run before stopping")

    gui_parser.set_defaults(func=gui_simulation)

    single_parser.add_argument("program_source")

    single_parser.add_argument("-e", "--emulator", action="store_true",
                        help="run the emulator")

    single_parser.add_argument("-v", "--verbose", action="store_true",
                        help="run the emulator in verbose mode")

    single_parser.add_argument("-s", "--cpu-sim", action="store_true",
                        help="run the modelsim cpu simulation")

    single_parser.add_argument("-p", "--print-variables", action="store_true",
                        help="prints all variables after cpu simulation")

    single_parser.add_argument("-c", "--check", action="store_true",
                        help="run the checker")

    single_parser.add_argument("-o", "--outdir", type=str, default="build",
                        help="the folder where to save the output")

    single_parser.add_argument("-a", "--start-address", type=int, default=0,
                        help="the address where to start loading instructions")

    single_parser.add_argument("-m", "--max-cycles", type=int, default=30_000,
                        help="the maximum cycles to run before stopping")

    single_parser.set_defaults(func=single_simulation)

    all_parser.add_argument("-t", "--tests-file-path", type=str, default="tests.list",
                        help="the file containing the path of all tests")

    all_parser.add_argument("-o", "--outdir", type=str, default="build",
                        help="the folder where to save the output")

    all_parser.add_argument("-m", "--max-cycles", type=int, default=200_000,
                        help="the maximum cycles to run before stopping")

    all_parser.set_defaults(func=all_simulation)

    return parser.parse_args()

def gui_simulation(args):
    run_gui_simulation(
        program_source=args.program_source,
        outdir=args.outdir,
        start_address=args.start_address,
        max_cycles=args.max_cycles,
    )

def single_simulation(args):
    run_program(
        program_source=args.program_source,
        outdir=args.outdir,
        start_address=args.start_address,
        max_cycles=args.max_cycles,
        should_emulate=args.emulator,
        should_simulate=args.cpu_sim,
        should_check=args.check,
        echo_variables=args.print_variables,
        verbose=args.verbose
    )

def all_simulation(args):
    run_test_suite(
        tests_file_path=args.tests_file_path,
        outdir=args.outdir,
        max_cycles=args.max_cycles
    )

def main():
    args = parse_args()

    args.func(args)


if __name__ == "__main__":
    main()
