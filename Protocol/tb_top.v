`include "top.v"

module tb_top;
    localparam N = 15;
    localparam M = 4;
    localparam T = 2;
    localparam DEPTH = 16;

    reg clk, rst, start;
    wire done;
    wire [N*N-1:0] corrected_res;

    top #(.N(N), .M(M), .T(T), .DEPTH(DEPTH)) DUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done),
        .corrected_res(corrected_res)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);
        
        clk = 0;
        rst = 0;
        start = 0;

        #13;
        rst = 1;
        #5;
        rst = 0;

        #10;
        start = 1;
        #10;
        start = 0;

        #400;
        $finish;
    end

endmodule