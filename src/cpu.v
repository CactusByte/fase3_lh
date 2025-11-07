// cpu.v

`define STR_FMT "%s"

module CPU (

  input  wire clk,

  input  wire reset,

  input  wire S // señal del MUX externo (cambia a 1 en t=40)

);

  // PC / nPC con LE=1 siempre (puedes modular si quieres stalls)

  wire [31:0] pc_cur, npc_cur;

  wire [31:0] pc_plus4 = pc_cur + 32'd4;

  wire [31:0] npc_next_seq = npc_cur + 32'd4;

  wire [31:0] pc_next_mux; // Declarado aquí, asignado más adelante



  PC  uPC  (.clk(clk), .reset(reset), .le(1'b1), .next_pc(pc_next_mux), .pc(pc_cur));

  NPC uNPC (.clk(clk), .reset(reset), .le(1'b1), .next_npc(npc_next_seq), .npc(npc_cur));



  // IF: instruction fetch

  wire [31:0] instr_IF;

  I_MEM imem (.addr(pc_cur), .instr(instr_IF));



  // IF/ID

  wire [63:0] ifid_in  = {npc_cur, instr_IF};

  wire [63:0] ifid_out;

  PipeReg #(.W(64)) IF_ID (.clk(clk), .reset(reset), .din(ifid_in), .dout(ifid_out));

  wire [31:0] npc_ID  = ifid_out[63:32];

  wire [31:0] instr_ID= ifid_out[31:0];



  // Control en ID

  wire [3:0]  alu_op_EX;

  wire        alu_src_EX, branch_EX, call_EX, jmpl_EX;

  wire        mem_read_MEM, mem_write_MEM;

  wire        reg_write_WB, mem_to_reg_WB;

  wire [31:0] imm_ext;

  wire [4:0]  rs1, rs2, rd;

  wire [79:0] keyword;



  Control ctrl (

    .instr(instr_ID),

    .alu_op_EX(alu_op_EX), .alu_src_EX(alu_src_EX),

    .branch_EX(branch_EX), .call_EX(call_EX), .jmpl_EX(jmpl_EX),

    .mem_read_MEM(mem_read_MEM), .mem_write_MEM(mem_write_MEM),

    .reg_write_WB(reg_write_WB), .mem_to_reg_WB(mem_to_reg_WB),

    .imm_ext(imm_ext), .rs1(rs1), .rs2(rs2), .rd(rd),

    .keyword(keyword)

  );



  // Banco de registros (demo: usamos rs1/rs2/rd tal cual)

  wire [31:0] rdata1, rdata2, wb_data;

  RegFile rf (

    .clk(clk),

    .we(reg_write_WB),

    .waddr(rd),

    .wdata(wb_data),

    .raddr1(rs1),

    .raddr2(rs2),

    .rdata1(rdata1),

    .rdata2(rdata2)

  );



  // Cálculo de targets en ID (para timing correcto)

  wire [31:0] branch_target_ID = npc_ID + (imm_ext << 2);

  wire [31:0] call_target_ID = npc_ID + (imm_ext << 2);

  wire [31:0] jmpl_target_ID = rdata1 + imm_ext;



  // Comparación para branch_taken en ID (simplificado: comparar rdata1 y rdata2)

  wire branch_compare_equal = (rdata1 == rdata2);

  wire branch_taken_ID = branch_EX && (branch_compare_equal == 1'b0); // bne: taken si no son iguales



  // ID/EX: pasar operandos y señales a EX

  // Empaquetamos: [EX control + rs1,rs2,rd + operandos + imm + npc_ID + targets + branch_taken]

  localparam W_IDEX = 4+1+1+1+1 + 5+5+5 + 32+32+32+32+32+32+32+1; // alu_op + alu_src + branch + call + jmpl + rs1+rs2+rd + rA+rB+imm + npc_ID + branch_target + call_target + jmpl_target + branch_taken

  wire [W_IDEX-1:0] idex_in, idex_out;

  assign idex_in = {alu_op_EX, alu_src_EX, branch_EX, call_EX, jmpl_EX, rs1, rs2, rd, rdata1, rdata2, imm_ext, npc_ID, branch_target_ID, call_target_ID, jmpl_target_ID, branch_taken_ID};

  PipeReg #(.W(W_IDEX)) ID_EX (.clk(clk), .reset(reset), .din(idex_in), .dout(idex_out));



  wire [3:0]  alu_op_EXs; wire alu_src_EXs, branch_EXs, call_EXs, jmpl_EXs;

  wire [4:0]  rs1_EXs, rs2_EXs, rd_EXs;

  wire [31:0] a_EXs, b_EXs, imm_EXs, npc_EXs;

  wire [31:0] branch_target_EXs, call_target_EXs, jmpl_target_EXs;

  wire branch_taken_EXs;

  assign {alu_op_EXs, alu_src_EXs, branch_EXs, call_EXs, jmpl_EXs, rs1_EXs, rs2_EXs, rd_EXs, a_EXs, b_EXs, imm_EXs, npc_EXs, branch_target_EXs, call_target_EXs, jmpl_target_EXs, branch_taken_EXs} = idex_out;



  // Selección de próximo PC con prioridades: jmpl > call > branch_taken > pc+4

  // Usamos las señales de ID para calcular el PC del siguiente ciclo

  // (Las señales de EX están un ciclo tarde, así que usamos las de ID directamente)

  wire [31:0] pc_target =

    jmpl_EX  ? jmpl_target_ID :

    call_EX  ? call_target_ID :

    branch_taken_ID ? branch_target_ID :

    pc_plus4;



  // Selección de próximo PC vía MUX (S como override manual, última prioridad)

  Mux2 #(32) pc_mux (.a(pc_target), .b(32'd0 /*alternativa demo*/), .s(S), .y(pc_next_mux));



  // ALU operandos

  wire [31:0] alu_b = alu_src_EXs ? imm_EXs : b_EXs;

  wire [31:0] alu_y; wire alu_zf;

  ALU alu (.alu_op(alu_op_EXs), .a(a_EXs), .b(alu_b), .y(alu_y), .zf(alu_zf));






  // EX/MEM

  localparam W_EXMEM = 32+1+1+5+32; // alu_y + mem_read + mem_write + rd + b_EXs (para stores)

  wire [W_EXMEM-1:0] exmem_in, exmem_out;

  assign exmem_in = {alu_y, mem_read_MEM, mem_write_MEM, rd_EXs, b_EXs};

  PipeReg #(.W(W_EXMEM)) EX_MEM (.clk(clk), .reset(reset), .din(exmem_in), .dout(exmem_out));



  wire [31:0] addr_MEM; wire mem_read_MEMs, mem_write_MEMs; wire [4:0] rd_MEMs; wire [31:0] store_data_MEMs;

  assign {addr_MEM, mem_read_MEMs, mem_write_MEMs, rd_MEMs, store_data_MEMs} = exmem_out;



  // MEM stage

  wire [31:0] mem_rdata;

  D_MEM dmem (.clk(clk), .mem_read(mem_read_MEMs), .mem_write(mem_write_MEMs), .addr(addr_MEM), .wdata(store_data_MEMs), .rdata(mem_rdata));



  // MEM/WB

  localparam W_MEMWB = 32+32+1+1+5; // alu_y + mem_rdata + reg_write + mem_to_reg + rd

  wire [W_MEMWB-1:0] memwb_in, memwb_out;

  assign memwb_in = {addr_MEM, mem_rdata, reg_write_WB, mem_to_reg_WB, rd_MEMs};

  PipeReg #(.W(W_MEMWB)) MEM_WB (.clk(clk), .reset(reset), .din(memwb_in), .dout(memwb_out));



  wire [31:0] alu_y_WB, mem_rdata_WB; wire reg_write_WBs, mem_to_reg_WBs; wire [4:0] rd_WBs;

  assign {alu_y_WB, mem_rdata_WB, reg_write_WBs, mem_to_reg_WBs, rd_WBs} = memwb_out;

  assign wb_data = mem_to_reg_WBs ? mem_rdata_WB : alu_y_WB;



  // ---- Impresiones por ciclo (según requisito) ----

  // Línea 1: keyword, PC, nPC, señales de salida de la Unidad de Control (binario "plano")

  // Luego: EX, MEM, WB en líneas sucesivas (binario)

  // Nota: imprimimos señales del ciclo "ID" actual (control) y las que fluyen (EX/MEM/WB)

  always @(posedge clk) if (!reset) begin

    $write("INST=");

    $write(`STR_FMT, keyword);

    $write("  PC=%0d  nPC=%0d  CTRL(ID): ", pc_cur, npc_cur);

    $display("ALUop=%b ALUSrc=%b BR=%b CALL=%b JMPL=%b MemR=%b MemW=%b RegW=%b M2R=%b",

      alu_op_EX, alu_src_EX, branch_EX, call_EX, jmpl_EX, mem_read_MEM, mem_write_MEM, reg_write_WB, mem_to_reg_WB);



    $display("  EX : ALUop=%b ALUSrc=%b", alu_op_EXs, alu_src_EXs);

    $display("  MEM: MemRead=%b MemWrite=%b", mem_read_MEMs, mem_write_MEMs);

    $display("  WB : RegWrite=%b MemToReg=%b", reg_write_WBs, mem_to_reg_WBs);

  end

endmodule

