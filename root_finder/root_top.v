`include "../root_finder/poly_i.v"

module root_top #(parameter T = 2, N = 15, M = 4) (c_in, rpos);
    input [(T+1)*M-1:0] c_in;
    output [N-1:0] rpos;

    genvar i;
    generate
        for(i = 0; i < N; i = i + 1) begin
            poly_i #(.M(M), .T(T), .REF(i+1)) U_i(
                .c_in(c_in),
                .out_bit(rpos[i])
            );
        end
    endgenerate

    /*
    poly_i #(.M(4), .T(T), .REF("poly_1.hex")) U1(
        .c_in(c_in),
        .out_bit(rpos[0])
    );
    poly_i #(.M(4), .T(T), .REF("poly_2.hex")) U2(
        .c_in(c_in),
        .out_bit(rpos[1])
    );
    poly_i #(.M(4), .T(T), .REF("poly_3.hex")) U3(
        .c_in(c_in),
        .out_bit(rpos[2])
    );
    poly_i #(.M(4), .T(T), .REF("poly_4.hex")) U4(
        .c_in(c_in),
        .out_bit(rpos[3])
    );
    poly_i #(.M(4), .T(T), .REF("poly_5.hex")) U5(
        .c_in(c_in),
        .out_bit(rpos[4])
    );
    poly_i #(.M(4), .T(T), .REF("poly_6.hex")) U6(
        .c_in(c_in),
        .out_bit(rpos[5])
    );
    poly_i #(.M(4), .T(T), .REF("poly_7.hex")) U7(
        .c_in(c_in),
        .out_bit(rpos[6])
    );
    poly_i #(.M(4), .T(T), .REF("poly_8.hex")) U8(
        .c_in(c_in),
        .out_bit(rpos[7])
    );
    poly_i #(.M(4), .T(T), .REF("poly_9.hex")) U9(
        .c_in(c_in),
        .out_bit(rpos[8])
    );
    poly_i #(.M(4), .T(T), .REF("poly_10.hex")) U10(
        .c_in(c_in),
        .out_bit(rpos[9])
    );
    poly_i #(.M(4), .T(T), .REF("poly_11.hex")) U11(
        .c_in(c_in),
        .out_bit(rpos[10])
    );
    poly_i #(.M(4), .T(T), .REF("poly_12.hex")) U12(
        .c_in(c_in),
        .out_bit(rpos[11])
    );
    poly_i #(.M(4), .T(T), .REF("poly_13.hex")) U13(
        .c_in(c_in),
        .out_bit(rpos[12])
    );
    poly_i #(.M(4), .T(T), .REF("poly_14.hex")) U14(
        .c_in(c_in),
        .out_bit(rpos[13])
    );
    poly_i #(.M(4), .T(T), .REF("poly_15.hex")) U15(
        .c_in(c_in),
        .out_bit(rpos[14])
    );
    */
endmodule  