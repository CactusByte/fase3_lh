// pc.v

module PC (

  input  wire        clk,

  input  wire        reset,   // sincrónico

  input  wire        le,      // load enable

  input  wire [31:0] next_pc,

  output reg  [31:0] pc

);

  always @(posedge clk) begin

    if (reset) pc <= 32'd0;

    else if (le) pc <= next_pc;

  end

endmodule

