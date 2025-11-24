module registerUnit (
  input  logic [4:0]  rs1,
  input  logic [4:0]  rs2,
  input  logic [4:0]  rd, 
  input  logic        clk,
  input  logic        reset,
  input  logic        writeEnable,
  input  logic [31:0] data,
  
  output logic [31:0] rs1Data,
  output logic [31:0] rs2Data,
  output logic [31:0] registers_out [0:31]
);

  // Banco de 32 registros de 32 bits
  logic [31:0] registers[31:0];
  
  // Exponer registros para VGA
  assign registers_out = registers;

  // Lectura asíncrona (combinacional) con x0 forzado a 0
  assign rs1Data = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
  assign rs2Data = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

  // Escritura con reset ASÍNCRONO
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      // Limpiar todos los registros EXCEPTO x2
      for (int i = 0; i < 32; i++) begin
        if (i == 2)
          registers[i] <= 32'd24;  // x2 (sp) inicializado
        else
          registers[i] <= 32'd0;   // Resto en 0
      end
    end else begin
      // Operación normal: solo escribir si writeEnable está activo y rd no es x0
      if (writeEnable && rd != 5'd0)
        registers[rd] <= data;
      // NO forzar registers[0] aquí, se maneja en la lectura
    end
  end

endmodule
