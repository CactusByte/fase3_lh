module PipeReg #(parameter W=32) (

  input  wire        clk,

  input  wire        reset,

  input  wire [W-1:0] din,

  output reg  [W-1:0] dout

);

  always @(posedge clk) begin

    if (reset) dout <= {W{1'b0}};

    else        dout <= din;

  end

endmodule
