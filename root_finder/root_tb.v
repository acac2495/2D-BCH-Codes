`timescale 1ns/1ns
`include "root_top.v"

module root_tb;
    localparam T = 2;
    localparam M = 4;
    localparam N = 15;

    reg [11 : 0] c_in;
    wire [14 : 0] rpos;

    root_top #(.T(T), .M(M), .N(N)) DUT(
        .c_in(c_in),
        .rpos(rpos)
    );

    initial begin
        c_in[3:0] = 4'b1000;
        c_in[7:4] = 4'b0110;
        c_in[11:8] = 4'b0001;

        #20;

        $display("%b", rpos);
    end
endmodule