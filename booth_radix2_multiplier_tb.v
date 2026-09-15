// =============================================================================
// booth_radix2_multiplier_tb.v
//
// Self-checking testbench for booth_radix2_multiplier - same pattern as the
// other testbenches: directed corner cases + 1000 random vectors, each
// checked against Verilog's own "*" as the golden reference.
//
// Vivado steps: add booth_radix2_multiplier.v as a DESIGN SOURCE, this file
// as a SIMULATION SOURCE, set this as simulation top, then Flow Navigator ->
// SIMULATION -> Run Behavioral Simulation. Close any previous simulation
// first, and remember `run -all` in the Tcl Console if the default runtime
// cuts off before the final summary line. Paste back the Tcl console output.
// =============================================================================

`timescale 1ns/1ps

module booth_radix2_multiplier_tb;

    localparam WIDTH = 8;

    reg  [WIDTH-1:0]   a, b;
    wire [2*WIDTH-1:0] p;
    integer errors;
    integer i;

    booth_radix2_multiplier #(.WIDTH(WIDTH)) DUT (
        .a(a),
        .b(b),
        .p(p)
    );

    task check_one(input [WIDTH-1:0] ta, input [WIDTH-1:0] tb);
        reg [2*WIDTH-1:0] expected;
        begin
            a = ta;
            b = tb;
            #1;
            expected = ta * tb;
            if (p !== expected) begin
                errors = errors + 1;
                $display("FAIL: a=%0d b=%0d expected=%0d got=%0d", ta, tb, expected, p);
            end else begin
                $display("pass: a=%0d b=%0d -> p=%0d", ta, tb, p);
            end
        end
    endtask

    initial begin
        errors = 0;

        // --- Directed cases ---
        check_one(0, 0);
        check_one({WIDTH{1'b1}}, {WIDTH{1'b1}});   // max * max
        check_one(1, {WIDTH{1'b1}});
        check_one({WIDTH{1'b1}}, 1);
        check_one(8'd5, 8'd7);                     // 5*7=35
        check_one(8'd32, 8'd68);                    // isolated single bit at the MSB-ish
                                                      // position - the case that first exposed
                                                      // the need for the extra "closing" step
                                                      // in the algorithm during verification
        check_one(8'd170, 8'd85);                   // alternating bit pattern
        check_one(8'd127, 8'd128);                  // exercises the top group's closing step

        // --- Randomized regression ---
        for (i = 0; i < 1000; i = i + 1) begin
            check_one($random, $random);
        end

        if (errors == 0)
            $display(">>> ALL TESTS PASSED (8 directed + 1000 random vectors)");
        else
            $display(">>> %0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
