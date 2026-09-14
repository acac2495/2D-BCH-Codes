`include "../recursive_extension/RE_base.v"

module RE_chain #(parameter T = 2, M = 4, NUM_STAGES = 11) (c_in, S_init, S_out_all);
    input  [T*M-1:0] c_in;
    input  [T*M-1:0] S_init;             // s_{t+1}..s_{2t}, oldest=low, newest=high
    output [NUM_STAGES*M-1:0] S_out_all; // newly computed syndromes, in cascade order

    wire [T*M-1:0] window [0:NUM_STAGES];
    assign window[0] = S_init;

    wire [M-1:0] stage_out [0:NUM_STAGES-1];

    genvar s;
    generate
        for (s = 0; s < NUM_STAGES; s = s + 1) begin : STAGE
            RE_base #(.T(T), .M(M)) U_re (
                .c_in(c_in),
                .S_in(window[s]),
                .S_out(stage_out[s])
            );
            assign window[s+1] = {stage_out[s], window[s][T*M-1:M]};
            assign S_out_all[(s+1)*M-1-:M] = stage_out[s];
        end
    endgenerate
endmodule