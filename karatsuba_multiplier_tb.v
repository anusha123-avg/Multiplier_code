// =============================================================================
// karatsuba_multiplier_tb.v
//
// Self-checking testbench for karatsuba_multiplier - same pattern as the
// Schoolbook and Booth testbenches.
//
// Vivado steps: add karatsuba_multiplier.v AND schoolbook_multiplier.v as
// DESIGN SOURCES (Karatsuba instantiates schoolbook internally, so both are
// required), add this file as a SIMULATION SOURCE, set it as simulation top,
// then Flow Navigator -> SIMULATION -> Run Behavioral Simulation. If it stops
// before printing the final summary, type "run -all" in the Tcl Console.
// Remember to close the previous simulation first (Simulation -> Close
// Simulation) if you hit the "file in use" error again.
// =============================================================================

`timescale 1ns/1ps

module karatsuba_multiplier_tb;

    localparam WIDTH = 8;

    reg  [WIDTH-1:0]   a, b;
    wire [2*WIDTH-1:0] p;
    integer errors;
    integer i;

    karatsuba_multiplier #(.WIDTH(WIDTH)) DUT (
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
        check_one({WIDTH{1'b1}}, {WIDTH{1'b1}});   // max * max  -> exercises largest sum_a/sum_b overflow
        check_one(1, {WIDTH{1'b1}});
        check_one({WIDTH{1'b1}}, 1);
        check_one(8'd15, 8'd15);                   // al=bl=15 (max low half) with ah=bh=0
        check_one(8'd240, 8'd240);                 // ah=bh=15 (max high half) with al=bl=0
        check_one(8'd170, 8'd85);
        check_one(8'd127, 8'd128);

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
