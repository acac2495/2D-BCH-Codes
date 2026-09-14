/*`include "../common/GF_2_4_mult.v"
`include "../common/xor_tree.v"*/

module RE_base #(parameter T = 2, M = 4) (c_in, S_in, S_out);
    input [T*M-1:0] c_in;
    input [T*M-1:0] S_in;
    output [M-1:0] S_out;

    genvar i;

    wire [T*M-1:0] comp_out;

    generate
        for(i = 0; i < T; i = i + 1) begin
            GF_2_4_mult MULT_INST (
                .in1(c_in[(i+1)*M-1-:M]),
                .in2(S_in[(T-i)*M-1-:M]),
                .out(comp_out[(i+1)*M-1-:M])
            );
        end
    endgenerate

    xor_tree #(.M(M), .N(T)) XOR_ARRAY (
        .in(comp_out),
        .out(S_out)
    );
endmodule