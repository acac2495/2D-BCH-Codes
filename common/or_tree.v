module or_tree #(parameter M = 4, N = 4) (in, out);
    input [N*M - 1 : 0] in;
    output [M-1:0] out;

    generate
        if(N==1) begin
            assign out = in[M-1:0];
        end
        else begin
            localparam NL = N/2;
            localparam NR = N-NL;

            wire [M-1:0] left, right;

            or_tree #(.N(NL), .M(M)) U_left (
                .in  (in[NL*M-1:0]),
                .out (left)
            );
            or_tree #(.N(NR), .M(M)) U_right (
                .in  (in[N*M-1:NL*M]),
                .out (right)
            );
            assign out = left | right;
         end
    endgenerate
endmodule