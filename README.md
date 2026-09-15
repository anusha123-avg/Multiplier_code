# Optimized Large Multiplier Architectures on FPGAs

Final Year Project (module ELE34001), Queen's University Belfast.
Student: Anusha Raju Naik (40500252).

This repository holds the RTL for all seven multiplier architectures
implemented and compared in this project, plus the testbenches and
characterization harness used to produce every result reported in the
dissertation. Target device: Xilinx Artix-7 `xc7a35tcpg236-1`, Vivado 2025.2.

## Architectures

Seven parameterized (`WIDTH`-bit) unsigned multiplier designs, all purely
combinational (no clock inside the multiplier itself):

| Module | File | Idea |
|---|---|---|
| Schoolbook | `rtl/schoolbook_multiplier.v` | Baseline shift-add reference design |
| Booth radix-4 | `rtl/booth_multiplier.v` | 3-bit overlapping window, one signed digit per 2 bits of `b` |
| Booth radix-2 | `rtl/booth_radix2_multiplier.v` | Adjacent-bit-pair recoding, one digit per bit of `b` |
| Karatsuba (2-way) | `rtl/karatsuba_multiplier.v` | Divide-and-conquer, 3 half-width sub-multiplies instead of 4 |
| Comba | `rtl/comba_multiplier.v` | Column-wise procedural (`always @(*)`) partial-product accumulation |
| Toom-Cook (3-way) | `rtl/toom_cook_multiplier.v` | 3-limb split, 5 evaluation points, fixed interpolation network |
| Toom-Cook (4-way) | `rtl/toom_cook4_multiplier.v` | 4-limb split, 7 evaluation points, fixed 5x5 interpolation solve |

Full architecture diagrams, dataflow figures, and the derivation of each
design are in the dissertation (Chapters 3-4).

## Repository structure

```
rtl/            The 7 multiplier modules themselves (design under test)
wrappers/       Input/output-registered "characterization wrappers", one per
                architecture - these give Vivado a real clocked path so it
                can report Fmax for an otherwise fully combinational module.
                Not part of the architectures; a measurement harness only.
testbenches/    Self-checking testbenches, one per architecture, each
                comparing the module's output against a plain `a * b`
                behavioural model over directed + randomised vectors.
constraints/    characterization.xdc - the shared timing constraint used
                with whichever wrapper is set as the synthesis/
                implementation top. Edit the `-period` value per
                (architecture, width) configuration before each run; see
                the dissertation (Section 6.1/7.1) for the exact periods
                used for every one of the 27 characterised configurations.
```

## Simulating a testbench

Each `<name>_multiplier_tb.v` is self-contained and self-checking (it prints
PASS/FAIL and stops on first mismatch). With a simulator on your PATH, e.g.
Icarus Verilog:

```
iverilog -o sim rtl/schoolbook_multiplier.v testbenches/schoolbook_multiplier_tb.v
vvp sim
```

Or add the relevant `rtl/*.v` and `testbenches/*_tb.v` pair as sources in a
Vivado simulation-only project and run behavioural simulation with the
testbench as the simulation top.

## Synthesis / FPGA characterization (Vivado)

1. Create a Vivado project targeting `xc7a35tcpg236-1`.
2. Add the relevant `rtl/<name>.v` and `wrappers/<name>_wrapper.v` as design
   sources, and `constraints/characterization.xdc` as the constraint.
3. Set `<name>_wrapper` (not the testbench, not the bare multiplier module)
   as the synthesis/implementation top.
4. Edit the `-period` value in `characterization.xdc` to the target for this
   (architecture, width) configuration (see the dissertation for the exact
   values used), run Synthesis then Implementation, and read WNS from the
   Timing Summary report.
5. Fmax (MHz) = 1000 / (period - WNS). LUT/FF/DSP usage and on-chip power
   come from the Utilization and Power reports respectively.

## Results and analysis

All 27 characterised (architecture, width) configurations, the full
resource/timing/power dataset, comparison graphs, and the trade-off
discussion are in the accompanying dissertation - this repository is the
source code referenced from there, kept out of the report's appendix per
the project's supervisor feedback.
