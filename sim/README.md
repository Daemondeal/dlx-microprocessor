# DLX simulation scripts

This folder contains a collection of all scripts used to simulate the project. These scripts manage:
- Simulating the regular single component testbenches.
- Simulating the DLX system.
- Running software emulations of the DLX microprocessor.
- Checking the resulting memory dumps against the expected values specified in the assembly file.

## Script parameters reference

### Single component testbenches

Single component testbenches can be run by using the `simulate.do` Tcl script, which provides some utilities for working with the simulator. An example usage is:
```sh
# This will load the ALU testbench and run the simulation until it finishes.
vsim -c -do simulate.do -do "start_sim tb_ALU"
```

The script provides two main procedures:
- `start_sim`: set up the simulator and then starts the simulation;
- `resim`: recompile all sources and restart the simulation.

#### `start_sim`

```tcl
start_sim <testbench - name> \
    [ -top <testbench>] \
    [ -generics <generics_list>] \
    [ -wavefile <wavefile_path>] \
    [ -precision <precision_with_unit>] \
    [ -time <nanoseconds_to_simulate>] \
    [ -compile <true / false>]
```

Starts the simulation for the specified testbench. This command will compile all sources and run the testbench with `run -all` if no other parameters are passed. The task of stopping the simulation is given to the testbench itself, which will have to terminate on it’s own. If this command is run with only one parameter, it will use that as the top entity name and leave everything as default. Otherwise, it takes these parameters:
- `-top`: The name of top entity to simulate.
- `-generics`: A comma-separated list of generics to set on the top entity to simulate. Defaults to an empty string.
- `-wavefile`: The file where to store the simulated waveform. Defaults to `waves.wlf`.
- `-wave_setup`: The name of the Tcl file to execute to load the waves to display in the GUI. If not specified, it will load all the signals in the testbench entity by default.
- `-precision`: The time precision of the simulation. Defaults to 10 ps.
- `-time`: The amount of time to simulate. If not given, the simulation will continue until the testbench stops on its own.
- `-compile`: Whether to compile or not before starting the simulation. Defaults to true.

Examples:
```tcl
# Starts the simulation with default arguments
start_sim tb_AdderSubtractor

# Starts the simulation changing some optional parameters
start_sim -top tb_MemorySystem \
    -generics {DUMP=./testvectors/example.mem,PROGRAM=./testvectors/memory.mem} \
    -wave_setup ./waves_setup/memorysystem_waves.do 
```

#### `resim`

```tcl
resim [<nanoseconds_to_simulate]
```

Recompiles all sources, and starts a new simulation of the currently chosen entity. This command is useful during the design phase, on when working on a fix, since it allows for quick iteration time. The command takes as an optional parameter the number of nanoseconds for which to run the simulation. If the parameter is not given, the default is to run the simulation indefinitely until the testbench stops by itself.

### Full system testbenches

For full system simulations, the `dlx_sim.py` scripts is used instead. This scripts handles the whole compilation, simulation and check flow, starting from the assembly and printing out all reports.

All the results of these scripts are saved in the `build/<program_name>` folder, and these files include:

- `emulator.trace` and `simulator.trace`: the files which include the execution trace (that is the list of instructions ran, and for the emulator also the program counter location and operands) of both emulator and simulator.
- `<program_name>.sym`: the list of symbols of the compiled assembly, which consists in a list of all labels found in the assembly file and the address they got put at.
- `<program_name>.mem`: the hex initialization file for memory, in a format that's convenient to load for both the top testbench and the Python emulator.
- `<program_name>_emu_dump.mem` and `<program_name>_sim_dump.mem`: respectively the emulator's final memory state dump and the simulator's final memory state dump.

#### `dlx_sim gui`
```sh
dlx_sim gui <program_path> [-o <target_directory>] [--max-cycles <max_cycles>]
```

Assembles the given assembly program, then starts QuestaSim in GUI mode and then starts the simulation. The parameters are:

- `-o`: Specifies the target directory for outputs. Defaults to `./build/`
- `--max-cycles`: Specifies the maximum number of cycles to run before the simulation aborts. Defaults to 30'000.

#### `dlx_sim single`

```sh
dlx_sim single <program_name> \
    [-o <target_directory>] \
    [--emulator] \
    [--cpu-sim] \
    [--check] \
    [--print-variable] \
    [--max-cycles <max_cycles>]
```

Starts the whole emulation flow, including assembling the given program, running the Python emulator, running QuestaSim in command line mode and checking the resulting memory dumps. The arguments are:
- `-o`: Specifies the target directory for outputs. Defaults to `./build/`
- `--max-cycles`: Specifies the maximum number of cycles to run before the simulation aborts. Defaults to 30'000.
- `--emulator`: Starts the Python emulator after the assembler.
- `--cpu-sim`: Starts the QuestaSim CPU simulation emulator after the assembler and the emulator.
- `--check`: Checks that the resulting memory dump is compliant with the tests written in the assembly source. If both CPU simulation and emulation are enabled, it will check the CPU memory dump; otherwise if only emulation is enable it will check the emulator's memory dump.
- `--print-variable`: Prints all the variables specified in the assembly file in the console. It will take them from the CPU simulation dump if enabled, otherwise from the emulator dump. 

Example:
```sh
./dlx_sim/dlx_sim.py single --emulator --cpu-sim -check ./programs/testrom.asm
```

#### `dlx_sim all`
```sh
dlx_sim all \
    [-o <target_directory>] \
    [--max-cycles <max_cycles>] \
    [--tests-file-path <test_file_path>]
```

Runs the simulation for all assembly files specified in the `test_file`.

- `-o`: Specifies the target directory for outputs. Defaults to `./build/`
- `--max-cycles`: Specifies the maximum number of cycles to run before the simulation aborts. Defaults to 200'000.
- `--tests-file-path`: Specifies the file which contains all the tests to run. Defaults to `tests.list`.
