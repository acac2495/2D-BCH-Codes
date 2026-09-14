`include "encoder_top.v"
`timescale 1ns/1ns

module encoder_tb;
    localparam M = 4;
    localparam COUNT_1 = 1;
    localparam COUNT_2 = 4;
    localparam COUNT_4 = 43;
    localparam N = 15;

    localparam TOTAL_CLASSES = COUNT_1 + COUNT_2 + COUNT_4;
    localparam MSG_WIDTH = 4 * COUNT_4 + 2 * COUNT_2 + 1 * COUNT_1;

    reg [MSG_WIDTH - 1 : 0] msg;
    reg [N*N - 1 : 0] check_code;
    wire [N * N - 1 : 0] code;

    reg [MSG_WIDTH - 1 : 0] msg_mem [0:0];
    reg [N*N - 1 : 0] code_mem [0:0];

    always @(*) begin
        msg = msg_mem[0];
        check_code = code_mem[0];
    end

    encoder_top #(.N(N), .M(M), .COUNT_1(COUNT_1), .COUNT_2(COUNT_2), .COUNT_4(COUNT_4)) DUT (
        .msg(msg),
        .code(code)
    );

    initial begin
        $readmemh("msg.hex", msg_mem);
        $readmemh("code.hex", code_mem);
    end

    integer i, j, mismatches;

    initial begin
        mismatches = 0;
        #20;
        $display("%b", msg);
        for(i = 0; i < N; i = i + 1) begin
            for(j = 0; j < N; j = j + 1) begin
                $write("%b ", code[N*i + j]);
            end
            $display("");
        end
        #20;
        for(i = 0; i < N; i = i + 1) begin
            for(j = 0; j < N; j = j + 1) begin
                if(code[N*i + j] != check_code[N*i + j]) begin
                    mismatches += 1;
                end
            end
        end
        $display("Number of mismatches : %d", mismatches);
        $finish;
    end
endmodule