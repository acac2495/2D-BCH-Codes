`include "../common/GF_2_4_mult.v"
`include "../common/GF_2_4_inv.v"

module BM_top #(parameter T = 2, M = 4) (clk, rst, start, S_in, done, sigma_out, done_del, bm_busy);
    input clk, rst, start;
    input [M-1:0] S_in;
    
    output reg done, done_del, bm_busy;
    output reg [(T+1) * M - 1 : 0] sigma_out;

    //FSM States
    localparam IDLE = 0;
    localparam COMPUTE = 1;

    //FSM variables
    reg [1:0] state;
    reg [$clog2(2 * T) - 1 : 0] count;

    reg [M-1:0] temp_reg [0:T];     //Temporary Syndrome Register
    reg [M-1:0] sigma_reg [0:T];    //Polynomial Register
    reg [M-1:0] sigma_p [0:T];      //Past polynomial register

    wire [M-1:0] prod_reg [0:T];    //Register to hold individual discrepancy terms
    wire [M-1:0] sigma_bus [0:T];   //T+1 width bus Register
    wire [M-1:0] corr_term [0:T];   //Correction term register

    reg [M-1:0] d_mu;               //current discrepancy
    reg [M-1:0] d_p;                //past discrepancy

    reg load_sigma;                 //Internal loading decision variable (for mux)

    //iterator variables for multiple loops
    genvar j;
    integer i;

    //computation register for the discrepancy, instantiating all the multipliers
    generate
        for(j = 0; j <= T; j = j + 1) begin
            if(j == 0) begin
                assign prod_reg[j] = temp_reg[j];
            end
            else begin
                GF_2_4_mult U_j(
                    .in1(temp_reg[j]),
                    .in2(sigma_reg[j]),
                    .out(prod_reg[j])
                );
            end
        end
    endgenerate

    always @(*) begin
        sigma_out = 0;
        if(done) begin
            for(i = 0; i <= T; i = i + 1) begin
                sigma_out[(i+1)*M - 1 -: M] = sigma_reg[i];
            end
        end
    end
    
    //Discrepancy calculation
    always @(*) begin
        d_mu = 0;
        for(i = 0; i <= T; i = i + 1) begin
            d_mu = d_mu ^ prod_reg[i];
        end
    end

    //mux result based on load_sigma
    reg [M-1:0] sigma_store [0:T];
    always @(*) begin
        for(i = 0; i <= T; i = i + 1) begin
            sigma_store[i] = (load_sigma == 1) ? sigma_reg[i] : sigma_p[i];
        end
    end

    always @(*) begin
        load_sigma = (d_mu != 0);
    end

    wire [M-1:0] d_p_inv;       //stores inverse of d_p
    wire [M-1:0] dmu_dpinv;     //stores the product of d_mu and d_p inverse

    //inverter
    GF_2_4_inv U_inv(
        .in(d_p),
        .out(d_p_inv)
    );
    //multiplier
    GF_2_4_mult U_mul(
        .in1(d_mu),
        .in2(d_p_inv),
        .out(dmu_dpinv)
    );

    //correction term computation logic
    generate
        for(j = 0; j <= T; j = j + 1) begin
            GF_2_4_mult U_corr(
                .in1(sigma_p[j]),
                .in2(dmu_dpinv),
                .out(corr_term[j])
            );
            assign sigma_bus[j] = sigma_reg[j] ^ corr_term[j];
        end
    endgenerate

    always @(posedge clk) begin
        if(rst) begin
            done_del <= 0;
        end
        else begin
            done_del <= done;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i <= T; i = i + 1) begin     //zero initialising all sequentially dependent terms
                temp_reg[i] <= 0;
                sigma_reg[i] <= 0;
                sigma_p[i] <= 0;
            end
            state <= IDLE;                          //initial state
            count <= 0;                             //initial count
            d_p <= 4'b1000;
            done <= 0;
            bm_busy <= 0;
        end
        else begin
            case(state)
                IDLE : begin
                    if(start) begin
                        state <= COMPUTE;
                        temp_reg[0] <= S_in;                    //take initial S_1
                        sigma_reg[0] <= {1'b1, {(M-1){1'b0}}};  //start with initial polynomial as 1
                        for(i = 1; i <= T; i = i + 1) begin     //zeroing in the rest of the locations
                            temp_reg[i]  <= 0;
                            sigma_reg[i] <= 0;
                        end
                        for(i = 1; i <= T; i = i + 1) begin
                            if(i == 1) begin
                                sigma_p[i] <= {1'b1, {(M-1){1'b0}}};
                            end
                            else begin
                                sigma_p[i] <= 0;
                            end
                        end
                        d_p <= 4'b1000;
                        bm_busy <= 1;
                    end
                    count <= 0;
                    done <= 0;
                end
                COMPUTE : begin
                    if(count == (2 * T - 1)) begin
                        state <= IDLE;
                        done <= 1;
                    end
                    if(count == (2 * T - 2)) begin
                        bm_busy <= 0;
                    end
                    for(i = 0; i <= T; i = i + 1) begin
                        if(i == 0) begin
                            temp_reg[i] <= S_in;                //shifting in the new syndrome
                            sigma_p[i] <= 0;                    //unsure
                        end
                        else begin
                            temp_reg[i] <= temp_reg[i-1];       //right shifting the syndromes
                            sigma_p[i] <= sigma_store[i-1];     //shift by 1 implementation
                        end
                        sigma_reg[i] <= sigma_bus[i];           //storing in the t+1 data bus, as in the paper
                        if(load_sigma) begin
                            d_p <= d_mu;
                        end
                    end
                    count <= count + 1;
                end
            endcase
        end
    end

    
    //galois field mapping
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

    //printing task
    
    integer p;
    /*always @(posedge clk) begin
        if (~rst && done) begin
            $display("---- time=%0t  state=%0d  count=%0d  load_sigma=%b ----",
                      $time, state, count, load_sigma);
            $display("S_in    = %s", gf_str(S_in));
            $display("d_mu    = %s", gf_str(d_mu));
            $display("d_p     = %s", gf_str(d_p));

            $write("temp_reg  = ");
            for (p = 0; p <= T; p = p + 1)
                $write("%s ", gf_str(temp_reg[p]));
            $display("");

            for (p = 0; p <= T; p = p + 1)
                $write("%s ", gf_str(sigma_reg[p]));
            $display("");

            $write("sigma_p   = ");
            for (p = 0; p <= T; p = p + 1)
                $write("%s ", gf_str(sigma_p[p]));
            $display("");
            $display("");
        end
    end*/
endmodule