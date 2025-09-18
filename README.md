# 8-Point FFT DSP Unit

## Implementation
SystemVerilog × Xilinx Vivado.

## Features
**Pipelined.** 3-stage pipelined for each butterfly.
**ASIC Synthesizable.** Q1.15 fixed-point (vs floating) to avoid PPA overheads.
**Radix-2 DIT.** Decimation in time, Cooley–Tukey algorithm.