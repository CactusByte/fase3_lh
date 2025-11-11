module ALU (

  input  wire [3:0]  alu_op,

  input  wire [31:0] a,

  input  wire [31:0] b,

  output reg  [31:0] y,

  output wire        zf

);

  always @* begin

    case (alu_op)

      4'd0: y = a + b;

      4'd1: y = a - b;

      4'd2: y = a & b;

      4'd3: y = a | b;

      4'd4: y = a ^ b;

      4'd5: y = b;

      default: y = 32'd0;

    endcase

  end

  assign zf = (y == 32'd0);

endmodule
