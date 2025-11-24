module instruction_memory (
  input  logic [31:0] address,
  output logic [31:0] instruction
);
  logic [31:0] memory [0:127];
  
  assign instruction = memory[address[6:2]];
  
  initial begin
    // Cargar desde archivo .hex
    $readmemh("instructions.hex", memory);
  end

endmodule