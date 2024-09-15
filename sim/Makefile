.PHONY: start_vsim all testrom coverage

start_vsim:
	vsim -do ./simulate.do

all: ./testvectors/division.mem
	vsim -c -do simulate.do -do simulate_all -do quit

./testvectors/division.mem: generate_testvectors.py
	python3 generate_testvectors.py

coverage:
	vsim -c -do simulate.do -do "simulate_all -coverage" -do quit

testrom:
	./dlx_sim/dlx_sim.py single ./programs/testrom.asm -esc -m 100000

clean:
	rm -f transcript
	rm -f *.wlf
	rm -f *.ucdb
	rm -f *.timestamp
	rm -rf ./build/

	vdel -all
