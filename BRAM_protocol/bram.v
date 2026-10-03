module bram #(parameter N = 15, DEPTH = 16) (
     input clk, rst,
     input [N*N-1:0] data_in,
     input [$clog2(DEPTH)-1:0] addr,
     input we,
     output reg [N*N-1:0] data_out
 );
 
     reg [N*N-1:0] mem [0:DEPTH-1];
 
     always @(posedge clk) begin
         if(rst) begin
             data_out <= 0;
         end
         else begin
             if(we) begin
                 mem[addr] <= data_in;
             end
             data_out <= mem[addr];
         end
     end
 
 endmodule