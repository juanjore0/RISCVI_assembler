// ============================================================
// forwarding_unit.sv - Maneja data forwarding (bypassing)
// ============================================================

module forwarding_unit(
  // Señales de la instrucción en EX stage
  input  logic [4:0] ex_rs1,
  input  logic [4:0] ex_rs2,
  
  // Señales de la instrucción en MEM stage
  input  logic [4:0] mem_rd,
  input  logic       mem_regwrite,
  input  logic       mem_valid,
  
  // Señales de la instrucción en WB stage
  input  logic [4:0] wb_rd,
  input  logic       wb_regwrite,
  input  logic       wb_valid,
  
  // Salidas de control de forwarding
  output logic [1:0] forward_a,  // Para rs1
  output logic [1:0] forward_b   // Para rs2
);

  always_comb begin
    // Forward A: para RS1
    // Prioridad: MEM > WB (más reciente primero)
    if (mem_regwrite && mem_valid && (mem_rd != 5'd0) && (mem_rd == ex_rs1))
      forward_a = 2'b10;  // Forward desde MEM
    else if (wb_regwrite && wb_valid && (wb_rd != 5'd0) && (wb_rd == ex_rs1))
      forward_a = 2'b01;  // Forward desde WB
    else
      forward_a = 2'b00;  // No forward (usar valor del register file)

    // Forward B: para RS2
    if (mem_regwrite && mem_valid && (mem_rd != 5'd0) && (mem_rd == ex_rs2))
      forward_b = 2'b10;  // Forward desde MEM
    else if (wb_regwrite && wb_valid && (wb_rd != 5'd0) && (wb_rd == ex_rs2))
      forward_b = 2'b01;  // Forward desde WB
    else
      forward_b = 2'b00;  // No forward
  end

endmodule