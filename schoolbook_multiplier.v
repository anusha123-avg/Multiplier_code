// =============================================================================
// schoolbook_multiplier.v
//
// Baseline "schoolbook" (shift-add) unsigned multiplier.
// This is your reference / golden architecture: every other architecture
// (Booth, Karatsuba, Comba, Toom-Cook) will be compared against this one for
// both correctness and FPGA resource/speed results.
//
// Algorithm (same one you'd do by hand on paper):
//   For each bit k of b:
//     - if b[k] = 1, the partial product row k is "a" itself
//     - if b[k] = 0, the partial product row k is all zeros
//     - that row is shifted left by k places before being added in
//   p = sum of all WIDTH partial product rows
//
// WIDTH is parameterized so the same module can be re-used at 8, 16, 32 bits
// etc. Start with WIDTH=8 while learning/debugging (fast simulation, easy to
// check answers by hand), then scale up later for the FPGA evaluation runs.
//
// SIMPLIFIED VERSION (this revision): the partial-product row pp[k] and its
// use in acc[k+1] used to live in two separate generate loops with their own
// wire array in between. They're now built in a single loop instead - pp[k]
// is computed right where it's used - which removes one whole wire array and
// one generate block without changing what gets computed at all (pp[k] was
// only ever read once, inside acc[k+1]'s own assignment).
// =============================================================================

module schoolbook_multiplier #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0]    a,   // multiplicand
    input  [WIDTH-1:0]    b,   // multiplier
    output [2*WIDTH-1:0]  p    // product (always 2*WIDTH bits wide - that's the
                                // max size two WIDTH-bit numbers can produce)
);

    // ---------------------------------------------------------------------
    // One row per bit of b, added into a running total as we go:
    //   pp[k]    = a & {WIDTH{b[k]}}   -> "a" if b[k]=1, all-zeros if b[k]=0
    //              ({WIDTH{b[k]}} replicates the single bit b[k] WIDTH
    //              times, e.g. b[k]=1, WIDTH=8 -> 8'b11111111, and ANDing
    //              with "a" just copies it through; b[k]=0 zeroes the row)
    //   acc[0]   = 0
    //   acc[k+1] = acc[k] + (pp[k] << k)
    // acc[WIDTH] is the finished product. Every acc[] wire is the full
    // 2*WIDTH bits wide so nothing overflows as the shifted rows are added
    // in. This add-a-shifted-row-at-a-time chain is exactly the "structure"
    // the optimized architectures (Booth, Karatsuba, etc.) try to shorten.
    // ---------------------------------------------------------------------
    wire [2*WIDTH-1:0] acc [0:WIDTH];
    assign acc[0] = {2*WIDTH{1'b0}};

    genvar k;
    generate
        for (k = 0; k < WIDTH; k = k + 1) begin : GEN_ADD_STAGES
            wire [WIDTH-1:0] pp = a & {WIDTH{b[k]}};
            assign acc[k+1] = acc[k] + ({{WIDTH{1'b0}}, pp} << k);
        end
    endgenerate

    assign p = acc[WIDTH];

endmodule
