// =============================================================================
// schoolbook_wrapper.v
//
// "Characterization wrapper" for schoolbook_multiplier. Our 5 architecture
// modules are purely combinational (no clock) by design, so on their own
// Vivado has no registered timing path to analyse and can't report a max
// clock frequency (Fmax) - only a raw combinational delay. Wrapping the
// combinational multiplier between an input register stage and an output
// register stage gives Vivado a real registered path to run static timing
// analysis on, so it can report a genuine, literature-comparable Fmax in MHz
// after implementation.
//
// This is purely a measurement harness - it is NOT one of the 5 architectures
// itself, just a shell for characterizing schoolbook_multiplier's speed/area.
//
// Vivado sources needed: this file + schoolbook_multiplier.v (design
// sources), characterization.xdc (constraint). Set THIS module as the
// synthesis/implementation top (not simulation top - this has no testbench,
// it's for synthesis/implementation only).
// =============================================================================

module schoolbook_wrapper #(
    parameter WIDTH = 8
) (
    input                     clk,
    input      [WIDTH-1:0]    a_in,
    input      [WIDTH-1:0]    b_in,
    output reg [2*WIDTH-1:0]  p_out
);

    reg [WIDTH-1:0] a_reg, b_reg;
    wire [2*WIDTH-1:0] p_comb;

    schoolbook_multiplier #(.WIDTH(WIDTH)) DUT (
        .a(a_reg), .b(b_reg), .p(p_comb)
    );

    always @(posedge clk) begin
        a_reg <= a_in;
        b_reg <= b_in;
        p_out <= p_comb;
    end

endmodule
