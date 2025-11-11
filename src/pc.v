module PC (

  input  wire        clk,

  input  wire        reset,

  input  wire        le,

  input  wire [31:0] next_pc,

  output reg  [31:0] pc

);

  always @(posedge clk) begin

    if (reset) pc <= 32'd0;

    else if (le) pc <= next_pc;

  end

endmodule
