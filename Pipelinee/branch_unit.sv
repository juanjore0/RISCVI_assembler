// ============================================================
// branch_unit.sv - Unidad de control de saltos y branches
// ============================================================

module branch_unit (
  input  logic [31:0] rs1_data,      // Operando 1
  input  logic [31:0] rs2_data,      // Operando 2
  input  logic [4:0]  br_op,         // Señal de control de branch
  input  logic [31:0] alu_result,    // Resultado de ALU (para JALR)
  input  logic [31:0] pc_current,    // PC actual
  input  logic [31:0] immediate,     // Inmediato
  
  output logic        pc_src,        // 0 = PC+4, 1 = PC_target
  output logic [31:0] pc_target      // Dirección de salto
);

  logic branch_taken;
  logic is_branch;
  logic is_jal;
  logic is_jalr;
  logic is_system;  //  para EBREAK
  
  // Decodificar tipo de operación
  assign is_branch = (br_op[4:3] == 2'b01);  // Branches condicionales
  assign is_jal    = (br_op == 5'b10000);    // JAL
  assign is_jalr   = (br_op == 5'b10001);    // JALR
  assign is_system = (br_op[4:3] == 2'b11);  // EBREAK
  
  // Lógica de comparación para branches
  always_comb begin
    branch_taken = 1'b0;
    
    if (is_branch) begin
      case (br_op[2:0])  // funct3 del branch
        3'b000: branch_taken = (rs1_data == rs2_data);           // BEQ
        3'b001: branch_taken = (rs1_data != rs2_data);           // BNE
        3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data)); // BLT
        3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
        3'b110: branch_taken = (rs1_data < rs2_data);            // BLTU
        3'b111: branch_taken = (rs1_data >= rs2_data);           // BGEU
        default: branch_taken = 1'b0;
      endcase
    end
  end
  
  // Calcular dirección de salto
  always_comb begin
    if (is_system) begin
      // ← NUEVO: EBREAK/ECALL - Congelar PC
      pc_target = pc_current;  // Mantener PC sin cambios
      pc_src = 1'b1;           // Usar pc_target (que es igual a pc_current)
    end else if (is_jalr) begin
      // JALR: saltar a (rs1 + imm) & ~1
      pc_target = (alu_result & 32'hFFFFFFFE);
      pc_src = 1'b1;
    end else if (is_jal) begin
      // JAL: saltar a PC + imm
      pc_target = pc_current + immediate;
      pc_src = 1'b1;
    end else if (is_branch && branch_taken) begin
      // Branch tomado: PC + imm
      pc_target = pc_current + immediate;
      pc_src = 1'b1;
    end else begin
      // No saltar: PC + 4
      pc_target = pc_current + 32'd4;
      pc_src = 1'b0;
    end
  end

endmodule