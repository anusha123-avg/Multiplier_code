module toom_cook_multiplier #(
    parameter WIDTH = 8   // WIDTH >= 6 recommended for a meaningful 3-way split
) (
    input  [WIDTH-1:0]    a,
    input  [WIDTH-1:0]    b,
    output reg [2*WIDTH-1:0] p
);

    localparam THIRD = (WIDTH + 2) / 3;      // ceil(WIDTH/3): digit width for a0,a1,b0,b1
    localparam TOP   = WIDTH - 2*THIRD;      // width of the top digit a2/b2 (TOP <= THIRD)

    localparam EW    = THIRD + 4;            // evaluation-point width (signed), generous margin
    localparam IW    = 2*EW + 4;             // pointwise-product / interpolation width (signed)
    localparam ACCW  = 6*THIRD + 16;         // final recombination accumulator width (unsigned)

    // Raw digit slices (unsigned).
    wire [THIRD-1:0] a0_raw = a[THIRD-1:0];
    wire [THIRD-1:0] a1_raw = a[2*THIRD-1:THIRD];
    wire [THIRD-1:0] a2_raw = a[WIDTH-1:2*THIRD];   // TOP bits, implicitly zero-extended below
    wire [THIRD-1:0] b0_raw = b[THIRD-1:0];
    wire [THIRD-1:0] b1_raw = b[2*THIRD-1:THIRD];
    wire [THIRD-1:0] b2_raw = b[WIDTH-1:2*THIRD];

    // Widened signed copies of the digits, and every other working value -
    // declaring everything `signed` from here on keeps all the arithmetic
    // below unambiguous.
    reg signed [EW-1:0] a0, a1, a2, b0, b1, b2;
    reg signed [EW-1:0] A0, A1, Am1, A2, Ainf;
    reg signed [EW-1:0] B0, B1, Bm1, B2, Binf;
    reg signed [IW-1:0] v0, v1, vm1, v2, vinf;
    reg signed [IW-1:0] c0, c1, c2, c3, c4;
    reg signed [IW-1:0] t1, t2, r_full, r_half, num3;

    reg [ACCW-1:0] acc;

    always @(*) begin
        a0 = a0_raw; a1 = a1_raw; a2 = a2_raw;
        b0 = b0_raw; b1 = b1_raw; b2 = b2_raw;

        // --- Step 1: evaluate at x = 0, 1, -1, 2, infinity ---
        // Plain words: A(x) = a0 + a1*x + a2*x^2, so plugging in each x just
        // means substituting that number for x below. "Infinity" isn't a
        // real division - for a degree-2 polynomial the x^2 term dominates
        // as x grows huge, so A(infinity) is defined as just its leading
        // coefficient, a2 (same trick used again in toom_cook4_multiplier.v).
        A0   = a0;
        A1   = a0 + a1 + a2;
        Am1  = a0 - a1 + a2;
        A2   = a0 + 2*a1 + 4*a2;
        Ainf = a2;

        B0   = b0;
        B1   = b0 + b1 + b2;
        Bm1  = b0 - b1 + b2;
        B2   = b0 + 2*b1 + 4*b2;
        Binf = b2;

        // --- Step 2: 5 pointwise multiplications (instead of 9) ---
        // Plain words: C(x) = A(x)*B(x) is also a polynomial, and any
        // degree-4 polynomial is completely pinned down by its value at any
        // 5 points - so multiplying A and B at just these 5 x-values gives
        // enough information to rebuild every coefficient of C(x) in Step 3,
        // without ever multiplying the full-width digits against each other.
        v0   = A0   * B0;
        v1   = A1   * B1;
        vm1  = Am1  * Bm1;
        v2   = A2   * B2;
        vinf = Ainf * Binf;

        // --- Step 3: interpolate back to c0..c4 ---
        // Plain words: this whole block is just algebra, solved once on
        // paper (offline) and typed in here as a fixed recipe - nothing
        // about it changes at run time. c0 and c4 fall out for free (they
        // ARE v0 and vinf). t1 isolates the three even-numbered unknowns
        // (c0+c2+c4) by averaging v1 and vm1 - the odd-numbered ones
        // (c1, c3) cancel out when you add A(1)*B(1) to A(-1)*B(-1) because
        // of the alternating +/- signs used when x=-1. t2 does the mirror
        // trick (subtracting instead of adding) to isolate c1+c3 instead.
        // From there each remaining unknown is peeled off one at a time by
        // subtracting the ones already known. The /2 and /3 below are exact
        // (no remainder) by construction - proven in Python before this file
        // was written - so plain integer division is safe here, not an
        // approximation.
        c0 = v0;
        c4 = vinf;

        t1 = (v1 + vm1) / 2;              // = c0 + c2 + c4
        t2 = (v1 - vm1) / 2;              // = c1 + c3

        c2 = t1 - c0 - c4;                // the only even-indexed unknown left, once c0/c4 are subtracted out

        r_full = v2 - c0 - 4*c2 - 16*c4;  // = 2*(c1 + 4*c3)   (strip out everything already known from A(2)*B(2))
        r_half = r_full / 2;              // = c1 + 4*c3

        num3 = r_half - t2;               // = 3*c3   (exact division below)
        c3   = num3 / 3;
        c1   = t2 - c3;                   // last unknown - whatever's left of (c1+c3) once c3 is known

        // --- Step 4: recombine (c0..c4 are guaranteed non-negative here) ---
        // Plain words: same idea as reading off a number's digits - each ci
        // gets shifted into its own "place value" (multiples of THIRD bits)
        // and added up, exactly like 1*1000+2*100+3*10+4 in ordinary base 10,
        // just with 5 "digits" instead of 4 and base 2^THIRD instead of 10.
        acc = ({{(ACCW-IW){1'b0}}, $unsigned(c0)})
            + ({{(ACCW-IW){1'b0}}, $unsigned(c1)} << THIRD)
            + ({{(ACCW-IW){1'b0}}, $unsigned(c2)} << (2*THIRD))
            + ({{(ACCW-IW){1'b0}}, $unsigned(c3)} << (3*THIRD))
            + ({{(ACCW-IW){1'b0}}, $unsigned(c4)} << (4*THIRD));

        p = acc[2*WIDTH-1:0];
    end

endmodule
