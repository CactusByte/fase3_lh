// mux2.v

module Mux2 #(parameter W=32) (

  input  wire [W-1:0] a,

  input  wire [W-1:0] b,

  input  wire         s,

  output wire [W-1:0] y

);

  assign y = s ? b : a;

endmodule

