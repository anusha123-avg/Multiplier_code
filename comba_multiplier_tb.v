// =============================================================================
// comba_multiplier_tb.v
//
// Self-checking testbench for comba_multiplier - same pattern as the other
// architectures' testbenches. No dependency on other design files this time
// (comba_multiplier.v is fully self-contained).
//
// Vivado steps: add comba_multiplier.v as a DESIGN SOURCE, this file as a
// SIMULATION SOURCE, set it as simulation top, close any previous simulation
// first, then Run Behavioral Simulation ("run -all" if it stops early).
// =============================================================================

`timescale 1ns/1ps

module comba_multiplier_tb;

    localparam WIDTH = 8;

    reg  [WIDTH-1:0]   a, b;
    wire [2*WIDTH-1:0] p;
    integer errors;
    integer i;

    comba_multiplier #(.WIDTH(WIDTH)) DUT (
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

        check_one(0, 0);
        check_one({WIDTH{1'b1}}, {WIDTH{1'b1}});
        check_one(1, {WIDTH{1'b1}});
        check_one({WIDTH{1'b1}}, 1);
        check_one(8'd170, 8'd85);
        check_one(8'd15, 8'd16);

        for (i = 0; i < 1000; i = i + 1) begin
            check_one($random, $random);
        end

        if (errors == 0)
            $display(">>> ALL TESTS PASSED (6 directed + 1000 random vectors)");
        else
            $display(">>> %0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
