module class_4 #(parameter M = 4) (p1, p2, c_out);
    input [M-1:0] p1, p2;
    output c_out;

    wire a0, a1, a2, a3;
    wire b0, b1, b2, b3;

    assign a0 = p1[3];
    assign a1 = p1[2];
    assign a2 = p1[1];
    assign a3 = p1[0];

    assign b0 = p2[3];
    assign b1 = p2[2];
    assign b2 = p2[1];
    assign b3 = p2[0];

    assign c_out = (a0 & b3) ^ (a1 & b2) ^ (a2 & b1) ^ (a3 & b0) ^ (a3 & b3);
endmodule