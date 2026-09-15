// =============================================================================
// comba_multiplier.v
//
// Comba multiplier, unsigned, parameterized WIDTH.
//
// As discussed in the report's literature review: Comba is NOT an
// asymptotically faster algorithm than schoolbook - it computes exactly the
// same set of WIDTH*WIDTH one-bit partial products (a[j] & b[i]). What
// differs is the ORDER they're summed in: schoolbook adds WIDTH full-width
// shifted rows one after another (see schoolbook_multiplier.v); Comba
// instead processes the output COLUMN BY COLUMN (by output bit position k),
// summing every partial product that lands on that column (i.e. every
// a[j]&b[i] pair with i+j==k) together with the carry propagating in from
// the column before it. This column-wise scheduling is what makes Comba
// attractive on real hardware - fewer values need to be held "in flight" at
// once compared to accumulating full-width rows.
//
// This is implemented with an unrolled `for` loop inside a combinational
// always block rather than nested generate blocks, since the number of
// partial-product terms landing in each column varies (it grows then shrinks
// like a triangle) - a plain for-loop with an `integer` index is the
// standard, synthesizable way to express that in Verilog. WIDTH is a
// parameter, so the loop bounds are fixed at elaboration time.
//
// carry/col_sum are WIDTH bits wide, which is far more headroom than needed
// (the true maximum carry value between columns stays well below WIDTH) but
// keeps the margin obviously safe for every width used in this project.
//
// This exact algorithm was verified in Python first: exhaustively for 4-bit
// and 8-bit operands (also checking that no carry is ever left over after
// the last column, confirming the product fits exactly in 2*WIDTH bits), and
// against 50,000 random 32-bit cases.
// =============================================================================

module comba_multiplier #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0]        a,
    input  [WIDTH-1:0]        b,
    output reg [2*WIDTH-1:0]  p
);

    integer i, j, k;
    reg [WIDTH-1:0] carry;    // carry running INTO the current output column
    reg [WIDTH-1:0] col_sum;  // running total for the current output column

    // Plain-words walkthrough (do this by hand on paper the same way):
    //   Write a[j]&b[i] in a grid, row i, column j. Every cell that shares the
    //   same (i+j) sits in the same output column k. Comba just adds up one
    //   whole column at a time, left to right (k = 0, 1, 2, ...), carrying
    //   into the next column exactly like carrying a digit when you add two
    //   decimal numbers by hand.
    always @(*) begin
        carry = {WIDTH{1'b0}};                    // no carry before the first column
        for (k = 0; k < 2*WIDTH; k = k + 1) begin // k = which output bit we're building
            col_sum = carry;                      // start this column with the carry-in
            for (i = 0; i < WIDTH; i = i + 1) begin
                j = k - i;                        // the partner index so that i+j = k
                if (j >= 0 && j < WIDTH) begin
                    // a[j]&b[i] is 1 only if BOTH bits are 1 - that's exactly
                    // the same single-bit product used in the schoolbook
                    // design, just added into the grid in a different order.
                    col_sum = col_sum + (a[j] & b[i]);
                end
            end
            p[k]  = col_sum[0];   // this column's own output bit is the low bit of the total
            carry = col_sum >> 1; // everything else carries forward into column k+1
        end
    end

endmodule
