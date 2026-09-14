module sub_msg #(parameter M = 4, COUNT_1 = 1, COUNT_2 = 4, COUNT_4 = 43) (msg, classes);
    localparam TOTAL_CLASSES = COUNT_1 + COUNT_2 + COUNT_4;
    localparam MSG_WIDTH = 4 * COUNT_4 + 2 * COUNT_2 + 1 * COUNT_1;

    input [MSG_WIDTH - 1 : 0] msg;
    output reg [M * TOTAL_CLASSES - 1 : 0] classes;

    integer i, j, k, l;
    reg [3:0] mapped_val;

    always @(*) begin
        classes = 0;
        l = 0;
        mapped_val = 0;

        for(i = 0; i < COUNT_1; i = i + 1) begin
            classes [M * (l + 1) - 1 -: M] = msg[i];
            l = l + 1;
        end
        for(j = COUNT_1; j < COUNT_1 + 2 * COUNT_2; j = j + 2) begin
            case(msg[j + 1 -: 2])
                2'b00 : mapped_val = 4'b0000;
                2'b01 : mapped_val = 4'b0110;
                2'b10 : mapped_val = 4'b1000;
                2'b11 : mapped_val = 4'b1110;
            endcase
            classes [M * (l + 1) - 1 -: M] = mapped_val;
            l = l + 1;
        end
        for(k = COUNT_1 + 2 * COUNT_2; k < MSG_WIDTH; k = k + 4) begin
            classes [M * (l + 1) - 1 -: M] = msg[k + 3 -: 4];
            l = l + 1;
        end
    end
endmodule