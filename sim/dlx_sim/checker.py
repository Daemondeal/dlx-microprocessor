#!/bin/python

import re

from common import error, success, load_symbols, load_memory

def check_memory(args, line, memory, symbols):
    val_hex  = False
    try:
        addr_str, val_str = args.strip().split(" ")

        if val_str.startswith("0x"):
            val = int(val_str[2:], 16)
            val_hex = True
        else:
            val = int(val_str)

        val &= 0xFFFFFFFF

        if addr_str in symbols:
            addr = symbols[addr_str]
        elif addr_str.startswith("0x"):
            addr = int(addr_str[2:], 16)
        else:
            addr = int(addr_str)

        if addr % 4 != 0:
            error(f" {line}: address \"{addr_str}\" not 4-bytes aligned")
            return False

        if addr not in memory:
            error(f" {line}: address \"{addr_str}\" is outside memory")
            return False

        if val != memory[addr]:
            if memory[addr] == -1:
                error(f" {line}: invalid value at address \"{addr_str}\". expected \"{val}\" but got \"ZZZZZZZZ\"")
            else:
                if val_hex:
                    error(f" {line}: invalid value at address \"{addr_str}\". expected \"0x{val:08X}\" but got \"0x{memory[addr]:08X}\"")
                else:
                    error(f" {line}: invalid value at address \"{addr_str}\". expected \"{val}\" but got \"{memory[addr]}\"")
            return False

        success(f" {line}: test passed!")
        return True


    except:
        error(f" invalid args for expect \"{args}\" at line {line}")
        return False


def check_output(filename, memory, symbols):
    testrom_line = 1
    failed_tests = 0
    total_tests = 0

    with open(filename, "r") as asm_file:
        for line in asm_file:
            match = re.search(r"; ([a-zA-Z]+):\s([a-zA-Z_\-0-9 ]+)", line.strip())
            if match:
                command = match.group(1)
                args = match.group(2)

                if command == "category":
                    category = args
                    print()
                    print(f" -- {category} -- ")
                elif command == "test":
                    testrom_context = args
                    print(f"[{testrom_context}]:")
                elif command == "expect":
                    if not check_memory(args, testrom_line, memory, symbols):
                        failed_tests += 1
                    total_tests += 1
                else:
                    error(f" {testrom_line}: invalid command \"{command}\"")

            testrom_line += 1

    if total_tests == 0:
        print("No tests were found")
        return

    print()
    if failed_tests == 0:
        success("ALL TESTS PASSED")
    else:
        error("TESTS FAILED")

    print(f"Tests Passed: {total_tests-failed_tests}/{total_tests} ({(total_tests-failed_tests)/total_tests * 100:.2f} %)")



def check(testrom_path, dump_path, path_symbols):
    memory = load_memory(dump_path)
    symbols = load_symbols(path_symbols)
    check_output(testrom_path, memory, symbols)

