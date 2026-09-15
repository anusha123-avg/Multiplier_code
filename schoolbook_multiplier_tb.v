// =============================================================================
// schoolbook_multiplier_tb.v
//
// Self-checking testbench for schoolbook_multiplier.
//
// This is NOT synthesizable and is NOT meant to be - it only runs in
// simulation. Its job is to drive inputs at the DUT (device under test) and
// automatically check the output against Verilog's own built-in "*"
// operator, which we trust as the golden reference here.
//
// How to run this in Vivado 2025.2 (behavioral simulation):
//   1. Create/open your project, target part xc7a35tcpg236-1.
//   2. Add schoolbook_multiplier.v as a DESIGN SOURCE
//      (Add Sources -> Add or Create Design Sources).
//   3. Add schoolbook_multiplier_tb.v as a SIMULATION SOURCE
//      (Add Sources -> Add or Create Simulation Sources).
//   4. In the Sources panel, under Simulation Sources, right-click
//      schoolbook_multiplier_tb and "Set as Top" if it isn't already.
//   5. Flow Navigator -> SIMULATION -> Run Simulation -> Run Behavioral
//      Simulation.
//   6. Look at the Tcl Console / log output for the PASS/FAIL messages
//      printed below. Paste that output back so we can debug together if
//      anything fails.
// =============================================================================

`timescale 1ns/1ps

module schoolbook_multiplier_tb;

    localparam WIDTH = 8;

    reg  [WIDTH-1:0]   a, b;
    wire [2*WIDTH-1:0] p;
    integer errors;
    integer i;

    // Device under test
    schoolbook_multiplier #(.WIDTH(WIDTH)) DUT (
        .a(a),
        .b(b),
        .p(p)
    );

    // Checks one (a,b) pair against the expected product, prints a
    // PASS/FAIL line, and bumps the error counter on mismatch.
    task check_one(input [WIDTH-1:0] ta, input [WIDTH-1:0] tb);
        reg [2*WIDTH-1:0] expected;
        begin
            a = ta;
            b = tb;
            #1; // let the combinational logic settle
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

        // --- Directed corner cases first ---
        check_one(0, 0);                          // 0 * 0
        check_one({WIDTH{1'b1}}, {WIDTH{1'b1}});   // max * max
        check_one(1, {WIDTH{1'b1}});               // 1 * max
        check_one({WIDTH{1'b1}}, 1);               // max * 1
        check_one(8'd170, 8'd85);                  // alternating bit pattern
        check_one(8'd15, 8'd16);

        // --- Randomized regression: 1000 random vectors ---
        for (i = 0; i < 1000; i = i + 1) begin
            check_one($random, $random);
        end

        // --- Summary ---
        if (errors == 0)
            $display(">>> ALL TESTS PASSED (%0d directed + 1000 random vectors)", 6);
        else
            $display(">>> %0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
