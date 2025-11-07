// alu.v

module ALU (

  input  wire [3:0]  alu_op,     // 0=ADD,1=SUB,2=AND,3=OR,4=XOR,5=PASSB

  input  wire [31:0] a,

  input  wire [31:0] b,

  output reg  [31:0] y,

  output wire        zf

);

  always @* begin

    case (alu_op)

      4'd0: y = a + b;      // ADD

      4'd1: y = a - b;      // SUB

      4'd2: y = a & b;      // AND

      4'd3: y = a | b;      // OR

      4'd4: y = a ^ b;      // XOR

      4'd5: y = b;          // passthrough (sethi, etc.)

      default: y = 32'd0;

    endcase

  end

  assign zf = (y == 32'd0);

endmodule

