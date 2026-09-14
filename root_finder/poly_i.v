/*`include "../common/GF_2_4_mult.v"
`include "../common/xor_tree.v"*/

module poly_i #(parameter T = 2, M = 4, REF = 1) (c_in, out_bit);
    input [(T+1) * M - 1 : 0] c_in;
    output out_bit;

    genvar i;

    wire [M-1:0] out_val;
    wire [M-1:0] c [0:T];
    wire [M-1:0] out_comp [0:T];

    wire [(T+1) * M - 1 : 0] out_comp_flat;

    reg [M-1:0] coeffs [0:T];
    reg [8*32-1:0] file_name;
    
    initial begin
        $sformat(file_name, "../root_finder/poly_%0d.hex", REF);
        $readmemh(file_name, coeffs);
    end

    generate
        for(i = 0; i <= T; i = i + 1) begin
            assign c[i] = c_in[(i+1)*M - 1 -: M];
            GF_2_4_mult U_i(
                .in1(c[i]),
                .in2(coeffs[i]),
                .out(out_comp[i])
            );
            assign out_comp_flat[(i+1)*M - 1 -: M] = out_comp[i];
        end
    endgenerate

    xor_tree #(.N(T+1), .M(M)) XOR_ARRAY(
        .in(out_comp_flat),
        .out(out_val)
    );

    assign out_bit = ~(|out_val);
endmodule