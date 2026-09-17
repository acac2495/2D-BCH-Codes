/*`include "../DFFFT/dffft_unit.v"

module dffft_top #(parameter M = 4, T = 2, N = 15) (c_in, C_out);
    input  [N*N-1:0] c_in;
    output [(2*T)*(2*T)*M-1:0] C_out;

    genvar J, Jp;
    generate
        for (J = 1; J <= 2*T; J = J + 1) begin : ROW
            for (Jp = 1; Jp <= 2*T; Jp = Jp + 1) begin : COL
                localparam integer FLAT_IDX = (J-1)*(2*T) + (Jp-1);
                dffft_unit #(.M(M), .N(N), .J(8'd48 + J), .JP(8'd48 + Jp)) U (
                    .c_in(c_in),
                    .out_val(C_out[(FLAT_IDX+1)*M-1 -: M])
                );
            end
        end
    endgenerate

endmodule*/

`include "../DFFFT/dffft_unit.v"
`include "../common/gf16_square.v"

module dffft_top #(parameter M = 4, T = 2, N = 15) (
    input  [N*N-1:0] c_in,
    output [(2*T)*(2*T)*M-1:0] C_out
);
    wire [M-1:0] rep_val [0:10];


    // Derived conjugate elements via Frobenius Squaring
    wire [M-1:0] sq_2_2, sq_2_4, sq_4_1_a, sq_4_1_b, sq_4_2, sq_4_4;

    // Compute representatives using 1-based J, JP indices directly (1 to 4)
    dffft_unit #(.M(M), .N(N), .J(8'd48+1), .JP(8'd48+1)) U0  (.c_in(c_in), .out_val(rep_val[0]));  // (1,1)
    dffft_unit #(.M(M), .N(N), .J(8'd48+1), .JP(8'd48+2)) U1  (.c_in(c_in), .out_val(rep_val[1]));  // (1,2)
    dffft_unit #(.M(M), .N(N), .J(8'd48+1), .JP(8'd48+3)) U2  (.c_in(c_in), .out_val(rep_val[2]));  // (1,3)
    dffft_unit #(.M(M), .N(N), .J(8'd48+1), .JP(8'd48+4)) U3  (.c_in(c_in), .out_val(rep_val[3]));  // (1,4)
    dffft_unit #(.M(M), .N(N), .J(8'd48+2), .JP(8'd48+1)) U4  (.c_in(c_in), .out_val(rep_val[4]));  // (2,1)
    dffft_unit #(.M(M), .N(N), .J(8'd48+2), .JP(8'd48+3)) U5  (.c_in(c_in), .out_val(rep_val[5]));  // (2,3)
    dffft_unit #(.M(M), .N(N), .J(8'd48+3), .JP(8'd48+1)) U6  (.c_in(c_in), .out_val(rep_val[6]));  // (3,1)
    dffft_unit #(.M(M), .N(N), .J(8'd48+3), .JP(8'd48+2)) U7  (.c_in(c_in), .out_val(rep_val[7]));  // (3,2)
    dffft_unit #(.M(M), .N(N), .J(8'd48+3), .JP(8'd48+3)) U8  (.c_in(c_in), .out_val(rep_val[8]));  // (3,3)
    dffft_unit #(.M(M), .N(N), .J(8'd48+3), .JP(8'd48+4)) U9  (.c_in(c_in), .out_val(rep_val[9]));  // (3,4)
    dffft_unit #(.M(M), .N(N), .J(8'd48+4), .JP(8'd48+3)) U10 (.c_in(c_in), .out_val(rep_val[10])); // (4,3)

    gf16_square #(.M(M)) SQ0 (.in(rep_val[0]), .out(sq_2_2));  // (1,1)^2 -> (2,2)
    gf16_square #(.M(M)) SQ1 (.in(rep_val[1]), .out(sq_2_4));  // (1,2)^2 -> (2,4)
    gf16_square #(.M(M)) SQ2 (.in(rep_val[3]), .out(sq_4_1_a));  // (1,4)^2 -> (4,1)
    gf16_square #(.M(M)) SQ2b (.in(sq_4_1_a), .out(sq_4_1_b));  // (4,1)^2 -> (4,1) (double squaring to ensure correctness)
    gf16_square #(.M(M)) SQ3 (.in(rep_val[4]), .out(sq_4_2));  // (2,1)^2 -> (4,2)
    gf16_square #(.M(M)) SQ4 (.in(sq_2_2),     .out(sq_4_4));  // (2,2)^2 -> (4,4)

    // Exact bit-packing formula matching FLAT_IDX = (J-1)*4 + (Jp-1)
    assign C_out[ 1*M-1 -: M] = rep_val[0];  // (1,1) -> FLAT_IDX 0
    assign C_out[ 2*M-1 -: M] = rep_val[1];  // (1,2) -> FLAT_IDX 1
    assign C_out[ 3*M-1 -: M] = rep_val[2];  // (1,3) -> FLAT_IDX 2
    assign C_out[ 4*M-1 -: M] = rep_val[3];  // (1,4) -> FLAT_IDX 3

    assign C_out[ 5*M-1 -: M] = rep_val[4];  // (2,1) -> FLAT_IDX 4
    assign C_out[ 6*M-1 -: M] = sq_2_2;      // (2,2) -> FLAT_IDX 5
    assign C_out[ 7*M-1 -: M] = rep_val[5];  // (2,3) -> FLAT_IDX 6
    assign C_out[ 8*M-1 -: M] = sq_2_4;      // (2,4) -> FLAT_IDX 7

    assign C_out[ 9*M-1 -: M] = rep_val[6];  // (3,1) -> FLAT_IDX 8
    assign C_out[10*M-1 -: M] = rep_val[7];  // (3,2) -> FLAT_IDX 9
    assign C_out[11*M-1 -: M] = rep_val[8];  // (3,3) -> FLAT_IDX 10
    assign C_out[12*M-1 -: M] = rep_val[9];  // (3,4) -> FLAT_IDX 11

    assign C_out[13*M-1 -: M] = sq_4_1_b;    // (4,1) -> FLAT_IDX 12
    assign C_out[14*M-1 -: M] = sq_4_2;      // (4,2) -> FLAT_IDX 13
    assign C_out[15*M-1 -: M] = rep_val[10]; // (4,3) -> FLAT_IDX 14
    assign C_out[16*M-1 -: M] = sq_4_4;      // (4,4) -> FLAT_IDX 15
endmodule