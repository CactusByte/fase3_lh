// control.v

module Control (

  input  wire [31:0] instr,

  output reg  [3:0]  alu_op_EX,

  output reg         alu_src_EX,     // 0=reg, 1=imm

  output reg         branch_EX,      // bne

  output reg         call_EX,

  output reg         jmpl_EX,



  output reg         mem_read_MEM,

  output reg         mem_write_MEM,



  output reg         reg_write_WB,

  output reg         mem_to_reg_WB,  // 1: desde MEM, 0: desde ALU



  output reg  [31:0] imm_ext,        // inmediato simple (para demo)

  output reg  [4:0]  rs1, rs2, rd,



  output reg  [79:0] keyword         // para imprimir palabra de instrucción

);

  wire [7:0] op = instr[31:24];



  // helpers de "nops" default

  task defaults;

  begin

    alu_op_EX      = 4'd0;

    alu_src_EX     = 1'b0;

    branch_EX      = 1'b0;

    call_EX        = 1'b0;

    jmpl_EX        = 1'b0;

    mem_read_MEM   = 1'b0;

    mem_write_MEM  = 1'b0;

    reg_write_WB   = 1'b0;

    mem_to_reg_WB  = 1'b0;

    imm_ext        = {{16{instr[15]}}, instr[15:0]}; // sign-extend 16b

    rs1 = instr[23:19];

    rs2 = instr[18:14];

    rd  = instr[4:0];

    keyword = "nop";

  end

  endtask



  always @* begin

    defaults();

    case (op)

      8'b10001010: begin // add

        keyword       = "add";

        alu_op_EX     = 4'd0; // ADD

        alu_src_EX    = 1'b0; // reg

        reg_write_WB  = 1'b1;

        mem_to_reg_WB = 1'b0;

      end

      8'b10000110: begin // subcc

        keyword       = "subcc";

        alu_op_EX     = 4'd1; // SUB

        alu_src_EX    = 1'b1; // usa imm=1 (según vector dado)

        reg_write_WB  = 1'b1;

        mem_to_reg_WB = 1'b0;

      end

      8'b11000100: begin // ldub

        keyword       = "ldub";

        alu_op_EX     = 4'd0; // addr calc a+b

        alu_src_EX    = 1'b1; // base + imm

        mem_read_MEM  = 1'b1;

        reg_write_WB  = 1'b1;

        mem_to_reg_WB = 1'b1; // write desde MEM

      end

      8'b11001010: begin // stb

        keyword       = "stb";

        alu_op_EX     = 4'd0;

        alu_src_EX    = 1'b1;

        mem_write_MEM = 1'b1;

        reg_write_WB  = 1'b0;

      end

      8'b00010010: begin // bne

        keyword       = "bne";

        branch_EX     = 1'b1;

      end

      8'b00001011: begin // sethi

        keyword       = "sethi";

        alu_op_EX     = 4'd5; // passthrough imm alto

        alu_src_EX    = 1'b1;

        reg_write_WB  = 1'b1;

        mem_to_reg_WB = 1'b0;

      end

      8'b01000000: begin // call

        keyword       = "call";

        call_EX       = 1'b1;

      end

      8'b10000001: begin // jmpl

        keyword       = "jmpl";

        jmpl_EX       = 1'b1;

      end

      8'b00000000: begin // nop

        keyword       = "nop";

      end

      default: begin

        keyword       = "unk";

      end

    endcase

  end

endmodule

