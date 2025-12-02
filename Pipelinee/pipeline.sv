// ============================================================
// pipeline_riscv.sv - Procesador RISC-V con Pipeline FUNCIONAL
// IF -> ID -> EX -> MEM -> WB
// Con Forwarding, Hazard Detection, Branch Handling y HALT
// ============================================================

module pipeline (
  input  logic        CLOCK_50,
  input  logic [3:0]  KEY,
  input  logic [9:0]  SW,
  
  output logic [6:0]  HEX0, HEX1, HEX2, HEX3,
  output logic [9:0]  LEDR,
  
  output logic [7:0]  VGA_R, VGA_G, VGA_B,
  output logic        VGA_HS, VGA_VS, VGA_CLK
);

  logic clk, reset;
  assign clk = ~KEY[0];
  assign reset = ~KEY[1];
  
  // ============================================================
  // SEÑAL DE HALT (DETECCIÓN DE EBREAK)
  // ============================================================
  logic halt_detected;
  logic [4:0] br_op_display;  // Para el display
  
  // EBREAK = 0x00100073 - Detectar solo en IF (más simple)
  logic ebreak_found;
  assign ebreak_found = (instruction == 32'h00100073);
  
  // Una vez que detectamos EBREAK, nos quedamos detenidos
  always_ff @(posedge clk) begin
    if (reset) begin
      halt_detected <= 1'b0;
      br_op_display <= 5'b00000;
    end else begin
      // Cuando encontramos EBREAK, activamos halt
      if (ebreak_found)
        halt_detected <= 1'b1;
      
      // Actualizamos br_op_display
      if (ebreak_found)
        br_op_display <= 5'b11000;      // Código de EBREAK
      else if (!halt_detected)
        br_op_display <= br_op;         // Seguir instrucción actual
    end
  end
  
  // ============================================================
  // REGISTROS DE PIPELINE
  // ============================================================
  
  // IF/ID
  logic [31:0] IF_ID_pc, IF_ID_pc_plus4;
  logic [31:0] IF_ID_instruction;
  logic        IF_ID_valid;
  
  // ID/EX
  logic [31:0] ID_EX_pc, ID_EX_pc_plus4;
  logic [31:0] ID_EX_rs1_data, ID_EX_rs2_data;
  logic [31:0] ID_EX_immediate;
  logic [4:0]  ID_EX_rd, ID_EX_rs1, ID_EX_rs2;
  logic [2:0]  ID_EX_funct3;
  logic        ID_EX_ru_write;
  logic [3:0]  ID_EX_alu_op;
  logic [1:0]  ID_EX_alu_a_src;
  logic        ID_EX_alu_b_src;
  logic        ID_EX_dm_write;
  logic [2:0]  ID_EX_dm_ctrl;
  logic [4:0]  ID_EX_br_op;
  logic [1:0]  ID_EX_ru_data_src;
  logic        ID_EX_valid;
  logic [31:0] ID_EX_instruction;
  
  // EX/MEM
  logic [31:0] EX_MEM_pc_plus4;
  logic [31:0] EX_MEM_alu_result;
  logic [31:0] EX_MEM_rs2_data;
  logic [31:0] EX_MEM_immediate;
  logic [4:0]  EX_MEM_rd;
  logic [31:0] EX_MEM_instruction;
  
  // Control signals EX/MEM
  logic        EX_MEM_ru_write;
  logic        EX_MEM_dm_write;
  logic [2:0]  EX_MEM_dm_ctrl;
  logic [1:0]  EX_MEM_ru_data_src;
  logic        EX_MEM_valid;
  
  // MEM/WB
  logic [31:0] MEM_WB_alu_result;
  logic [31:0] MEM_WB_mem_data;
  logic [31:0] MEM_WB_pc_plus4;
  logic [31:0] MEM_WB_immediate;
  logic [4:0]  MEM_WB_rd;
  logic [31:0] MEM_WB_instruction;
  
  // Control signals MEM/WB
  logic        MEM_WB_ru_write;
  logic [1:0]  MEM_WB_ru_data_src;
  logic        MEM_WB_valid;
  
  // ============================================================
  // SEÑALES DE CONTROL DE HAZARDS
  // ============================================================
  logic stall_pipeline;
  logic flush_IF_ID;
  logic flush_ID_EX;
  logic pc_write_enable;
  logic take_branch;
  
  // ============================================================
  // STAGE 1: IF (Instruction Fetch)
  // ============================================================
  logic [31:0] pc_current, pc_next;
  logic [31:0] pc_plus4;
  logic [31:0] instruction;
  logic [31:0] branch_target;
  logic        reset_high;
  
  assign pc_plus4 = pc_current + 32'd4;
  assign reset_high = reset;
  
  // PC Selection (branch tiene prioridad)
  assign pc_next = take_branch ? branch_target : pc_plus4;
  
  // ============================================================
  // MÓDULO PC CON HALT
  // ============================================================
  logic pc_should_update;
  assign pc_should_update = pc_write_enable && !halt_detected;
  
  pc program_counter (
    .next_address(pc_should_update ? pc_next : pc_current),
    .clk(clk),
    .reset(reset_high),
    .initial_address(32'h00000000),
    .address(pc_current)
  );
  
  // Instruction Memory
  logic [31:0] instruction_display [0:31];

  instruction_memory imem (
    .address(pc_current),
    .page_select(SW[7:6]),
    .instruction(instruction),
    .memory_out(instruction_display)  
  );
  
  // IF/ID Pipeline Register
  always_ff @(posedge clk) begin
    if (reset || flush_IF_ID) begin
      IF_ID_pc <= 32'd0;
      IF_ID_pc_plus4 <= 32'd0;
      IF_ID_instruction <= 32'h00000013;  // NOP
      IF_ID_valid <= 1'b0;
    end else if (!stall_pipeline && !halt_detected) begin
      IF_ID_pc <= pc_current;
      IF_ID_pc_plus4 <= pc_plus4;
      IF_ID_instruction <= instruction;
      IF_ID_valid <= 1'b1;
    end
  end
  
  // ============================================================
  // STAGE 2: ID (Instruction Decode)
  // ============================================================
  logic [6:0]  opcode;
  logic [4:0]  rd, rs1, rs2;
  logic [2:0]  funct3;
  logic [6:0]  funct7;
  logic [31:0] rs1_data_raw, rs2_data_raw;
  logic [31:0] immediate;
  
  // Control signals
  logic        ru_write;
  logic [3:0]  alu_op;
  logic [2:0]  imm_src;
  logic [1:0]  alu_a_src;
  logic        alu_b_src;
  logic        dm_write;
  logic [2:0]  dm_ctrl;
  logic [4:0]  br_op;
  logic [1:0]  ru_data_src;

  // Instruction Decoder
  instruction_decoder decoder (
    .instruction(IF_ID_instruction),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7)
  );
  
  // Control Unit
  control_unit ctrl (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .ru_write(ru_write),
    .alu_op(alu_op),
    .imm_src(imm_src),
    .alu_a_src(alu_a_src),
    .alu_b_src(alu_b_src),
    .dm_write(dm_write),
    .dm_ctrl(dm_ctrl),
    .br_op(br_op),
    .ru_data_src(ru_data_src)
  );
  
  // Immediate Generator
  immediate_generator imm_gen (
    .instruction(IF_ID_instruction),
    .imm_src(imm_src),
    .opcode(opcode),
    .funct3(funct3),
    .immediate(immediate)
  );
  
  // Register File
  logic [31:0] wb_data;
  logic [31:0] registers [0:31];
  
  registerUnit reg_file (
    .rs1(rs1),
    .rs2(rs2),
    .rd(MEM_WB_rd),
    .clk(clk),
    .reset(reset),
    .writeEnable(MEM_WB_ru_write && MEM_WB_valid),
    .data(wb_data),
    .rs1Data(rs1_data_raw),
    .rs2Data(rs2_data_raw),
    .registers_out(registers)
  );
  
  // ============================================================
  // HAZARD DETECTION UNIT
  // ============================================================

  hazard_detection_unit hazard_unit (
    .id_rs1(rs1),
    .id_rs2(rs2),
    .ex_rd(ID_EX_rd),
    .ex_ru_data_src(ID_EX_ru_data_src),
    .ex_valid(ID_EX_valid),
    .ex_br_op(ID_EX_br_op),
    .take_branch(take_branch),
    .stall_pipeline(stall_pipeline),
    .flush_if_id(flush_IF_ID),
    .flush_id_ex(flush_ID_EX),
    .pc_write_enable(pc_write_enable)
  );
  
  // ============================================================
  // FORWARDING UNIT
  // ============================================================
  logic [1:0] forward_a_sel, forward_b_sel;
  
  forwarding_unit forward_unit (
    .ex_rs1(rs1),
    .ex_rs2(rs2),
    .mem_rd(EX_MEM_rd),
    .mem_regwrite(EX_MEM_ru_write),
    .mem_valid(EX_MEM_valid),
    .wb_rd(MEM_WB_rd),
    .wb_regwrite(MEM_WB_ru_write),
    .wb_valid(MEM_WB_valid),
    .forward_a(forward_a_sel),
    .forward_b(forward_b_sel)
  );
  
  // Aplicar forwarding en ID stage (para branches)
  logic [31:0] rs1_data, rs2_data;
  logic [31:0] ex_forward_data, mem_forward_data;
  
  // Datos para forward desde EX/MEM
  always_comb begin
    case (EX_MEM_ru_data_src)
      2'b00: ex_forward_data = EX_MEM_alu_result;
      2'b10: ex_forward_data = EX_MEM_pc_plus4;
      2'b11: ex_forward_data = EX_MEM_immediate;
      default: ex_forward_data = EX_MEM_alu_result;
    endcase
  end
  
  assign mem_forward_data = wb_data;
  
  // Multiplexores de forwarding
  always_comb begin
    case (forward_a_sel)
      2'b00: rs1_data = rs1_data_raw;
      2'b01: rs1_data = mem_forward_data;
      2'b10: rs1_data = ex_forward_data;
      default: rs1_data = rs1_data_raw;
    endcase
    
    case (forward_b_sel)
      2'b00: rs2_data = rs2_data_raw;
      2'b01: rs2_data = mem_forward_data;
      2'b10: rs2_data = ex_forward_data;
      default: rs2_data = rs2_data_raw;
    endcase
  end
  
  // ID/EX Pipeline Register
  always_ff @(posedge clk) begin
    if (reset || flush_ID_EX) begin
      ID_EX_pc <= 32'd0;
      ID_EX_pc_plus4 <= 32'd0;
      ID_EX_rs1_data <= 32'd0;
      ID_EX_rs2_data <= 32'd0;
      ID_EX_immediate <= 32'd0;
      ID_EX_rd <= 5'd0;
      ID_EX_rs1 <= 5'd0;
      ID_EX_rs2 <= 5'd0;
      ID_EX_funct3 <= 3'd0;
      ID_EX_ru_write <= 1'b0;
      ID_EX_alu_op <= 4'd0;
      ID_EX_alu_a_src <= 2'd0;
      ID_EX_alu_b_src <= 1'b0;
      ID_EX_dm_write <= 1'b0;
      ID_EX_dm_ctrl <= 3'd0;
      ID_EX_br_op <= 5'd0;
      ID_EX_ru_data_src <= 2'd0;
      ID_EX_valid <= 1'b0;
      ID_EX_instruction <= 32'h00000013;
    end else if (!stall_pipeline && !halt_detected) begin
      ID_EX_pc <= IF_ID_pc;
      ID_EX_pc_plus4 <= IF_ID_pc_plus4;
      ID_EX_rs1_data <= rs1_data;
      ID_EX_rs2_data <= rs2_data;
      ID_EX_immediate <= immediate;
      ID_EX_rd <= rd;
      ID_EX_rs1 <= rs1;
      ID_EX_rs2 <= rs2;
      ID_EX_funct3 <= funct3;
      ID_EX_ru_write <= ru_write && IF_ID_valid;
      ID_EX_alu_op <= alu_op;
      ID_EX_alu_a_src <= alu_a_src;
      ID_EX_alu_b_src <= alu_b_src;
      ID_EX_dm_write <= dm_write && IF_ID_valid;
      ID_EX_dm_ctrl <= dm_ctrl;
      ID_EX_br_op <= br_op;
      ID_EX_ru_data_src <= ru_data_src;
      ID_EX_valid <= IF_ID_valid;
      ID_EX_instruction <= IF_ID_instruction;
    end
  end
  
  // ============================================================
  // STAGE 3: EX (Execute)
  // ============================================================
  logic [31:0] alu_operand_a, alu_operand_b;
  logic [31:0] alu_result;
  
  // ALU Operand Selection
  always_comb begin
    case (ID_EX_alu_a_src)
      2'b00: alu_operand_a = ID_EX_rs1_data;
      2'b01: alu_operand_a = ID_EX_pc;
      default: alu_operand_a = ID_EX_rs1_data;
    endcase
    
    alu_operand_b = ID_EX_alu_b_src ? ID_EX_immediate : ID_EX_rs2_data;
  end
  
  // ALU
  alu alu_unit (
    .operand1(alu_operand_a),
    .operand2(alu_operand_b),
    .funct3(ID_EX_alu_op[2:0]),
    .subsra(ID_EX_alu_op[3]),
    .result(alu_result)
  );
  
  // ============================================================
  // BRANCH DECISION UNIT
  // ============================================================
  branch_decision_unit branch_unit (
    .rs1_data(ID_EX_rs1_data),
    .rs2_data(ID_EX_rs2_data),
    .br_op(ID_EX_br_op),
    .funct3(ID_EX_funct3),
    .valid(ID_EX_valid),
    .pc_current(ID_EX_pc),
    .immediate(ID_EX_immediate),
    .alu_result(alu_result),
    .take_branch(take_branch),
    .branch_target(branch_target)
  );
  
  // EX/MEM Pipeline Register
  always_ff @(posedge clk) begin
    if (reset) begin
      EX_MEM_pc_plus4 <= 32'd0;
      EX_MEM_alu_result <= 32'd0;
      EX_MEM_rs2_data <= 32'd0;
      EX_MEM_immediate <= 32'd0;
      EX_MEM_rd <= 5'd0;
      EX_MEM_ru_write <= 1'b0;
      EX_MEM_dm_write <= 1'b0;
      EX_MEM_dm_ctrl <= 3'd0;
      EX_MEM_ru_data_src <= 2'd0;
      EX_MEM_valid <= 1'b0;
      EX_MEM_instruction <= 32'h00000013;
    end else if (!halt_detected) begin
      EX_MEM_pc_plus4 <= ID_EX_pc_plus4;
      EX_MEM_alu_result <= alu_result;
      EX_MEM_rs2_data <= ID_EX_rs2_data;
      EX_MEM_immediate <= ID_EX_immediate;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_ru_write <= ID_EX_ru_write;
      EX_MEM_dm_write <= ID_EX_dm_write;
      EX_MEM_dm_ctrl <= ID_EX_dm_ctrl;
      EX_MEM_ru_data_src <= ID_EX_ru_data_src;
      EX_MEM_valid <= ID_EX_valid;
      EX_MEM_instruction <= ID_EX_instruction;
    end
  end
  
  // ============================================================
  // STAGE 4: MEM (Memory Access)
  // ============================================================
  logic [31:0] mem_read_data;
  logic [31:0] memory_display [0:31];
  
  data_memory dmem (
    .clk(clk),
    .address(EX_MEM_alu_result),
    .write_data(EX_MEM_rs2_data),
    .write_enable(EX_MEM_dm_write && EX_MEM_valid),
    .dm_ctrl(EX_MEM_dm_ctrl),
    .read_data(mem_read_data),
    .memory_out(memory_display)
  );
  
  // MEM/WB Pipeline Register
  always_ff @(posedge clk) begin
    if (reset) begin
      MEM_WB_alu_result <= 32'd0;
      MEM_WB_mem_data <= 32'd0;
      MEM_WB_pc_plus4 <= 32'd0;
      MEM_WB_immediate <= 32'd0;
      MEM_WB_rd <= 5'd0;
      MEM_WB_ru_write <= 1'b0;
      MEM_WB_ru_data_src <= 2'd0;
      MEM_WB_valid <= 1'b0;
      MEM_WB_instruction <= 32'h00000013;
    end else if (!halt_detected) begin
      MEM_WB_alu_result <= EX_MEM_alu_result;
      MEM_WB_mem_data <= mem_read_data;
      MEM_WB_pc_plus4 <= EX_MEM_pc_plus4;
      MEM_WB_immediate <= EX_MEM_immediate;
      MEM_WB_rd <= EX_MEM_rd;
      MEM_WB_ru_write <= EX_MEM_ru_write;
      MEM_WB_ru_data_src <= EX_MEM_ru_data_src;
      MEM_WB_valid <= EX_MEM_valid;
      MEM_WB_instruction <= EX_MEM_instruction;
    end
  end
  
  // ============================================================
  // STAGE 5: WB (Write Back)
  // ============================================================
  always_comb begin
    case (MEM_WB_ru_data_src)
      2'b00: wb_data = MEM_WB_alu_result;
      2'b01: wb_data = MEM_WB_mem_data;
      2'b10: wb_data = MEM_WB_pc_plus4;
      2'b11: wb_data = MEM_WB_immediate;
      default: wb_data = MEM_WB_alu_result;
    endcase
  end
  
  // ============================================================
  // DEBUG & OUTPUT
  // ============================================================
  logic [31:0] reg_changed_mask;
  assign reg_changed_mask = 32'h0;
  
  risc_debug_display vga_debug (
    .clock(CLOCK_50),
    .sw0(reset),
    .sw1(SW[2]), .sw2(SW[3]), .sw3(SW[4]), .sw4(SW[5]), .sw5(SW[6]),
    .page_select(SW[7:6]),
    
    .regs_demo(registers),
    .changed_mask(reg_changed_mask),
    .pc_value(pc_current),
    .instruction(IF_ID_instruction),
    .br_op(br_op_display),  // Usar la señal que mantiene EBREAK visible
    .alu_operand_a(alu_operand_a),
    .alu_operand_b(alu_operand_b),
    .alu_result(alu_result),
    .alu_op(ID_EX_alu_op),
    .immediate(ID_EX_immediate),
    .memory(memory_display),
    .instruction_memory(instruction_display),

    // Pipeline Stages
    .if_pc(pc_current),
    .if_instr(instruction),
    
    .id_pc(IF_ID_pc),
    .id_instr(IF_ID_instruction),
    .id_valid(IF_ID_valid),

    .ex_pc(ID_EX_pc),
    .ex_instr(ID_EX_instruction),
    .ex_alu_res(alu_result),
    .ex_valid(ID_EX_valid),

    .mem_pc(EX_MEM_pc_plus4 - 4),
    .mem_instr(EX_MEM_instruction),
    .mem_data(mem_read_data),
    .mem_valid(EX_MEM_valid),

    .wb_pc(MEM_WB_pc_plus4 - 4),
    .wb_instr(MEM_WB_instruction),
    .wb_data(wb_data),
    .wb_valid(MEM_WB_valid),

    .vga_red(VGA_R),
    .vga_green(VGA_G),
    .vga_blue(VGA_B),
    .vga_hsync(VGA_HS),
    .vga_vsync(VGA_VS),
    .vga_clock(VGA_CLK)
  );

  // LEDs para debug
  assign LEDR[7:0] = pc_current[7:0];
  assign LEDR[8] = halt_detected;  // LED 8 indica HALT
  assign LEDR[9] = (br_op_display == 5'b11000);  // LED 9 indica si br_op_display tiene EBREAK
  
  // 7-Segment displays
  hex_to_7seg d0 (.hex(IF_ID_instruction[3:0]),   .seg(HEX0));
  hex_to_7seg d1 (.hex(IF_ID_instruction[7:4]),   .seg(HEX1));
  hex_to_7seg d2 (.hex(IF_ID_instruction[11:8]),  .seg(HEX2));
  hex_to_7seg d3 (.hex(IF_ID_instruction[15:12]), .seg(HEX3));

endmodule