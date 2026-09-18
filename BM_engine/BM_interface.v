`include "../BM_engine/BM_top.v"

module BM_interface #(parameter T = 2, M = 4) (clk, rst, synd, done, sigma_out, start, bm_busy);
    input clk, rst, start;
    input [2*T*M-1:0] synd;

    output done;
    output [(T+1)*M-1:0] sigma_out;
    output bm_busy;

    localparam IDLE = 0;
    localparam SENDING = 1;
    reg [1:0] state;
    
    reg [M-1:0] S_in;
    reg BM_start;
    reg [$clog2(2*T)-1:0] count;

    always @(posedge clk) begin
        if(rst) begin
            count <= 0;
            state <= IDLE;
            BM_start <= 0;
            S_in <= 0;
        end
        else begin
            case(state)
                IDLE : begin
                    if(start) begin
                        state <= SENDING;
                        BM_start <= 1;
                        S_in <= synd[M * (count + 1) - 1 -: M];
                        count <= 1;
                    end
                    else begin
                        BM_start <= 0;
                        S_in <= 0;
                        count <= 0;
                    end
                end
                SENDING : begin
                    if(count == (2 * T - 1)) begin
                        state <= IDLE;
                    end
                    count <= count + 1;
                    S_in <= synd[M * (count + 1) - 1 -: M];
                    BM_start <= 0;
                end
            endcase
        end
    end

    BM_top #(.M(M), .T(T)) BM_INST(
        .clk(clk),
        .rst(rst),
        .S_in(S_in),
        .start(BM_start),
        .done(done),
        .sigma_out(sigma_out),
        .bm_busy(bm_busy)
    );
endmodule