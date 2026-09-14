`timescale 1ns/1ns
`include "dffft_top.v"

module dffft_tb;
    localparam N = 15;
    localparam T = 2;
    localparam M = 4;

    reg [N-1:0] codeword_mem [0:N-1];
    integer i, j;
    initial begin
        $readmemh("../DFFFT/codeword.hex", codeword_mem);
        for(i = 0; i < N; i = i + 1) begin
            $display("%b", codeword_mem[i]);
        end
    end

    reg [N*N - 1 : 0] c_in;
    wire [(2*T)*(2*T)*M-1:0] C_out;

    always @(*) begin
        c_in = 0;
        for(i = 0; i < N; i = i + 1) begin
            for(j = 0; j < N; j = j + 1) begin
                c_in[N*i + j] = codeword_mem[i][j];
            end
        end
    end

    wire [2*T*M-1:0] col_synd [0:T-1];

    genvar j1, k;

    generate
        for (j1 = 0; j1 < T; j1 = j1 + 1) begin : COL_GATHER
            for (k = 1; k <= 2*T; k = k + 1) begin : STACK
                // flat index of (J=k, Jp=rep_idx(j)) in row-major C_out
                assign col_synd[j1][M*k-1 -: M] =
                    C_out[ ((k-1)*2*T + (rep_idx(j1)-1) + 1) * M - 1 -: M ];
            end
        end
    endgenerate

    dffft_top #(.N(N), .M(M), .T(T)) DUT(
        .c_in(c_in),
        .C_out(C_out)
    ); 

    function [8*6-1:0] gf_str;
        input [M-1:0] val;
        begin
            case(val)
                4'b0000: gf_str = "0    ";
                4'b1000: gf_str = "a^0  ";
                4'b0100: gf_str = "a^1  ";
                4'b0010: gf_str = "a^2  ";
                4'b0001: gf_str = "a^3  ";
                4'b1100: gf_str = "a^4  ";
                4'b0110: gf_str = "a^5  ";
                4'b0011: gf_str = "a^6  ";
                4'b1101: gf_str = "a^7  ";
                4'b1010: gf_str = "a^8  ";
                4'b0101: gf_str = "a^9  ";
                4'b1110: gf_str = "a^10 ";
                4'b0111: gf_str = "a^11 ";
                4'b1111: gf_str = "a^12 ";
                4'b1011: gf_str = "a^13 ";
                4'b1001: gf_str = "a^14 ";
                default: gf_str = "??   ";
            endcase
        end
    endfunction

    function integer rep_idx;
        input integer r;
        begin
            case(r)
                0 : rep_idx = 1;
                1 : rep_idx = 3;
                2 : rep_idx = 5;
                default : rep_idx = 0;
            endcase
        end 
    endfunction

    initial begin
        #20;
        for (i = 1; i <= 2*T; i = i + 1) begin
            for (j = 1; j <= 2*T; j = j + 1) begin
                $write("%s ", gf_str(C_out[((i-1)*(2*T) + (j-1)+1)*M-1 -: M]));
            end
            $display("");
        end
        $display(" ");
        #20;
        for(j = 0; j < T; j = j + 1) begin
            for(i = 1; i <= 2*T; i = i + 1) begin
                $write("%s ", gf_str(col_synd[j][M*i-1 -: M]));
            end
            $display("");
        end
        $finish;
    end
endmodule