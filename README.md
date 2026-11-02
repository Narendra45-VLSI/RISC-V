# RV32I CPU in Verilog

A single-cycle RISC-V (RV32I) CPU written from scratch in Verilog. It runs C programs
compiled with the GNU RISC-V toolchain and is simulated with Icarus Verilog.

## How it works
- `rtl/rv32i_core.v` : the CPU (decoder, ALU, register file, branches, loads/stores)
- `tb/tb.v`          : testbench with 16 KB memory, a print port at `0x10000000`
                       and a halt port at `0x10000004`
- `sw/`              : startup code, linker script and a C test program
- `Makefile`         : compiles the C code, converts it to hex, runs the simulation

## Requirements
    sudo apt install iverilog gtkwave gcc-riscv64-unknown-elf

## Run
    make
    gtkwave wave.vcd     # optional: view waveforms

Expected output:

    Hello from my own RISC-V CPU!
    HALT, exit code = 0

If your compiler is named `riscv64-linux-gnu-gcc`, run `make CROSS=riscv64-linux-gnu-`.

## Roadmap
- [ ] Larger test programs (sorting, Fibonacci, multiplication)
- [ ] 5-stage pipeline with forwarding and stalls
- [ ] riscv-tests suite and comparison against a reference simulator
- [ ] TL-Verilog version in Makerchip
- [ ] CPI comparison, single-cycle vs pipelined
