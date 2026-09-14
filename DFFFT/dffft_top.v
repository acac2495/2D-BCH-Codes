`include "../DFFFT/dffft_unit.v"

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

endmodule