module root_lookup #(parameter N = 15, M = 4, T = 2) (rpos, roots, num_found);
    input [N-1:0] rpos;

    output [T*M-1:0] roots;
    output [$clog2(T+1)-1:0] num_found;
    
    integer idx;

    reg [M-1:0] roots_r [0:T-1];
    reg [$clog2(T+1)-1:0] count;

    function [3:0] alpha_pow;
        input integer idx;
        begin
            case(idx)
                0 : alpha_pow = 4'b1000;
                1 : alpha_pow = 4'b0100;
                2 : alpha_pow = 4'b0010;
                3 : alpha_pow = 4'b0001;
                4 : alpha_pow = 4'b1100;
                5 : alpha_pow = 4'b0110;
                6 : alpha_pow = 4'b0011;
                7 : alpha_pow = 4'b1101;
                8 : alpha_pow = 4'b1010;
                9 : alpha_pow = 4'b0101;
                10 : alpha_pow = 4'b1110;
                11 : alpha_pow = 4'b0111;
                12 : alpha_pow = 4'b1111;
                13 : alpha_pow = 4'b1011;
                14 : alpha_pow = 4'b1001;
            endcase
        end 
    endfunction

    always @(*) begin
        count = 0;
        for(idx = 0; idx < T; idx = idx + 1) begin
            roots_r[idx] = 0;
        end
        for (idx = 0; idx < N; idx = idx + 1) begin
            if (rpos[idx] && count < T) begin
                roots_r[count] = alpha_pow(idx);
                count = count + 1;
            end
        end
    end

    genvar g;
    generate
        for (g = 0; g < T; g = g + 1) begin : PACK
            assign roots[(g+1)*M-1 -: M] = roots_r[g];
        end
    endgenerate

    assign num_found = count;
endmodule