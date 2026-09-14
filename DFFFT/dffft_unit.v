`include "../DFFFT/mux.v"
`include "../DFFFT/xor_tree.v"

module dffft_unit #(
    parameter N = 15, 
    parameter M = 4,

    parameter [7:0] J  = "1", 
    parameter [7:0] JP = "1"
) (
    input [N*N-1:0] c_in,
    output [M-1:0] out_val
);

    genvar i, j;
    reg [M-1:0] mem [0:N*N-1];

    localparam FILE_P = {"../DFFFT/dfft_", J, "_", JP, ".hex"};

    initial begin
        $readmemh(FILE_P, mem);
    end

    wire [N*N*M-1:0] out_comp;

    generate
        for(i = 0; i < N; i = i + 1) begin
            for(j = 0; j < N; j = j + 1) begin
                wire [M-1:0] mux_out;
                mux #(.M(M)) MUX_i(
                    .in1(mem[N*i + j]),
                    .in2(4'b0),
                    .sel(c_in[N*i + j]),
                    .out(mux_out)
                );
                assign out_comp[(N*i + j + 1) * M - 1 -: M] = mux_out;
            end
        end
    endgenerate

    xor_tree #(.M(M), .N(N*N)) XOR_TREE(
        .in(out_comp),
        .out(out_val)
    );
endmodule