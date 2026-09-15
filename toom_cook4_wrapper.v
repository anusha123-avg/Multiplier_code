// =============================================================================
// toom_cook4_wrapper.v - characterization wrapper for toom_cook4_multiplier.
// See schoolbook_wrapper.v for the full explanation of why this exists.
// Requires: this file + toom_cook4_multiplier.v (design sources) +
// characterization.xdc (constraint). Set as synthesis/implementation top.
// =============================================================================

module toom_cook4_wrapper #(
    parameter WIDTH = 8
) (
    input                     clk,
    input      [WIDTH-1:0]    a_in,
    input      [WIDTH-1:0]    b_in,
    output reg [2*WIDTH-1:0]  p_out
);

    reg [WIDTH-1:0] a_reg, b_reg;
    wire [2*WIDTH-1:0] p_comb;

    toom_cook4_multiplier #(.WIDTH(WIDTH)) DUT (
        .a(a_reg), .b(b_reg), .p(p_comb)
    );

    always @(posedge clk) begin
        a_reg <= a_in;
        b_reg <= b_in;
        p_out <= p_comb;
    end

endmodule
