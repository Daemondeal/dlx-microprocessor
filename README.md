# DLX microprocessor

An implementation of the DLX microprocessor architecture described by John L. Hennessy and David A. Patterson in "Computer Architecture: A Quantitative Approach" (2nd edition). This implementation supports one-level caching, branch prediction, hazard detection, and hardware multiplication and division.

Written in collaboration with [@Giulisol](https://github.com/Giulsol) and [@Cesacesa](https://github.com/Cesacesa).

## Table of contents

1. [How to simulate](#how-to-simulate)
1. [Folder structure](#folder-structure)
2. [Code style](#code-style)

## How to simulate

All the simulation scripts are stored inside the `sim` folder. From there, you can either run the testbench for single components or you can simulate the entire DLX microprocessor by running an assembly language program. Every testbench is self checking: the single component testbenches use VHDL assertions to check results, while the system-wide testbenches are tested using a Python emulator

Inside the `sim` folder, there is a `Makefile` that provides default commands for some common simulation tasks:
```sh
cd sim
make all # Run all testbenches for individual components
make testrom # Run the testrom.asm program, and check if results are correct.
```

More documentation is provided on the [README.md](./sim/README.md) file inside the `sim` folder.

The simulation tools will assume that you have Mentor's QuestaSim installed (version 2020 or above), and a relatively modern Python installation (at least Python 3.6).

## Folder structure

- The folder `codegen` contains some scripts that are used for code generation;
- The folder `components` contains all the components needed for the DLX as well as the DLX itself. Note that it's necessary to name them in a specific way, so that they're in the proper compile order;
- The folder `testbenches` contains test benches for each major component of the DLX, as well as the DLX itself.
- The folder `sim` contains all scripts needed for simulation, as well as scripts for:
    - An assembler for `dlx` machine code, written in Perl.
    - A python DLX emulator (inside `emulator`).
    - A program to test your .asm sources (inside `checker`).
    - A folder containing files to set up your waves inside QuestaSim.
    - A folder containing assembly programs (`programs`) to test the DLX.

## Code style

- Each component shall be named in PascalCase (`HazardUnit`).
- Each signal shall be named in snake_case (`multiply_request`).
    - Input signals shall be marked by the `i_` prefix (`i_clk`).
    - Output signals shall be marked by the `o_` prefix (`o_result`).
- Each testbench for a component shall be named `tb_ComponentName` (`tb_HazardUnit`).
- Each major component shall have a corresponding testbench in the `testbenches` folder, possibly with assertions.
- For signal and generic mappings, use the named style (`port map (x, y, z)` is bad, `port map (in1 => x, in2 => y, out => z)` is good).
- Each synchronous component shall have their active edge clock to be the rising edge.
- Each synchronous component shall have synchronous active low reset, and active high enable.
- Try to make all logic active high. Never use `write_n`, prefer `write_enable`.

