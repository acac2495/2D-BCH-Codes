module mux #(parameter M = 4) (in1, in2, sel, out);
    input [M-1:0] in1, in2;
    input sel;
    output [M-1:0] out;

    assign out = (sel == 1) ? in1 : in2;
endmodule