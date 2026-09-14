`timescale 1ns/1ns
`include "BM_top.v"

module BM_tb_2;
    localparam M = 4;
    localparam T = 2;
    localparam NUM_VECTORS = 105;

    reg clk, start, rst;
    reg [M-1:0] S_in;

    wire done;
    wire [(T+1) * M - 1 : 0] sigma_out;
    wire done_del;

    BM_top #(.M(M), .T(T)) DUT(
        .clk(clk),
        .start(start),
        .rst(rst),
        .S_in(S_in),
        .done(done),
        .sigma_out(sigma_out),
        .done_del(done_del)
    );

    always #5 clk = ~clk;

    reg [3:0] synd_mem [0:(NUM_VECTORS*2*T-1)];
    reg [3:0] poly_mem [0:(NUM_VECTORS*(T+1)-1)];

    
    initial begin
        $readmemh("synd_vectors_1.hex", synd_mem);
        $readmemh("expected_sigma_1.hex", poly_mem);
    end

    function [8*6-1:0] gf_str;
        input [M-1:0] val;
        begin
            case(val)
                4'b0000: gf_str = "0    ";
                4'b1000: gf_str = "a^0  ";
                4'b0100: gf_str = "a^1  ";
                4'b0010: gf_str = "a^2  ";
                4'b0001: gf_str = "a^3  ";
                4'b1100: gf_str = "a^4  ";
                4'b0110: gf_str = "a^5  ";
                4'b0011: gf_str = "a^6  ";
                4'b1101: gf_str = "a^7  ";
                4'b1010: gf_str = "a^8  ";
                4'b0101: gf_str = "a^9  ";
                4'b1110: gf_str = "a^10 ";
                4'b0111: gf_str = "a^11 ";
                4'b1111: gf_str = "a^12 ";
                4'b1011: gf_str = "a^13 ";
                4'b1001: gf_str = "a^14 ";
                default: gf_str = "??   ";
            endcase
        end
    endfunction

    
    task send_syndromes;
        input integer idx;
        integer j;
        begin
            start = 1;
            S_in = synd_mem[2*T*idx];
            #10;
            start = 0;
            for(j = 1; j < 2*T; j = j + 1) begin
                S_in = synd_mem[2*T*idx + j];
                #10;
            end
        end
    endtask

    integer i;

    task display_poly;
        input integer idx;
        integer j;
        begin
            $display("Case : %d", idx);
            $display("Obtained sigma : ");
            for(j = 0; j <= T; j = j + 1) begin
                $write("%s ", gf_str(sigma_out[(j+1)*M - 1 -: M]));
            end
            $display("");
            /*$display("Expected Sigma : ");
            for(j = 0; j <= T; j = j + 1) begin
                $write("%s ", gf_str(poly_mem[(T+1)*idx + j]));
            end
            $display(" ");*/
        end
    endtask

    task mismatch;
        input integer idx;
        integer j;
        integer mismatches;
        begin
            mismatches = 0;
            for(j = 0; j <= T; j = j + 1) begin
                if(sigma_out[(j+1)*M - 1 -: M] != poly_mem[(T+1)*idx + j]) begin
                    mismatches = mismatches + 1;
                end
            end
            $display("Case : %d, Mismatches : %d", idx, mismatches);
            if(mismatches != 0) begin
                $error("Mismatch detected at case : %d", idx);
                $fatal(1, "Simulation stopped due to output mismatch.");
            end
        end
    endtask

    task check_vectors;
        integer i;
        begin
            for(i = 0; i < NUM_VECTORS; i = i + 1) begin
                send_syndromes(i);
                #100;
                display_poly(i);
                mismatch(i);
                $display(" ");
            end
            $display("All Cases Passed, no mismatch");
        end
    endtask

    initial begin
        //$dumpfile("waveform.vcd");
        //$dumpvars(0, BM_tb);

        clk = 0;
        rst = 0;
        start = 0;
        S_in = 0;

        #13;
        rst = 1;
        #5;
        rst = 0;

        check_vectors();
        $finish;
    end
endmodule