`include "../encoder/idffft_top1.v"
`include "../encoder/sub_msg.v"

module encoder_top #(parameter M = 4, COUNT_1 = 1, COUNT_2 = 4, COUNT_4 = 43, N = 15) (msg, code);
    localparam TOTAL_CLASSES = COUNT_1 + COUNT_2 + COUNT_4;
    localparam MSG_WIDTH = 4 * COUNT_4 + 2 * COUNT_2 + 1 * COUNT_1;

    input [MSG_WIDTH - 1 : 0] msg;
    output [N * N - 1 : 0] code;

    wire [M * TOTAL_CLASSES - 1 : 0] classes;

    sub_msg #(.M(M), .COUNT_1(COUNT_1), .COUNT_2(COUNT_2), .COUNT_4(COUNT_4)) SUB_MSG_INST (
        .msg(msg),
        .classes(classes)
    );

    genvar i, ip;

    generate
        for(i = 0; i < N; i = i + 1) begin
            for(ip = 0; ip < N; ip = ip + 1) begin
                idffft_top1 #(.M(M), .COUNT_1(COUNT_1), .COUNT_2(COUNT_2), .COUNT_4(COUNT_4), .M(M), .I(i), .IP(ip)) IDFFFT_INST (
                    .classes(classes),
                    .c_out(code[N * i + ip])
                );
            end
        end
    endgenerate
endmodule