/*`include "../common/GF_2_4_mult.v"
`include "../common/GF_2_4_inv.v"*/

module roots_to_coeffs #(parameter T = 2, M = 4) (
    input clk, rst, start,
    input [T*M-1:0] roots,
    input [$clog2(T+1)-1:0] num_found,
    output [(T+1)*M-1:0] coeffs_out,
    output reg done
);

    localparam IDLE = 0, ITER = 1, NORMALIZE = 2;
    reg [1:0] state;
    reg [$clog2(T+1)-1:0] k;   // iteration counter, 0..T-1 (root index being processed)

    integer m;
    reg [M-1:0] poly [0:T];    // poly[0]=constant term ... poly[T]=leading term

    wire [M-1:0] cur_root = roots[(k+1)*M-1 -: M];
    wire active = (k < num_found);

    // combinational: candidate next poly, multiplying current poly by (x + cur_root)
    wire [M-1:0] mult_term [0:T];
    wire [M-1:0] next_poly [0:T];

    genvar g;
    generate
        for (g = 0; g <= T; g = g + 1) begin : UPDATE
            GF_2_4_mult U_m (
                .in1(cur_root),
                .in2(poly[g]),
                .out(mult_term[g])
            );
            if (g == 0)
                assign next_poly[g] = mult_term[g];              // poly[-1] treated as 0
            else
                assign next_poly[g] = poly[g-1] ^ mult_term[g];
        end
    endgenerate

    // normalization: divide every coefficient by the constant term poly[0]
    wire [M-1:0] inv_const;
    GF_2_4_inv U_inv (.in(poly[0]), .out(inv_const));

    wire [M-1:0] norm_term [0:T];
    generate
        for (g = 0; g <= T; g = g + 1) begin : NORM
            GF_2_4_mult U_n (
                .in1(poly[g]),
                .in2(inv_const),
                .out(norm_term[g])
            );
        end
    endgenerate

    wire [(T+1)*M-1:0] coeffs_flat;
    generate
        for (g = 0; g <= T; g = g + 1) begin : PACK
            assign coeffs_flat[(g+1)*M-1 -: M] = poly[g];
        end
    endgenerate
    assign coeffs_out = coeffs_flat;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            done  <= 0;
            k     <= 0;
            for (m = 0; m <= T; m = m + 1)
                poly[m] <= (m == 0) ? {1'b1, {(M-1){1'b0}}} : 0;   // poly = [1,0,0,...] (constant 1)
        end
        else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= ITER;
                        k <= 0;
                        for (m = 0; m <= T; m = m + 1)
                            poly[m] <= (m == 0) ? {1'b1, {(M-1){1'b0}}} : 0;
                    end
                end
                ITER: begin
                    if (active) begin
                        for (m = 0; m <= T; m = m + 1)
                            poly[m] <= next_poly[m];
                    end
                    if (k == T-1)
                        state <= NORMALIZE;
                    k <= k + 1;
                end
                NORMALIZE: begin
                    for (m = 0; m <= T; m = m + 1)
                        poly[m] <= norm_term[m];
                    state <= IDLE;
                    done  <= 1;
                end
            endcase
        end
    end

endmodule