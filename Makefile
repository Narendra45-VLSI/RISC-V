.RECIPEPREFIX := >
CROSS  ?= riscv64-unknown-elf-
CFLAGS := -march=rv32i -mabi=ilp32 -O1 -nostdlib -ffreestanding -Wl,-T,sw/link.ld

sim: prog.hex rtl/rv32i_core.v tb/tb.v
> iverilog -g2012 -o sim.vvp rtl/rv32i_core.v tb/tb.v
> vvp sim.vvp

prog.elf: sw/start.S sw/main.c sw/link.ld
> $(CROSS)gcc $(CFLAGS) -o $@ sw/start.S sw/main.c

prog.hex: prog.elf
> $(CROSS)objcopy -O binary $< prog.bin
> od -An -v -tx4 -w4 prog.bin | tr -d ' ' > $@

clean:
> rm -f sim.vvp prog.elf prog.bin prog.hex wave.vcd
