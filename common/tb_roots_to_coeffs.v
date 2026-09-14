`timescale 1ns/1ns
`include "roots_to_coeffs.v"

module tb_roots_to_coeffs;
    parameter T = 2, M = 4;

    reg clk, rst, start;
    reg [T*M-1:0] roots;
    reg [$clog2(T+1)-1:0] num_found;

    wire [(T+1)*M-1:0] coeffs_out;
    wire done;

    roots_to_coeffs #(.T(T), .M(M)) DUT (
        .clk(clk), .rst(rst), .start(start),
        .roots(roots), .num_found(num_found),
        .coeffs_out(coeffs_out), .done(done)
    );

    always #5 clk = ~clk;

    function [8*6-1:0] gf_str;
        input [M-1:0] val;
        begin
            case(val)
                4'b0000: gf_str = "0    ";
                4'b1000: gf_str = "a^0  ";
                4'b0100: gf_str = "a^1  ";
                4'b0010: gf_str = "a^2  ";
                4'b0001: gf_str = "a^3  ";
                4'b1100: gf_str = "a^4  ";
                4'b0110: gf_str = "a^5  ";
                4'b0011: gf_str = "a^6  ";
                4'b1101: gf_str = "a^7  ";
                4'b1010: gf_str = "a^8  ";
                4'b0101: gf_str = "a^9  ";
                4'b1110: gf_str = "a^10 ";
                4'b0111: gf_str = "a^11 ";
                4'b1111: gf_str = "a^12 ";
                4'b1011: gf_str = "a^13 ";
                4'b1001: gf_str = "a^14 ";
                default: gf_str = "??   ";
            endcase
        end
    endfunction

    integer g;

    initial begin
        clk = 0; rst = 1; start = 0; roots = 0; num_found = 0;
        #12;
        rst = 0;
        #5;

        // Test: roots = alpha^0, alpha^12 (num_found=2)
        roots = {4'b1111, 4'b1000};  // {a2=alpha^12, a1=alpha^0} packed low-to-high
        num_found = 2;
        start = 1;
        #10;
        start = 0;

        wait(done);
        #1;
        $write("roots=[a^0, a^12], num_found=2 -> coeffs = ");
        for (g = 0; g <= T; g = g + 1)
            $write("%s ", gf_str(coeffs_out[(g+1)*M-1 -: M]));
        $display("(expect a^0 a^14 a^3)");

        #10; rst = 1; #10; rst = 0; #5;

        // Test: single root alpha^14, num_found=1 (unused slot = 0)
        roots = {4'b0100, 4'b0010};  // {a2=0 (unused), a1=alpha^14}
        num_found = 2;
        start = 1;
        #10;
        start = 0;

        wait(done);
        #1;
        $write("roots=[a^1, a^2], num_found=2 -> coeffs = ");
        for (g = 0; g <= T; g = g + 1)
            $write("%s ", gf_str(coeffs_out[(g+1)*M-1 -: M]));
        //$display("(expect a^0 a^1 0)");

        #10;
        $finish;
    end
endmodule