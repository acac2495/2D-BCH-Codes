/*`include "../common/GF_2_4_inv.v"
`include "../common/GF_2_4_mult.v"*/

module root_to_coeff_t2 #(parameter M = 4) (a1, a2, c1, c2);
    input [M-1:0] a1, a2;
    output [M-1:0] c1, c2;

    wire [M-1:0] sum;
    wire [M-1:0] prod, prod_inv;
    wire [M-1:0] sum_prod_inv;

    assign sum = a1 ^ a2;

    GF_2_4_mult MULT_INST_1 (
        .in1(a1),
        .in2(a2),
        .out(prod)
    );

    GF_2_4_inv INV_INST (
        .in(prod),
        .out(prod_inv)
    );

    GF_2_4_mult MULT_INST_2 (
        .in1(sum),
        .in2(prod_inv),
        .out(sum_prod_inv)
    );

    assign c2 = prod_inv;
    assign c1 = sum_prod_inv;
endmodule