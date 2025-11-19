module Control (

  input  wire [31:0] instr,

  input  wire        LE,

  output reg         call_instruc,
  output reg  [3:0]  SOH_S,
  output reg         ID_Branch_Instruc,
  output reg  [3:0]  ID_ALU_op,
  output reg         ID_load_intruc,
  output reg         RF_LE,
  output reg  [1:0]  RAM_Size,
  output reg         RAM_R_W,
  output reg         RAM_Enable,
  output reg         jumpl_intruct,
  output reg         PSR_Enable,
  output reg  [1:0]  Load_Call_jmpl,
  output reg         target_sel,

  output reg         alu_src_EX,
  output reg         mem_read_MEM,
  output reg         mem_write_MEM,
  output reg         mem_to_reg_WB,
  output reg  [31:0] imm_ext,
  output reg  [4:0]  rs1, rs2, rd,
  output reg  [79:0] keyword

);

  wire [7:0] op = instr[31:24];



  task defaults;

  begin

    call_instruc   = 1'b0;

    SOH_S          = 4'd0;

    ID_Branch_Instruc = 1'b0;

    ID_ALU_op      = 4'd0;

    ID_load_intruc = 1'b0;

    RF_LE          = 1'b0;

    RAM_Size       = 2'b00;

    RAM_R_W        = 1'b0;

    RAM_Enable     = 1'b0;

    jumpl_intruct  = 1'b0;

    PSR_Enable     = 1'b0;

    Load_Call_jmpl = 2'b00;

    target_sel     = 1'b0;

    alu_src_EX     = 1'b0;

    mem_read_MEM   = 1'b0;

    mem_write_MEM  = 1'b0;

    mem_to_reg_WB  = 1'b0;

    imm_ext        = {{16{instr[15]}}, instr[15:0]};

    rs1 = instr[23:19];

    rs2 = instr[18:14];

    rd  = instr[4:0];

    keyword = "nop";

  end

  endtask



  always @* begin

    defaults();

    case (op)

      8'b10001010: begin

        keyword       = "add";

        ID_ALU_op     = 4'd0;

        SOH_S         = 4'b1000;

        alu_src_EX    = 1'b0;

        RF_LE         = 1'b1;

        mem_to_reg_WB = 1'b0;

        PSR_Enable    = 1'b0;

      end

      8'b10000110: begin

        keyword       = "subcc";

        ID_ALU_op     = 4'd1;

        SOH_S         = 4'b1000;

        alu_src_EX    = 1'b1;

        RF_LE         = 1'b1;

        mem_to_reg_WB = 1'b0;

        PSR_Enable    = 1'b1;

      end

      8'b11000100: begin

        keyword       = "ldub";

        ID_ALU_op     = 4'd0;

        SOH_S         = 4'b0100;

        alu_src_EX    = 1'b1;

        mem_read_MEM  = 1'b1;

        ID_load_intruc = 1'b1;

        RF_LE         = 1'b1;

        mem_to_reg_WB = 1'b1;

        RAM_Size      = 2'b00;

        RAM_R_W       = 1'b0;

        RAM_Enable    = 1'b1;

        Load_Call_jmpl = 2'b01;

      end

      8'b11001010: begin

        keyword       = "stb";

        ID_ALU_op     = 4'd0;

        SOH_S         = 4'b0000;

        alu_src_EX    = 1'b1;

        mem_write_MEM = 1'b1;

        RF_LE         = 1'b0;

        RAM_Size      = 2'b00;

        RAM_R_W       = 1'b1;

        RAM_Enable    = 1'b1;

      end

      8'b00010010: begin

        keyword       = "bne";

        SOH_S         = 4'd0;

        ID_Branch_Instruc = 1'b1;

        target_sel    = 1'b1;

      end

      8'b00001011: begin

        keyword       = "sethi";

        ID_ALU_op     = 4'd5;

        SOH_S         = 4'b0100;

        alu_src_EX    = 1'b1;

        RF_LE         = 1'b0;

        mem_to_reg_WB = 1'b0;

        imm_ext       = {instr[21:0], 10'b0};

      end

      8'b01000000: begin

        keyword       = "call";

        SOH_S         = 4'd0;

        call_instruc  = 1'b1;

        Load_Call_jmpl = 2'b10;

        target_sel    = 1'b1;

        RF_LE         = 1'b1;

        rd            = 5'd15;

      end

      8'b10000001: begin

        keyword       = "jmpl";

        SOH_S         = 4'd0;

        jumpl_intruct = 1'b1;

        Load_Call_jmpl = 2'b11;

        target_sel    = 1'b1;

        RF_LE         = (instr[4:0] != 5'd0) ? 1'b1 : 1'b0;

        rd            = instr[4:0];

      end

      8'b00000000: begin

        keyword       = "nop";

      end

      default: begin

        keyword       = "unk";

      end

    endcase

  end

endmodule
