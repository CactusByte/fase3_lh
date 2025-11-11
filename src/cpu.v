`define STR_FMT "%s"

module CPU (

  input  wire clk,

  input  wire reset,

  input  wire S

);

  reg [31:0] pc_cur, npc_cur;



  wire [31:0] instr_IF;

  I_MEM imem (.addr(pc_cur), .instr(instr_IF));



  wire [63:0] ifid_in  = {npc_cur, instr_IF};

  wire [63:0] ifid_out;

  PipeReg #(.W(64)) IF_ID (.clk(clk), .reset(reset), .din(ifid_in), .dout(ifid_out));

  wire [31:0] npc_ID  = ifid_out[63:32];

  wire [31:0] instr_ID= ifid_out[31:0];



  wire        call_instruc, ID_Branch_Instruc, ID_load_intruc;
  wire [3:0]  SOH_S;
  wire        RF_LE, RAM_R_W, RAM_Enable, jumpl_intruct, PSR_Enable, target_sel;
  wire [3:0]  ID_ALU_op;
  wire [1:0]  RAM_Size, Load_Call_jmpl;
  wire        LE = 1'b1;

  wire        alu_src_EX;
  wire        mem_read_MEM, mem_write_MEM;
  wire        mem_to_reg_WB;
  wire [31:0] imm_ext;
  wire [4:0]  rs1, rs2, rd;
  wire [79:0] keyword;



  Control ctrl (

    .instr(instr_ID),

    .LE(LE),

    .call_instruc(call_instruc),
    .SOH_S(SOH_S),
    .ID_Branch_Instruc(ID_Branch_Instruc),
    .ID_ALU_op(ID_ALU_op),
    .ID_load_intruc(ID_load_intruc),
    .RF_LE(RF_LE),
    .RAM_Size(RAM_Size),
    .RAM_R_W(RAM_R_W),
    .RAM_Enable(RAM_Enable),
    .jumpl_intruct(jumpl_intruct),
    .PSR_Enable(PSR_Enable),
    .Load_Call_jmpl(Load_Call_jmpl),
    .target_sel(target_sel),

    .alu_src_EX(alu_src_EX),
    .mem_read_MEM(mem_read_MEM), .mem_write_MEM(mem_write_MEM),
    .mem_to_reg_WB(mem_to_reg_WB),
    .imm_ext(imm_ext), .rs1(rs1), .rs2(rs2), .rd(rd),
    .keyword(keyword)

  );



  wire [31:0] rdata1, rdata2, wb_data;

  RegFile rf (

    .clk(clk),

    .we(RF_LE),

    .waddr(rd),

    .wdata(wb_data),

    .raddr1(rs1),

    .raddr2(rs2),

    .rdata1(rdata1),

    .rdata2(rdata2)

  );



  wire branch_compare_equal = (rdata1 == rdata2);

  wire branch_taken_ID = ID_Branch_Instruc && (branch_compare_equal == 1'b0);



  localparam W_IDEX = 4+1+1+1+1 + 5+5+5 + 32+32+32+32+1+32+1+1+1;

  wire [W_IDEX-1:0] idex_in, idex_out;

  assign idex_in = {ID_ALU_op, alu_src_EX, ID_Branch_Instruc, call_instruc, jumpl_intruct, rs1, rs2, rd, rdata1, rdata2, imm_ext, branch_taken_ID, npc_ID, ID_Branch_Instruc, call_instruc, jumpl_intruct};

  PipeReg #(.W(W_IDEX)) ID_EX (.clk(clk), .reset(reset), .din(idex_in), .dout(idex_out));



  wire [3:0]  alu_op_EXs; wire alu_src_EXs, branch_EXs, call_EXs, jmpl_EXs;

  wire [4:0]  rs1_EXs, rs2_EXs, rd_EXs;

  wire [31:0] a_EXs, b_EXs, imm_EXs;

  wire branch_taken_EXs;

  wire [31:0] npc_EXs;

  wire branch_EXs_delay, call_EXs_delay, jmpl_EXs_delay;

  assign {alu_op_EXs, alu_src_EXs, branch_EXs, call_EXs, jmpl_EXs, rs1_EXs, rs2_EXs, rd_EXs, a_EXs, b_EXs, imm_EXs, branch_taken_EXs, npc_EXs, branch_EXs_delay, call_EXs_delay, jmpl_EXs_delay} = idex_out;

  wire [31:0] basePC_EX = npc_EXs - 32'd4;

  wire [31:0] call_target_EX = basePC_EX + (imm_EXs << 2);

  wire [31:0] branch_target_EX = basePC_EX + (imm_EXs << 2);

  wire [31:0] jmpl_target_EX = a_EXs + imm_EXs;

  wire take_ctrl_EX = (jmpl_EXs) ? 1'b1 : ((call_EXs) ? 1'b1 : (branch_taken_EXs));

  wire [31:0] targetPC_EX = (jmpl_EXs) ? jmpl_target_EX : ((call_EXs) ? call_target_EX : branch_target_EX);

  reg take_ctrl_r;
  reg [31:0] targetPC_r;
  wire [31:0] npc_plus4 = npc_cur + 32'd4;
  wire delay_slot_in_EX = (jmpl_EXs_delay || call_EXs_delay || branch_EXs_delay);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      pc_cur <= 32'd0;
      npc_cur <= 32'd4;
      take_ctrl_r <= 1'b0;
      targetPC_r <= 32'd0;
    end else begin
      pc_cur <= npc_cur;
      if (delay_slot_in_EX) begin
        npc_cur <= npc_plus4;
      end else begin
        npc_cur <= take_ctrl_r ? targetPC_r : npc_plus4;
      end
      take_ctrl_r <= take_ctrl_EX;
      targetPC_r <= targetPC_EX;
    end
  end




  wire [31:0] alu_b = alu_src_EXs ? imm_EXs : b_EXs;

  wire [31:0] alu_y; wire alu_zf;

  ALU alu (.alu_op(alu_op_EXs), .a(a_EXs), .b(alu_b), .y(alu_y), .zf(alu_zf));





  localparam W_EXMEM = 32+1+1+5+32;

  wire [W_EXMEM-1:0] exmem_in, exmem_out;

  assign exmem_in = {alu_y, mem_read_MEM, mem_write_MEM, rd_EXs, b_EXs};

  PipeReg #(.W(W_EXMEM)) EX_MEM (.clk(clk), .reset(reset), .din(exmem_in), .dout(exmem_out));



  wire [31:0] addr_MEM; wire mem_read_MEMs, mem_write_MEMs; wire [4:0] rd_MEMs; wire [31:0] store_data_MEMs;

  assign {addr_MEM, mem_read_MEMs, mem_write_MEMs, rd_MEMs, store_data_MEMs} = exmem_out;

  wire [31:0] mem_rdata;

  D_MEM dmem (.clk(clk), .mem_read(mem_read_MEMs), .mem_write(mem_write_MEMs), .addr(addr_MEM), .wdata(store_data_MEMs), .rdata(mem_rdata));



  localparam W_MEMWB = 32+32+1+1+5;

  wire [W_MEMWB-1:0] memwb_in, memwb_out;

  assign memwb_in = {addr_MEM, mem_rdata, RF_LE, mem_to_reg_WB, rd_MEMs};

  PipeReg #(.W(W_MEMWB)) MEM_WB (.clk(clk), .reset(reset), .din(memwb_in), .dout(memwb_out));



  wire [31:0] alu_y_WB, mem_rdata_WB; wire reg_write_WBs, mem_to_reg_WBs; wire [4:0] rd_WBs;

  assign {alu_y_WB, mem_rdata_WB, reg_write_WBs, mem_to_reg_WBs, rd_WBs} = memwb_out;

  assign wb_data = mem_to_reg_WBs ? mem_rdata_WB : alu_y_WB;



  always @(posedge clk) if (!reset) begin

    $write("INST=");

    $write(`STR_FMT, keyword);

    $write("  PC=%0d  nPC=%0d  CTRL(ID): ", pc_cur, npc_cur);

    $display("call_instruc=%b SOH_S=%b ID_Branch_Instruc=%b ID_ALU_op=%b ID_load_intruc=%b RF_LE=%b RAM_Size=%b RAM_R_W=%b RAM_Enable=%b jumpl_intruct=%b PSR_Enable=%b Load_Call_jmpl=%b target_sel=%b",

      call_instruc, SOH_S, ID_Branch_Instruc, ID_ALU_op, ID_load_intruc, RF_LE, RAM_Size, RAM_R_W, RAM_Enable, jumpl_intruct, PSR_Enable, Load_Call_jmpl, target_sel);



    $display("  EX : ALUop=%b ALUSrc=%b", alu_op_EXs, alu_src_EXs);

    $display("  MEM: MemRead=%b MemWrite=%b", mem_read_MEMs, mem_write_MEMs);

    $display("  WB : RegWrite=%b MemToReg=%b", reg_write_WBs, mem_to_reg_WBs);

  end

endmodule
