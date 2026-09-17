module gf16_square #(parameter M = 4) (in, out);
    input  [M-1:0] in;
    output [M-1:0] out;
    // P^2(alpha) = (a0+a2) + a2*alpha + (a1+a3)*alpha^2 + a3*alpha^3
    // bit convention: in[3]=a0, in[2]=a1, in[1]=a2, in[0]=a3 (MSB-first, matches your project convention)
    assign out[3] = in[3] ^ in[1];   // a0+a2
    assign out[2] = in[1];           // a2
    assign out[1] = in[2] ^ in[0];   // a1+a3
    assign out[0] = in[0];           // a3
endmodule