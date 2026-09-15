# =============================================================================
# characterization.xdc
#
# Shared timing constraint for characterizing max clock frequency (Fmax) of
# whichever *_wrapper.v module is currently set as the synthesis/implementation
# top. All 7 wrapper modules use the same port names (clk, a_in, b_in, p_out),
# so this one constraint file works for all of them - no need to edit it when
# switching between architectures, other than the -period value itself.
#
# UPDATED FLOW (per supervisor feedback that WNS must not be negative in the
# final results): every (architecture, width) config now gets its OWN -period
# value, chosen so the real critical path fits inside it with margin - i.e.
# WNS comes out positive by construction, instead of one shared too-tight
# 10ns target used for every config. See the "Re-run Plan (clean WNS)" tab in
# Results_Tracker.xlsx for every config's exact period. Change the -period
# value below to that config's number before each Synthesis/Implementation
# run, then read WNS straight from the Timing Summary report - it should
# already be non-negative. Fmax is still:
#
#     Fmax (MHz) = 1000 / (PERIOD - WNS)
#
# e.g. period=15.000, WNS=+4.138 -> real critical path = 15.0-4.138 = 10.862ns,
# so Fmax = 1000/10.862 = ~92 MHz. The formula is exactly the same one used
# throughout this project - only the period changes per config now, not the
# formula.
#
# CURRENT SETTING BELOW: 10.000 ns - this is Schoolbook, WIDTH=8's target
# (Step 1 of the full re-confirmation walk, going through every architecture
# in order: Schoolbook -> Booth Radix-4 -> Booth Radix-2 -> Karatsuba ->
# Comba -> Toom-Cook 3-way -> Toom-Cook 4-way, 8/16/32/64-bit each time).
# Change this line for every subsequent run - see the full sequence table.
# =============================================================================

create_clock -period 10.000 -name clk [get_ports clk]
