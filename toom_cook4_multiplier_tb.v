// =============================================================================
// toom_cook4_multiplier_tb.v
//
// Self-checking testbench for toom_cook4_multiplier - same pattern as the
// other architectures' testbenches. Self-contained (no dependency on other
// design files).
//
// Vivado steps: add toom_cook4_multiplier.v as a DESIGN SOURCE, this file as
// a SIMULATION SOURCE, set it as simulation top, close any previous
// simulation first, then Run Behavioral Simulation ("run -all" if it stops
// early).
// =============================================================================

`timescale 1ns/1ps

module toom_cook4_multiplier_tb;

    localparam WIDTH = 8;

    reg  [WIDTH-1:0]   a, b;
    wire [2*WIDTH-1:0] p;
    integer errors;
    integer i;

    toom_cook4_multiplier #(.WIDTH(WIDTH)) DUT (
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

        // --- Directed cases, exercising all 4 limbs (WIDTH=8 -> LW=2 bits
        // per limb) and the negative intermediate evaluations (A(-1), A(-2)) ---
        check_one(0, 0);
        check_one({WIDTH{1'b1}}, {WIDTH{1'b1}});   // max * max
        check_one(1, {WIDTH{1'b1}});
        check_one({WIDTH{1'b1}}, 1);
        check_one(8'b11_00_00_00, 8'b00_00_00_11); // a3=top limb only, b0=bottom limb only
        check_one(8'b10_01_10_01, 8'b01_10_01_10); // alternating limb pattern
        check_one(8'd170, 8'd85);
        check_one(8'd15, 8'd16);

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
