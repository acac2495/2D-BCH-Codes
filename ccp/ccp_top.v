`include "../DFFFT/dffft_top.v"
`include "../BM_engine/BM_interface.v"
`include "../root_finder/root_top.v"
`include "../common/or_tree.v"
`include "../root_finder/root_lookup.v"
`include "../common/roots_to_coeffs.v"
`include "../recursive_extension/RE_chain.v"
`include "../common/root_to_coeff_comb.v"
`include "../IDFFFT/idffft_synd.v"

module ccp_top #(parameter T = 2, M = 4, N = 15) (clk, rst, r_in, start, done);
    input [N*N-1:0] r_in;
    input clk, rst;
    input start;

    //output reg done;
    output done;

    integer f;

    wire ready;
    reg [N*N-1:0] r_in_captured, r_in_captured1;

    wire [(2*T)*(2*T)*M-1:0] S_2t;

    reg [(2*T)*(2*T)*M-1:0] S_2t_reg, S_2t_reg1;
    reg start_row, start_col;

    always @(posedge clk) begin
        if(rst) begin
            r_in_captured <= 0;
            r_in_captured1 <= 0;
            S_2t_reg <= 0;
            S_2t_reg1 <= 0;
        end
        else if(start && ready) begin
            r_in_captured <= r_in;
            r_in_captured1 <= r_in_captured;
            S_2t_reg <= S_2t;
            S_2t_reg1 <= S_2t_reg;
        end
    end
    
    function integer rep_idx;
        input integer r;
        begin
            case(r)
                0 : rep_idx = 1;
                1 : rep_idx = 3;
                2 : rep_idx = 5;
                default : rep_idx = 0;
            endcase
        end 
    endfunction

    dffft_top #(.M(M), .T(T), .N(N)) DFFFT_INST (
        .c_in(r_in),
        .C_out(S_2t)
    );

    //row wise BM engines
    genvar i;

    wire [(T+1)*M-1:0] row_sigma_arr [0:T-1];
    wire [T-1:0] row_done;
    wire row_done_flag;

    assign row_done_flag = |row_done;

    wire [T-1:0] bm_busy_row;
    wire [T-1:0] bm_busy_col;

    wire row_busy, col_busy;
    assign row_busy = |bm_busy_row;
    assign col_busy = |bm_busy_col;

    assign ready = ~(start_row | start_col | row_busy | col_busy);

    generate
        for(i = 0; i < T; i = i + 1) begin
            BM_interface #(.M(M), .T(T)) BM_INST_ROW (
                .clk(clk),
                .rst(rst),
                .start(start_row),
                .synd(S_2t_reg[rep_idx(i)*2*T*M-1-:2*T*M]),
                .sigma_out(row_sigma_arr[i]),
                .done(row_done[i]),
                .bm_busy(bm_busy_row[i])
            );
        end
    endgenerate

    //col wise BM engines
    genvar j, k;

    wire [(T+1)*M-1:0] col_sigma_arr [0:T-1];
    wire [T-1:0] col_done;
    wire col_done_flag;

    assign col_done_flag = |col_done;

    wire [2*T*M-1:0] col_synd_2t_conjug [0:T-1];    //getting just the conjugate IP columns from 1-2t

    generate
        for (j = 0; j < T; j = j + 1) begin : COL_GATHER
            for (k = 1; k <= 2*T; k = k + 1) begin : STACK
                assign col_synd_2t_conjug[j][M*k-1 -: M] =
                    S_2t_reg[ ((k-1)*2*T + (rep_idx(j)-1) + 1) * M - 1 -: M ];
            end
        end
    endgenerate

    wire [2*T*M-1:0] col_synd_int [0:2*T-1];        //getting all the columns from 1-2t

    generate
        for (j = 1; j <= 2*T; j = j + 1) begin : FULL_COL_GATHER
            for (k = 1; k <= 2*T; k = k + 1) begin : STACK
                assign col_synd_int[j-1][M*k-1 -: M] =
                    S_2t_reg1[ ((k-1)*2*T + (j-1) + 1) * M - 1 -: M ];
            end
        end
    endgenerate

    generate
        for (j = 0; j < T; j = j + 1) begin : COL_BM
            BM_interface #(.M(M), .T(T)) BM_INST_COL (
                .clk(clk),
                .rst(rst),
                .start(start_col),
                .synd(col_synd_2t_conjug[j]),
                .sigma_out(col_sigma_arr[j]),
                .done(col_done[j]),
                .bm_busy(bm_busy_col[j])
            );
        end
    endgenerate

    reg [(T+1)*M-1:0] col_sigma_arr_reg [0:T-1];
    reg [(T+1)*M-1:0] row_sigma_arr_reg [0:T-1];

    //reg [(T+1)*M*T-1:0] col_sigma_arr_flat, row_sigma_arr_flat;

    reg col_done_flag_reg;
    reg row_done_flag_reg;

    always @(posedge clk) begin
        if(rst) begin
            start_col <= 0;
            start_row <= 0;
            row_done_flag_reg <= 0;
            col_done_flag_reg <= 0;
        end
        else begin
            start_row <= start && ready;
            start_col <= start && ready;
            row_done_flag_reg <= row_done_flag;
            col_done_flag_reg <= col_done_flag;
        end
    end

    integer ip;

    always @(posedge clk) begin
        if(rst) begin
            for(ip = 0; ip < T; ip = ip + 1) begin
                col_sigma_arr_reg[ip] <= 0;
                row_sigma_arr_reg[ip] <= 0;
            end
            //col_sigma_arr_flat <= 0;
            //row_sigma_arr_flat <= 0;
        end
        else begin
            for(ip = 0; ip < T; ip = ip + 1) begin
                col_sigma_arr_reg[ip] <= col_sigma_arr[ip];
                row_sigma_arr_reg[ip] <= row_sigma_arr[ip];
                //col_sigma_arr_flat[(ip+1)*(T+1)*M-1 -: (T+1)*M] <= col_sigma_arr[ip];
                //row_sigma_arr_flat[(ip+1)*(T+1)*M-1 -: (T+1)*M] <= row_sigma_arr[ip];
            end
        end
    end

    wire [T*N-1:0] col_rpos;
    wire [T*N-1:0] row_rpos;

    generate
        for(i = 0; i < T; i = i + 1) begin
            root_top #(.T(T), .M(M), .N(N)) ROOT_FINDER_COL_INST (
                .c_in(col_sigma_arr_reg[i]),
                .rpos(col_rpos[(i+1)*N-1 -: N])
            );
        end
    endgenerate

    generate
        for(i = 0; i < T; i = i + 1) begin
            root_top #(.T(T), .M(M), .N(N)) ROOT_FINDER_ROW_INST (
                .c_in(row_sigma_arr_reg[i]),
                .rpos(row_rpos[(i+1)*N-1 -: N])
            );
        end
    endgenerate

    wire [N-1:0] col_rpos_lcm;
    wire [N-1:0] row_rpos_lcm;

    or_tree #(.M(N), .N(T)) COL_OR_TREE_INST (
        .in(col_rpos),
        .out(col_rpos_lcm)
    );
    or_tree #(.M(N), .N(T)) ROW_OR_TREE_INST (
        .in(row_rpos),
        .out(row_rpos_lcm)
    );

    wire [T*M - 1 : 0] roots_col;
    wire [T*M - 1 : 0] roots_row;

    wire [$clog2(T+1)-1:0] col_num_found;
    wire [$clog2(T+1)-1:0] row_num_found;

    root_lookup #(.M(M), .T(T), .N(N)) COL_LOOKUP_INST (
        .rpos(col_rpos_lcm),
        .roots(roots_col),
        .num_found(col_num_found)
    );

    root_lookup #(.M(M), .T(T), .N(N)) ROW_LOOKUP_INST (
        .rpos(row_rpos_lcm),
        .roots(roots_row),
        .num_found(row_num_found)
    );

    wire [(T+1)*M-1:0] col_ccp;
    wire [(T+1)*M-1:0] row_ccp;
    
    root_to_coeff_comb #(.T(T), .M(M)) COL_ROOTS_TO_COEFFS (
        .num_found(col_num_found),
        .roots(roots_col),
        .poly(col_ccp)
    );

    root_to_coeff_comb #(.T(T), .M(M)) ROW_ROOTS_TO_COEFFS (
        .num_found(row_num_found),
        .roots(roots_row),
        .poly(row_ccp)
    );

    reg col_ccp_done_reg;
    reg row_ccp_done_reg;

    reg [(T+1)*M-1:0] row_ccp_reg, col_ccp_reg;
    always @(posedge clk) begin
        if(rst) begin
            row_ccp_reg <= 0;
            col_ccp_reg <= 0;
            col_ccp_done_reg <= 0;
            row_ccp_done_reg <= 0;
        end
        else begin
            row_ccp_reg <= row_ccp;
            col_ccp_reg <= col_ccp;
            //col_ccp_done_reg <= col_ccp_done;
            //row_ccp_done_reg <= row_ccp_done;
            col_ccp_done_reg <= col_done_flag_reg;
            row_ccp_done_reg <= row_done_flag_reg;
            //col_ccp_done_reg <= col_done_flag;
            //row_ccp_done_reg <= row_done_flag;
        end
    end

    wire [T*M-1:0] col_c_in;
    assign col_c_in = col_ccp_reg[(T+1)*M-1 -: T*M];

    localparam RE_STAGES = N - 2 * T;

    wire [RE_STAGES*M-1:0] col_S_ext [0:2*T-1];

    generate
        for (j = 0; j < 2*T; j = j + 1) begin : RE_COL_ALL
            RE_chain #(.T(T), .M(M), .NUM_STAGES(RE_STAGES)) U_re_col (
                .c_in(col_c_in),
                .S_init(col_synd_int[j][2*T*M-1 -: T*M]),
                .S_out_all(col_S_ext[j])
            );
        end
    endgenerate

    wire [N*M-1:0] col_synd_full [0:2*T-1];

    generate
        for(j = 0; j < 2*T; j = j + 1) begin
            assign col_synd_full[j][2*T*M-1:0] = col_synd_int[j];
            assign col_synd_full[j][N*M-1:2*T*M] = col_S_ext[j];
        end
    endgenerate

    reg [N*M-1:0] col_synd_full_reg [0:2*T-1];
    reg [(T+1)*M-1:0] row_ccp_reg1;
    reg col_re_done_reg;

    always @(posedge clk) begin
        if(rst) begin
            for(ip = 0; ip < 2*T; ip = ip + 1) begin
                col_synd_full_reg[ip] <= 0;
            end
            row_ccp_reg1 <= 0;
            col_re_done_reg <= 0;
        end
        else begin
            for(ip = 0; ip < 2*T; ip = ip + 1) begin
                col_synd_full_reg[ip] <= col_synd_full[ip];
            end
            row_ccp_reg1 <= row_ccp_reg;
            col_re_done_reg <= col_ccp_done_reg;
        end
    end

    wire [2*M*T-1:0] row_synds_partial [0:N-1];

    generate
        for (i = 0; i < N; i = i + 1) begin : ROW_GATHER
            for (j = 0; j < 2*T; j = j + 1) begin : STACK
                assign row_synds_partial[i][(j+1)*M-1 -: M] =
                    col_synd_full_reg[j][(i+1)*M-1 -: M];
            end
        end
    endgenerate

    wire [T*M-1:0] row_c_in;
    assign row_c_in = row_ccp_reg1[(T+1)*M-1 -: T*M];

    wire [RE_STAGES*M-1:0] row_S_ext [0:N-1];

    generate
        for (i = 0; i < N; i = i + 1) begin : RE_ROW_ALL
            RE_chain #(.T(T), .M(M), .NUM_STAGES(RE_STAGES)) U_re_row (
                .c_in(row_c_in),
                .S_init(row_synds_partial[i][2*T*M-1 -: T*M]),
                .S_out_all(row_S_ext[i])
            );
        end
    endgenerate

    wire [N*M-1:0] row_synd_full [0:N-1];

    generate
        for (i = 0; i < N; i = i + 1) begin : ROW_ASSEMBLE
            assign row_synd_full[i][2*T*M-1:0] = row_synds_partial[i];
            assign row_synd_full[i][N*M-1:2*T*M] = row_S_ext[i];
        end
    endgenerate

    reg [N*M-1:0] synd_full_reg [0:N-1];
    reg row_re_done_reg;

    always @(posedge clk) begin
        if(rst) begin
            for(ip = 0; ip < N; ip = ip + 1) begin
                synd_full_reg[ip] <= 0;
            end
            row_re_done_reg <= 0;
        end
        else begin
            for(ip = 0; ip < N; ip = ip + 1) begin
                synd_full_reg[ip] <= row_synd_full[ip];
            end
            row_re_done_reg <= col_re_done_reg;
        end
    end

    localparam COUNT_1 = 1;
    localparam COUNT_2 = 4;
    localparam COUNT_4 = 54;

    localparam TOTAL_CLASSES = COUNT_1 + COUNT_2 + COUNT_4;

    reg [M*TOTAL_CLASSES-1:0] classes;

    integer c;
    integer j_ip, jp_ip;

    function integer ip_row;
        input integer idx;
        begin
            case(idx)
                 0 : ip_row = 0;
                 1 : ip_row = 0;
                 2 : ip_row = 5;
                 3 : ip_row = 5;
                 4 : ip_row = 5;
                 5 : ip_row = 0;
                 6 : ip_row = 0;
                 7 : ip_row = 0;
                 8 : ip_row = 1;
                 9 : ip_row = 1;
                10 : ip_row = 1;
                11 : ip_row = 1;
                12 : ip_row = 1;
                13 : ip_row = 1;
                14 : ip_row = 1;
                15 : ip_row = 1;
                16 : ip_row = 1;
                17 : ip_row = 1;
                18 : ip_row = 1;
                19 : ip_row = 1;
                20 : ip_row = 1;
                21 : ip_row = 1;
                22 : ip_row = 1;
                23 : ip_row = 3;
                24 : ip_row = 3;
                25 : ip_row = 3;
                26 : ip_row = 3;
                27 : ip_row = 3;
                28 : ip_row = 3;
                29 : ip_row = 3;
                30 : ip_row = 3;
                31 : ip_row = 3;
                32 : ip_row = 3;
                33 : ip_row = 3;
                34 : ip_row = 3;
                35 : ip_row = 3;
                36 : ip_row = 3;
                37 : ip_row = 3;
                38 : ip_row = 5;
                39 : ip_row = 5;
                40 : ip_row = 5;
                41 : ip_row = 5;
                42 : ip_row = 5;
                43 : ip_row = 5;
                44 : ip_row = 7;
                45 : ip_row = 7;
                46 : ip_row = 7;
                47 : ip_row = 7;
                48 : ip_row = 7;
                49 : ip_row = 7;
                50 : ip_row = 7;
                51 : ip_row = 7;
                52 : ip_row = 7;
                53 : ip_row = 7;
                54 : ip_row = 7;
                55 : ip_row = 7;
                56 : ip_row = 7;
                57 : ip_row = 7;
                58 : ip_row = 7;
                default: ip_row = 0;
            endcase
        end
    endfunction

    function integer ip_col;
        input integer idx;
        begin
            case(idx)
                 0 : ip_col = 0;
                 1 : ip_col = 5;
                 2 : ip_col = 0;
                 3 : ip_col = 5;
                 4 : ip_col = 10;
                 5 : ip_col = 1;
                 6 : ip_col = 3;
                 7 : ip_col = 7;
                 8 : ip_col = 0;
                 9 : ip_col = 1;
                10 : ip_col = 2;
                11 : ip_col = 3;
                12 : ip_col = 4;
                13 : ip_col = 5;
                14 : ip_col = 6;
                15 : ip_col = 7;
                16 : ip_col = 8;
                17 : ip_col = 9;
                18 : ip_col = 10;
                19 : ip_col = 11;
                20 : ip_col = 12;
                21 : ip_col = 13;
                22 : ip_col = 14;
                23 : ip_col = 0;
                24 : ip_col = 1;
                25 : ip_col = 2;
                26 : ip_col = 3;
                27 : ip_col = 4;
                28 : ip_col = 5;
                29 : ip_col = 6;
                30 : ip_col = 7;
                31 : ip_col = 8;
                32 : ip_col = 9;
                33 : ip_col = 10;
                34 : ip_col = 11;
                35 : ip_col = 12;
                36 : ip_col = 13;
                37 : ip_col = 14;
                38 : ip_col = 1;
                39 : ip_col = 2;
                40 : ip_col = 3;
                41 : ip_col = 6;
                42 : ip_col = 7;
                43 : ip_col = 11;
                44 : ip_col = 0;
                45 : ip_col = 1;
                46 : ip_col = 2;
                47 : ip_col = 3;
                48 : ip_col = 4;
                49 : ip_col = 5;
                50 : ip_col = 6;
                51 : ip_col = 7;
                52 : ip_col = 8;
                53 : ip_col = 9;
                54 : ip_col = 10;
                55 : ip_col = 11;
                56 : ip_col = 12;
                57 : ip_col = 13;
                58 : ip_col = 14;
                default: ip_col = 0;
            endcase
        end
    endfunction

    always @(*) begin
        classes = 0;
        for (c = 0; c < TOTAL_CLASSES; c = c + 1) begin
            j_ip  = (ip_row(c) + N - 1) % N;   // convert true J  -> array index
            jp_ip = (ip_col(c) + N - 1) % N;   // convert true J' -> array slot
            classes[M*(c+1)-1 -: M] = synd_full_reg[j_ip][M*(jp_ip+1)-1 -: M];
        end
    end

    wire [N*N - 1:0] c_out;

    idffft_synd #(.COUNT_1(COUNT_1), .COUNT_2(COUNT_2), .COUNT_4(COUNT_4), .M(M), .N(N)) IDFFFT (
        .classes(classes),
        .c_out(c_out)
    );

    wire [N*N - 1:0] corrected_res;

    assign corrected_res = c_out ^ r_in_captured1;

    /*always @(posedge clk) begin
        if(rst) begin
            done <= 0;
        end
        else begin
            done <= row_re_done_reg;
        end
    end*/

    assign done = row_re_done_reg;

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

    integer p,q;

    always @(posedge clk) begin
        /*if(col_done_flag_reg) begin
            $display("Received Code Word : ");
            for (p = 0; p < N; p = p + 1) begin
                for (q = 0; q < N; q = q + 1) begin
                    $write("%b ", r_in[N*p + q]);
                end
                $display("");
            end

            $display("Syndromes 1-2t : ");
            $display("%b", S_2t);
            for (p = 1; p <= 2*T; p = p + 1) begin
                for (q = 1; q <= 2*T; q = q + 1) begin
                    $write("%s ", gf_str(S_2t_reg[((p-1)*(2*T) + (q-1)+1)*M-1 -: M]));
                end
                $display("");
            end

            $display("Non conjugate Column Syndromes : ");
            for(p = 0; p < T; p = p + 1) begin
                for (q = 1; q <= 2*T; q = q + 1) begin 
                    $write("%s ", gf_str(col_synd_2t_conjug[p][M*q-1 -: M])); 
                end
                $display("");
            end

            $display("All upper Column Syndromes : ");
            for(p = 0; p < 2*T; p = p + 1) begin
                for (q = 1; q <= 2*T; q = q + 1) begin 
                    $write("%s ", gf_str(col_synd_int[p][M*q-1 -: M])); 
                end
                $display("");
            end

            $display("Column location polynomials : ");
            for(p = 0; p < T; p = p + 1) begin
                for(q = 0; q <= T; q = q + 1) begin
                    $write("%s ", gf_str(col_sigma_arr_reg[p][(q+1)*M - 1 -: M]));
                end
                $display("");
            end

            $display("Column rpos : ");
            for(p = 0; p < T; p = p + 1) begin
                $display("%b", col_rpos[(p+1)*N - 1 -: N]);
            end

            $display("Column lcm rpos : ");
            $display("%b", col_rpos_lcm);

            $display("Column roots found : ");
            for(p = 0; p < T; p = p + 1) begin
                $write("%s ", gf_str(roots_col[(p+1)*M-1 -: M]));
            end
            $display("");
        end
        if(row_done_flag_reg) begin
            $display("Row location polynomials : ");
            for(p = 0; p < T; p = p + 1) begin
                for(q = 0; q <= T; q = q + 1) begin
                    $write("%s ", gf_str(row_sigma_arr_reg[p][(q+1)*M - 1 -: M]));
                end
                $display("");
            end

            $display("Row rpos : ");
            for(p = 0; p < T; p = p + 1) begin
                $display("%b", row_rpos[(p+1)*N - 1 -: N]);
            end

            $display("Row lcm rpos : ");
            $display("%b", row_rpos_lcm);

            $display("Row roots found : ");
            for(p = 0; p < T; p = p + 1) begin
                $write("%s ", gf_str(roots_row[(p+1)*M-1 -: M]));
            end
            $display("");
        end
        if(col_ccp_done_reg) begin
            $display("Column ccp polynomial : ");
            for(p = 0; p <= T; p = p + 1) begin
                $write("%s ", gf_str(col_ccp_reg[(p+1)*M-1 -: M]));
            end
            $display("");
        end
        if(row_ccp_done_reg) begin
            $display("Row ccp polynomial : ");
            for(p = 0; p <= T; p = p + 1) begin
                $write("%s ", gf_str(row_ccp_reg[(p+1)*M-1 -: M]));
            end
            $display("");
        end
        if(col_re_done_reg) begin
            $display("All upper Column Syndromes : ");
            for(p = 0; p < 2*T; p = p + 1) begin
                for (q = 1; q <= 2*T; q = q + 1) begin 
                    $write("%s ", gf_str(col_synd_int[p][M*q-1 -: M])); 
                end
                $display("");
            end
            $display("Extended column syndromes");
            for(p = 0; p < 2*T; p = p + 1) begin
                for (q = 1; q <= RE_STAGES; q = q + 1) begin 
                    $write("%s ", gf_str(col_S_ext[p][M*q-1 -: M])); 
                end
                $display("");
            end
            $display("combined column syndromes : ");
            for(p = 0; p < 2*T; p = p + 1) begin
                for (q = 1; q <= N; q = q + 1) begin 
                    $write("%s ", gf_str(col_synd_full[p][M*q-1 -: M])); 
                end
                $display("");
            end
            $display("packed as row wise syndromes : ");
            for(p = 0; p < N; p = p + 1) begin
                for (q = 0; q < 2*T; q = q + 1) begin 
                    $write("%s ", gf_str(row_synds_partial[p][(q+1)*M-1 -: M])); 
                end
                $display("");
            end
        end*/
        if(row_re_done_reg) begin
            /*$display("full syndrome after row recursive extension : ");
            for(p = 0; p < N; p = p + 1) begin
                for(q = 0; q < N; q = q + 1) begin
                    $write("%s ", gf_str(synd_full_reg[p][(q+1)*M-1 -: M]));
                end
                $display("");
            end
            $display("Conjugate class IPs : ");
            for (c = 0; c < TOTAL_CLASSES; c = c + 1) begin
                $write("%s ", gf_str(classes[M*(c+1)-1 -: M]));
            end
            $display("");*/
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
        end 
    end
endmodule