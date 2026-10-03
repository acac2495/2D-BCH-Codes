`include "ccp_top.v"
`timescale 1ns/1ns

module ccp_tb;
    localparam N = 15;
    localparam M = 4;
    localparam T = 2;

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
    endtask

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, ccp_tb);
        
        clk = 0;
        rst = 0;
        start = 0;

        #13;
        rst = 1;
        #5;
        rst = 0;

        send_codeword(1);

        #40;

        send_codeword(2);

        #40;

        send_codeword(1);

        #40;
        
        send_codeword(2);

        #40;
        
        send_codeword(1);

        #40;
        start = 1;
        #10;
        start = 0;

        #300;
        $finish;
    end
endmodule