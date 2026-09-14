module GF_2_4_inv(
    input  [3:0] in,
    output reg [3:0] out
);
    always @(*) begin
        case(in)
            4'b0000: out = 4'b0000; // 0 has no inverse; don't-care, defined as 0
            4'b1000: out = 4'b1000; // a^0  -> a^0
            4'b0100: out = 4'b1001; // a^1  -> a^14
            4'b0010: out = 4'b1011; // a^2  -> a^13
            4'b0001: out = 4'b1111; // a^3  -> a^12
            4'b1100: out = 4'b0111; // a^4  -> a^11
            4'b0110: out = 4'b1110; // a^5  -> a^10
            4'b0011: out = 4'b0101; // a^6  -> a^9
            4'b1101: out = 4'b1010; // a^7  -> a^8
            4'b1010: out = 4'b1101; // a^8  -> a^7
            4'b0101: out = 4'b0011; // a^9  -> a^6
            4'b1110: out = 4'b0110; // a^10 -> a^5
            4'b0111: out = 4'b1100; // a^11 -> a^4
            4'b1111: out = 4'b0001; // a^12 -> a^3
            4'b1011: out = 4'b0010; // a^13 -> a^2
            4'b1001: out = 4'b0100; // a^14 -> a^1
            default: out = 4'b0000;
        endcase
    end
endmodule