// ============================================================
// hazard_detection_unit.sv - Detecta hazards y genera stalls
// ============================================================

module hazard_detection_unit (
  // Señales de la instrucción en ID stage
  input  logic [4:0]  id_rs1,
  input  logic [4:0]  id_rs2,
  
  // Señales de la instrucción en EX stage
  input  logic [4:0]  ex_rd,
  input  logic [1:0]  ex_ru_data_src,  // 2'b01 = Load
  input  logic        ex_valid,
  
  // Señales de control de branches
  input  logic [4:0]  ex_br_op,
  input  logic        take_branch,
  
  // Salidas de control
  output logic        stall_pipeline,
  output logic        flush_if_id,
  output logic        flush_id_ex,
  output logic        pc_write_enable
);

  // Detección de Load-Use Hazard
  logic load_use_hazard;
  
  always_comb begin
    // Load-Use Hazard ocurre cuando:
    // 1. Hay un LOAD en EX stage (ex_ru_data_src == 2'b01)
    // 2. La instrucción en ID necesita el registro destino del load
    load_use_hazard = (ex_ru_data_src == 2'b01) &&  // Es un LOAD
                      ex_valid &&                     // Instrucción válida
                      (((ex_rd == id_rs1) && (id_rs1 != 5'd0)) ||
                       ((ex_rd == id_rs2) && (id_rs2 != 5'd0)));
  end
  
  // Control de stalls y flushes
  assign stall_pipeline = load_use_hazard;
  assign pc_write_enable = !stall_pipeline;
  assign flush_if_id = take_branch;
  assign flush_id_ex = stall_pipeline || take_branch;

endmodule