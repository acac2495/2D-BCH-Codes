/*`include "GF_2_4_mult.v"
`include "GF_2_4_inv.v"*/

// Combinational, num_found-aware coefficient reconstruction for T=2.
// Handles all three cases explicitly via a case-select mux, avoiding
// the multi-cycle latency of the general sequential roots_to_coeffs:
//   num_found=2: c(x) = (x+a1)(x+a2) normalized -> c1=(a1+a2)/(a1a2), c2=1/(a1a2)
//   num_found=1: c(x) = (x+a1) normalized        -> c1=1/a1,          c2=0
//   num_found=0: c(x) = 1 (trivial, no error)     -> c1=0,             c2=0
module root_to_coeff_comb #(parameter M = 4, T = 2) (roots, num_found, poly);
    input [$clog2(T+1)-1:0] num_found;
    input [M*T-1:0] roots;
    output [(T+1)*M-1:0] poly;

    wire  [M-1:0] a1, a2;
    wire [M-1:0] c1, c2;

    assign a1 = roots[M-1:0];
    assign a2 = roots[T*M-1:M];

    wire [M-1:0] sum, prod, prod_inv, sum_prod_inv;
    wire [M-1:0] a1_inv;

    assign sum = a1 ^ a2;

    GF_2_4_mult MULT_PROD (.in1(a1), .in2(a2), .out(prod));
    GF_2_4_inv  INV_PROD  (.in(prod), .out(prod_inv));
    GF_2_4_mult MULT_SUM  (.in1(sum), .in2(prod_inv), .out(sum_prod_inv));

    GF_2_4_inv  INV_A1    (.in(a1), .out(a1_inv));

    assign c1 = (num_found == 2) ? sum_prod_inv :
                (num_found == 1) ? a1_inv        : {M{1'b0}};
    assign c2 = (num_found == 2) ? prod_inv      : {M{1'b0}};

    assign poly = {c2, c1, 4'b1000};
endmodule