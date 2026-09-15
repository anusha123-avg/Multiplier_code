// =============================================================================
// karatsuba_multiplier.v
//
// 2-way Karatsuba multiplier, unsigned, parameterized WIDTH (must be even).
//
// Idea (matches the split/recombine example in the project spec): split each
// WIDTH-bit operand into a high half and low half of HALF = WIDTH/2 bits each:
//   a = ah * 2^HALF + al          b = bh * 2^HALF + bl
//
// The direct expansion needs 4 sub-multiplications (ah*bh, ah*bl, al*bh,
// al*bl). Karatsuba's trick needs only 3:
//   z2 = ah*bh
//   z0 = al*bl
//   z1 = (ah+al)*(bh+bl) - z2 - z0      <- this equals ah*bl + al*bh
// Then:
//   p = (z2 << WIDTH) + (z1 << HALF) + z0
//
// This project uses schoolbook multipliers as the "inner" multipliers for the
// 3 sub-multiplications, exactly as described in the reference literature
// (Rafferty et al. and the TTech-LIB papers both build Karatsuba this way).
// This file therefore depends on schoolbook_multiplier.v - both files must be
// added as DESIGN SOURCES in Vivado for this to compile.
//
// (ah+al) and (bh+bl) can be one bit wider than HALF (e.g. 0xF + 0xF = 0x1E
// needs 5 bits for HALF=4), so the "middle" multiplication uses a
// schoolbook_multiplier instance parameterized to HALF+1 bits, not HALF.
//
// This exact algorithm (including the sum-overflow handling) was verified in
// Python first: exhaustively for 4-bit and 8-bit operands, and against
// 200,000 random 16-bit cases, before being written here.
// =============================================================================

module karatsuba_multiplier #(
    parameter WIDTH = 8   // must be even
) (
    input  [WIDTH-1:0]    a,
    input  [WIDTH-1:0]    b,
    output [2*WIDTH-1:0]  p
);

    localparam HALF = WIDTH / 2;

    // Split each operand into high/low halves.
    wire [HALF-1:0] ah = a[WIDTH-1:HALF];
    wire [HALF-1:0] al = a[HALF-1:0];
    wire [HALF-1:0] bh = b[WIDTH-1:HALF];
    wire [HALF-1:0] bl = b[HALF-1:0];

    // z2 = ah*bh, z0 = al*bl - each a HALF x HALF -> WIDTH-bit multiplication,
    // done with an inner schoolbook multiplier.
    wire [2*HALF-1:0] z2, z0;

    schoolbook_multiplier #(.WIDTH(HALF)) MUL_HIGH (
        .a(ah), .b(bh), .p(z2)
    );

    schoolbook_multiplier #(.WIDTH(HALF)) MUL_LOW (
        .a(al), .b(bl), .p(z0)
    );

    // sum_a = ah+al, sum_b = bh+bl - one bit wider than HALF to hold a
    // possible carry (e.g. for HALF=4: 15+15=30 needs 5 bits).
    wire [HALF:0] sum_a = {1'b0, ah} + {1'b0, al};
    wire [HALF:0] sum_b = {1'b0, bh} + {1'b0, bl};

    // "Middle" multiplication: (ah+al) x (bh+bl), each HALF+1 bits wide.
    wire [2*(HALF+1)-1:0] cross;

    schoolbook_multiplier #(.WIDTH(HALF+1)) MUL_MID (
        .a(sum_a), .b(sum_b), .p(cross)
    );

    // z1 = cross - z2 - z0 (mathematically guaranteed non-negative). Widening
    // z2/z0 up to cross's width happens automatically since they're assigned
    // into a same-or-wider context below.
    localparam ZW = 2*(HALF+1);
    wire [ZW-1:0] z1 = cross - z2 - z0;

    // Recombine: p = (z2 << WIDTH) + (z1 << HALF) + z0.
    // Zero-extending each term to the full 2*WIDTH-bit product width happens
    // automatically on assignment to these wider wires.
    wire [2*WIDTH-1:0] z2_ext = z2;
    wire [2*WIDTH-1:0] z1_ext = z1;
    wire [2*WIDTH-1:0] z0_ext = z0;

    assign p = (z2_ext << WIDTH) + (z1_ext << HALF) + z0_ext;

endmodule
