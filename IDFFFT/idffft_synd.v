`include "../IDFFFT/idffft_top.v"

module idffft_synd #(parameter COUNT_1 = 1, COUNT_2 = 4, COUNT_4 = 54, M = 4, N = 15) (classes, c_out);
    localparam TOTAL_CLASSES = COUNT_1 + COUNT_2 + COUNT_4;

    input [(TOTAL_CLASSES * M)-1:0] classes;
    output [N * N - 1 : 0] c_out;

    genvar i, ip;

    generate
        for(i = 0; i < N; i = i + 1) begin
            for(ip = 0; ip < N; ip = ip + 1) begin
                idffft_top #(.M(M), .COUNT_1(COUNT_1), .COUNT_2(COUNT_2), .COUNT_4(COUNT_4), .M(M), .I(i), .IP(ip)) IDFFFT_INST (
                    .classes(classes),
                    .c_out(c_out[N * i + ip])
                );
            end
        end
    endgenerate
endmodule