module GF_2_4_mult(in1, in2, out);
    input [3:0] in1, in2;
    output [3:0] out;

    wire a0, a1, a2, a3;
    wire b0, b1, b2, b3;
    wire c0, c1, c2, c3;

    assign a0 = in1[3];
    assign a1 = in1[2];
    assign a2 = in1[1];
    assign a3 = in1[0];

    assign b0 = in2[3];
    assign b1 = in2[2];
    assign b2 = in2[1];
    assign b3 = in2[0];

    assign c0 = (a0 & b0) ^ (a1 & b3) ^ (a2 & b2) ^ (a3 & b1);
    assign c1 = (a0 & b1) ^ (a1 & b0) ^ (a1 & b3) ^ (a2 & b2) ^ (a2 & b3) ^ (a3 & b1) ^ (a3 & b2);
    assign c2 = (a0 & b2) ^ (a1 & b1) ^ (a2 & b0) ^ (a2 & b3) ^ (a3 & b2) ^ (a3 & b3);
    assign c3 = (a0 & b3) ^ (a1 & b2) ^ (a2 & b1) ^ (a3 & b0) ^ (a3 & b3);

    assign out = {c0, c1, c2, c3};
endmodule