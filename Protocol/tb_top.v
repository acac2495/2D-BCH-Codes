`include "top.v"

module tb_top;
    localparam N = 15;
    localparam M = 4;
    localparam T = 2;
    localparam DEPTH = 1000;

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

    integer n_corrected, n_mismatched;
    initial begin
        n_corrected = 0;
        n_mismatched = 0;
    end

    initial begin
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

        #120000;
        $display("Mismatched : %0d" , n_mismatched);
        $finish;
    end

    always @(posedge clk) begin
        if(done) begin
            n_corrected <= n_corrected + 1;
            if(corrected_res != 0) begin
                $display("Mismatched at : %0d", n_corrected);
                n_mismatched = n_mismatched + 1;
            end
            else begin
                $display("Corrected at : %0d", n_corrected);
                $display("%h", corrected_res);
            end
        end
    end
endmodule