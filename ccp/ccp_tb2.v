`include "ccp_top.v"
`include "../encoder/encoder_top.v"
`timescale 1ns/1ns

module ccp_tb2;
    localparam N = 15;
    localparam M = 4;
    localparam T = 2;

    localparam COUNT_1 = 1;
    localparam COUNT_2 = 4;
    localparam COUNT_4 = 43;

    localparam TOTAL_CLASSES = COUNT_1 + COUNT_2 + COUNT_4;
    localparam MSG_WIDTH = 4 * COUNT_4 + 2 * COUNT_2 + 1 * COUNT_1;

    reg [MSG_WIDTH - 1 : 0] msg_mem [0:0];
    reg [MSG_WIDTH - 1 : 0] msg;

    always @(*) begin
        msg = msg_mem[0];
    end

    initial begin
        $readmemh("msg.hex", msg_mem);
    end

    wire [N*N - 1 : 0] code;

    encoder_top #(.N(N), .M(M), .COUNT_1(COUNT_1), .COUNT_2(COUNT_2), .COUNT_4(COUNT_4)) DUT1 (
        .msg(msg),
        .code(code)
    );

    reg [N*N-1:0] r_in;
    reg clk, rst;
    reg start;

    reg [N-1:0] codeword_mem [0:N-1];
    
    integer i, j;

    ccp_top #(.M(M), .N(N), .T(T)) DUT (
        .r_in(r_in),
        .clk(clk),
        .rst(rst),
        .start(start)
    );

    task send_codeword;
        input integer idx;
        integer i, j;
        reg [8*64-1:0] file_name; // 64-character buffer
        begin : send_codeword_block
            if(idx == 1 || idx == 2) begin
                $swrite(file_name, "codeword_%0d.hex", idx);
                $readmemh(file_name, codeword_mem);

                start = 1;
                r_in = 0;
                for(i = 0; i < N; i = i + 1) begin
                    for(j = 0; j < N; j = j + 1) begin
                        r_in[N*i + j] = codeword_mem[i][j];
                    end
                end
                #10;
                start = 0;
            end
            else begin
                start = 1;
                r_in = 0;

                r_in = code; // Directly assign the code output from encoder_top to r_in
                r_in[0] ^= 1'b1; // Flip the first bit to introduce an error
                r_in[1] ^= 1'b1; // Flip the second bit to introduce another error 
                r_in[N] ^= 1'b1; // Flip the first bit of the second row to introduce a third error
                r_in[N+1] ^= 1'b1; // Flip the second bit of the second row to introduce a fourth error
                #10;
                start = 0;
            end
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, ccp_tb2);
        
        clk = 0;
        rst = 0;
        start = 0;

        #13;
        rst = 1;
        #5;
        rst = 0;

        send_codeword(3);

        #50;

        send_codeword(1);

        #50;

        send_codeword(3);

        #50;
        
        send_codeword(1);

        #50;
        
        send_codeword(3);

        #50;
        start = 1;
        #10;
        start = 0;

        #300;
        $finish;
    end
endmodule