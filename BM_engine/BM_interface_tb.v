`timescale 1ns/1ns
`include "BM_interface.v"

module BM_interface_tb;
    localparam T = 2;
    localparam M = 4;

    reg clk, rst, start;
    reg [15:0] synd;

    wire done;
    wire [11:0] sigma_out;

    BM_interface #(.T(T), .M(M)) DUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .synd(synd),
        .sigma_out(sigma_out)
    );

    always #5 clk = ~clk;

    task prepare_synd;
        input integer i1, i2, i3, i4;
        begin
            synd[3:0] = i1;
            synd[7:4] = i2;
            synd[11:8] = i3;
            synd[15:12] = i4;
        end
    endtask

    task check;
        input integer i1, i2, i3, i4;
        begin
            prepare_synd(i1, i2, i3, i4);
            start = 1;
            #10;
            start = 0;
            #60;
            $write("%d %d %d", sigma_out[3:0], sigma_out[7:4], sigma_out[11:8]);
            $display("");
        end
    endtask

    initial begin
        clk = 0;
        rst = 0;
        start = 0;
        synd = 0;

        #13;
        rst = 1;
        #5;
        rst = 0;

        check(8,9,10,15);
        /*check(7,13,12,9);
        check(7,13,13,9);
        check(5,1,9,3);*/

        $finish;
    end
endmodule