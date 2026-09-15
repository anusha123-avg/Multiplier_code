// =============================================================================
// booth_multiplier_tb.v
//
// Self-checking testbench for booth_multiplier - same pattern as
// schoolbook_multiplier_tb.v: directed corner cases + 1000 random vectors,
// each checked against Verilog's own "*" as the golden reference.
//
// Vivado steps: same as before - add booth_multiplier.v as a DESIGN SOURCE,
// this file as a SIMULATION SOURCE, set this as simulation top, then
// Flow Navigator -> SIMULATION -> Run Behavioral Simulation. Paste back the
// Tcl console output.
// =============================================================================

`timescale 1ns/1ps

module booth_multiplier_tb;

    localparam WIDTH = 8;

    reg  [WIDTH-1:0]   a, b;
    wire [2*WIDTH-1:0] p;
    integer errors;
    integer i;

    booth_multiplier #(.WIDTH(WIDTH)) DUT (
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
        check_one(8'd5, 8'd7);                     // the hand-worked example: 5*7=35
        check_one(8'd170, 8'd85);                  // alternating bit pattern
        check_one(8'd15, 8'd16);
        check_one(8'd127, 8'd128);                 // exercises the top group's sign-extension bits

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
