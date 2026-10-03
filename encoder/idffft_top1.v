/*`include "../encoder/class_1.v"
`include "../encoder/class_2.v"
`include "../encoder/class_4.v"
`include "../encoder/xor_tree.v"*/

module idffft_top1 #(parameter COUNT_1 = 1, COUNT_2 = 4, COUNT_4 = 43, M = 4, I = 0, IP = 0) (classes, c_out);
    localparam TOTAL_CLASSES = COUNT_1 + COUNT_2 + COUNT_4;

    input [M * TOTAL_CLASSES - 1 : 0] classes;

    output c_out;

    reg [M-1:0] alpha_classes [0 : TOTAL_CLASSES - 1];
    reg [8*32-1:0] file_name;

    initial begin
        $sformat(file_name, "../encoder/alpha_%0d_%0d.hex", I, IP);
        $readmemh(file_name, alpha_classes);
    end

    genvar i, j, k;
    wire [TOTAL_CLASSES - 1 : 0] out_comp;

    generate
        for(i = 0; i < COUNT_1; i = i + 1) begin
            class_1 #(.M(M)) CLASS_1_INST (
                .p1(classes[M * (i + 1) - 1 -: M]),
                .p2(alpha_classes[i]),
                .c_out(out_comp[i])
            );
        end
        for(j = COUNT_1; j < COUNT_1 + COUNT_2; j = j + 1) begin
            class_2 #(.M(M)) CLASS_2_INST (
                .p1(classes[M * (j + 1) - 1 -: M]),
                .p2(alpha_classes[j]),
                .c_out(out_comp[j])
            );
        end
        for(k = COUNT_1 + COUNT_2; k < TOTAL_CLASSES; k = k + 1) begin
            class_4 #(.M(M)) CLASS_4_INST (
                .p1(classes[M * (k + 1) - 1 -: M]),
                .p2(alpha_classes[k]),
                .c_out(out_comp[k])
            );
        end
    endgenerate

    xor_tree #(.M(1), .N(TOTAL_CLASSES)) XOR_TREE (
        .in(out_comp),
        .out(c_out)
    );
endmodule