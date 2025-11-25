// ============================================================
// branch_decision_unit.sv - Decide si tomar un branch/jump
// ============================================================

module branch_decision_unit (
  // Datos de los registros
  input  logic [31:0] rs1_data,
  input  logic [31:0] rs2_data,
  
  // Señales de control
  input  logic [4:0]  br_op,
  input  logic [2:0]  funct3,
  input  logic        valid,
  
  // PC y direcciones
  input  logic [31:0] pc_current,
  input  logic [31:0] immediate,
  input  logic [31:0] alu_result,  // Para JALR
  
  // Salidas
  output logic        take_branch,
  output logic [31:0] branch_target
);

  // Decodificar tipo de operación
  logic is_branch, is_jal, is_jalr;
  logic branch_condition;
  
  assign is_branch = (br_op[4:3] == 2'b01);  // Branches condicionales
  assign is_jal    = (br_op == 5'b10000);    // JAL
  assign is_jalr   = (br_op == 5'b10001);    // JALR
  
  // Evaluar condición del branch
  always_comb begin
    branch_condition = 1'b0;
    
    if (is_branch) begin
      case (funct3)
        3'b000: branch_condition = (rs1_data == rs2_data);                      // BEQ
        3'b001: branch_condition = (rs1_data != rs2_data);                      // BNE
        3'b100: branch_condition = ($signed(rs1_data) < $signed(rs2_data));    // BLT
        3'b101: branch_condition = ($signed(rs1_data) >= $signed(rs2_data));   // BGE
        3'b110: branch_condition = (rs1_data < rs2_data);                       // BLTU
        3'b111: branch_condition = (rs1_data >= rs2_data);                      // BGEU
        default: branch_condition = 1'b0;
      endcase
    end
  end
  
  // Decidir si tomar el salto y calcular dirección
  always_comb begin
    take_branch = 1'b0;
    branch_target = pc_current + 32'd4;  // Por defecto, siguiente instrucción
    
    if (valid) begin
      if (is_jalr) begin
        // JALR: saltar a (rs1 + imm) & ~1
        take_branch = 1'b1;
        branch_target = (alu_result & 32'hFFFFFFFE);
      end 
      else if (is_jal) begin
        // JAL: saltar a PC + imm
        take_branch = 1'b1;
        branch_target = pc_current + immediate;
      end 
      else if (is_branch && branch_condition) begin
        // Branch condicional tomado
        take_branch = 1'b1;
        branch_target = pc_current + immediate;
      end
    end
  end

endmodule