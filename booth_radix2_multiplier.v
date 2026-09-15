// =============================================================================
// booth_radix2_multiplier.v
//
// Classic (radix-2) Booth multiplier - the original 1951 algorithm, examining
// the multiplier b ONE BIT AT A TIME (as opposed to booth_multiplier.v, which
// is the modified radix-4 version examining 2 bits/group). Added alongside the
// radix-4 design to cover "Booth multiplier (with various radix)" from the
// project spec.
//
// Algorithm: for each bit position i = 0 .. WIDTH (WIDTH+1 steps - the extra
// step accounts for an implicit zero bit above the MSB, needed to correctly
// close out a run of 1s that reaches the top of b), look at the pair
// (b[i-1], b[i]) with b[-1] = 0 and b[WIDTH] = 0 (both virtual):
//
//   b[i-1] b[i]  |  action
//   ------------------------
//     0     0    |  no-op            (inside a run of 0s)
//     0     1    |  subtract A<<i    (start of a run of 1s)
//     1     0    |  add A<<i         (end of a run of 1s)
//     1     1    |  no-op            (inside a run of 1s)
//
// This recoding is exact for two's-complement values; since our operands are
// unsigned, A is simply zero-extended (never sign-extended) before being
// added/subtracted - the arithmetic is done in a wide enough accumulator that
// two's-complement wraparound during intermediate (possibly "negative")
// partial sums self-corrects by the final step, exactly like the radix-4
// module. Algorithm cross-checked exhaustively in Python (including bit-exact
// wraparound at this accumulator width) before writing this file.
//
// Verified in Vivado 2025.2 behavioural simulation - see
// booth_radix2_multiplier_tb.v. Close any previous simulation before running
// a new one (Simulation -> Close Simulation), and remember `run -all` in the
// Tcl Console if the default runtime cuts off before the final summary line.
//
// SIMPLIFIED VERSION (this revision): a_ext (a, zero-extended to the
// accumulator width) is now computed once outside the step loop instead of
// being redeclared fresh inside every single step - it never changes from
// step to step, so this is a pure tidy-up with no change in behaviour.
// =============================================================================

module booth_radix2_multiplier #(
    parameter WIDTH = 8
) (
    input      [WIDTH-1:0]    a,
    input      [WIDTH-1:0]    b,
    output     [2*WIDTH-1:0]  p
);

    localparam NUM_STEPS = WIDTH + 1;   // one step per bit, plus the closing step
    localparam ACCW       = 2*WIDTH + 4; // extra guard bits for intermediate sums

    // b_shift[0]      = virtual b[-1] = 0
    // b_shift[WIDTH:1]= b[WIDTH-1:0]
    // b_shift[WIDTH+1]= virtual b[WIDTH] = 0
    wire [WIDTH+1:0] b_shift = {1'b0, b, 1'b0};

    // a, zero-extended to the accumulator width (a is unsigned) - computed
    // once here rather than freshly inside every step, since it never
    // changes from one step to the next.
    wire [ACCW-1:0] a_ext = {{(ACCW-WIDTH){1'b0}}, a};

    wire [ACCW-1:0] acc [0:NUM_STEPS];
    assign acc[0] = {ACCW{1'b0}};

    genvar i;
    generate
        for (i = 0; i < NUM_STEPS; i = i + 1) begin : STEP
            wire bi   = b_shift[i+1];
            wire bim1 = b_shift[i];

            wire [ACCW-1:0] row_shifted = a_ext << i;

            assign acc[i+1] = (bim1 == 1'b0 && bi == 1'b1) ? (acc[i] - row_shifted) :
                              (bim1 == 1'b1 && bi == 1'b0) ? (acc[i] + row_shifted) :
                              acc[i];
        end
    endgenerate

    assign p = acc[NUM_STEPS][2*WIDTH-1:0];

endmodule
