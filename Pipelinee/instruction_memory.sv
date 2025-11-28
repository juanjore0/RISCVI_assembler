module instruction_memory (
  input  logic [31:0] address,
  input  logic [1:0]  page_select,
  output logic [31:0] instruction,
  output logic [31:0] memory_out [0:31]
);
  logic [31:0] memory [0:127];
  
  // Instrucción normal para ejecución
  assign instruction = memory[address[6:2]];

  always_comb begin
    case (page_select)
      2'b00: begin
        for (int i = 0; i < 32; i++) begin
          memory_out[i] = memory[i];
        end
      end
      2'b01: begin
        for (int i = 0; i < 32; i++) begin
          memory_out[i] = memory[32 + i];
        end
      end
      2'b10: begin
        for (int i = 0; i < 32; i++) begin
          memory_out[i] = memory[64 + i];
        end
      end
      2'b11: begin
        for (int i = 0; i < 32; i++) begin
          memory_out[i] = memory[96 + i];
        end
      end
    endcase
  end
  
  initial begin
    // Inicializar memoria en cero
    for (int i = 0; i < 128; i++) begin
      memory[i] = 32'h00000000;
    end
    
    // Cargar archivo hex
    $readmemh("instructions.hex", memory);
    
  end

endmodule