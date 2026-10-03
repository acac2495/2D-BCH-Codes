`include "../ccp/ccp_top.v"

module top #(parameter N = 15, M = 4, T = 2, DEPTH = 16) (clk, rst, start, done, corrected_res);

    input clk, rst, start;
    output done;
    output [N*N-1:0] corrected_res;

    reg [N*N-1:0] mem [0:DEPTH-1];
    initial begin
        $readmemh("codes.hex", mem);
    end

    localparam N_CYCLES = 6;
    reg [2:0] cycle_count;

    always @(posedge clk) begin
        if(rst) begin
            cycle_count <= N_CYCLES;
        end
        else if(mem_index == DEPTH) begin
            cycle_count <= N_CYCLES;
        end
        else if(start) begin
            cycle_count <= 0;
        end
        else begin
            if(cycle_count == (N_CYCLES - 1)) begin
                cycle_count <= 0;
            end
            else begin
                cycle_count <= cycle_count + 1;
            end
        end
    end

    reg decode_start;
    reg [$clog2(DEPTH):0] mem_index;

    always @(posedge clk) begin
        if(rst) begin
            decode_start <= 0;
            mem_index <= 0;
        end
        else begin
            if(cycle_count == 0) begin
                decode_start <= 1;
                mem_index <= mem_index + 1;
            end
            else begin
                decode_start <= 0;
            end
        end
    end

    wire [N*N-1:0] r_in;
    assign r_in = mem[mem_index];

    wire [N*N-1:0] c_out;

    ccp_top #(.M(M), .N(N), .T(T)) DUT (
        .r_in(r_in),
        .clk(clk),
        .rst(rst),
        .start(decode_start),
        .done(done),
        .corrected_res(corrected_res),
        .c_out(c_out)
    );

    /*always @(posedge clk) begin
        if(done) begin
            $display("Obtained error vector : ");
            for(p = 0; p < N; p = p + 1) begin
                for(q = 0; q < N; q = q + 1) begin
                    $write("%b ", c_out[N*p + q]);
                end
                $display("");
            end
            $display("Corrected result : ");
            for(p = 0; p < N; p = p + 1) begin
                for(q = 0; q < N; q = q + 1) begin
                    $write("%b ", corrected_res[N*p + q]);
                end
                $display("");
            end  
        end*/

endmodule