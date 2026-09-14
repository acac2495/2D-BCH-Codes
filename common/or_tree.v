module or_tree #(parameter M = 4, N = 4) (in, out);
    input  [N*M-1:0] in;
    output [M-1:0]   out;

    genvar b, e;
    wire [N-1:0] lane [0:M-1];

    generate
        for (b = 0; b < M; b = b + 1) begin : BITLANE
            for (e = 0; e < N; e = e + 1) begin : GATHER
                assign lane[b][e] = in[e*M + b];
            end
            assign out[b] = |lane[b];   // built-in reduction-OR over N bits
        end
    endgenerate
endmodule