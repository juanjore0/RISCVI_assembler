module immediate_generator (
  input  logic [31:0] instruction,
  input  logic [2:0]  imm_src,
  input  logic [6:0]  opcode,      // detectar shifts
  input  logic [2:0]  funct3,      // detectar shifts
  
  output logic [31:0] immediate
);

  always_comb begin
    case (imm_src)
      3'b000: begin // Tipo I
        // Detectar si es una instrucción de shift inmediato
        // Opcode 0010011 = operaciones inmediatas
        // funct3 = 001 (SLLI) o 101 (SRLI/SRAI)
        if (opcode == 7'b0010011 && (funct3 == 3'b001 || funct3 == 3'b101)) begin
          // Para shifts: solo usar bits [24:20] como shamt (shift amount)
          // NO extender signo, solo 5 bits válidos (0-31)
          immediate = {27'b0, instruction[24:20]};
        end else begin
          // Para otras instrucciones tipo I: extensión de signo normal
          // (ADDI, SLTI, XORI, ORI, ANDI, loads, JALR)
          immediate = {{20{instruction[31]}}, instruction[31:20]};
        end
      end
		      
      3'b001: // Tipo S (STORE) 
        // imm[11:5] = instruction[31:25]
        // imm[4:0]  = instruction[11:7]
        immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

      3'b010: // Tipo B (BRANCHES: BEQ, BNE, BLT, BGE, BLTU, BGEU)
        // imm[12|10:5] = instruction[31:25]
        // imm[4:1|11]  = instruction[11:7]
        // bit 0 siempre es 0 (alineación)
        immediate = {{20{instruction[31]}}, instruction[7], 
                     instruction[30:25], instruction[11:8], 1'b0};
      
      3'b011: // Tipo J (JAL)
        // imm[20|10:1|11|19:12] de instruction[31:12]
        immediate = {{12{instruction[31]}}, instruction[19:12], 
                     instruction[20], instruction[30:21], 1'b0};
      
      3'b100: // Tipo U (LUI, AUIPC)
        // imm[31:12] = instruction[31:12], bits [11:0] = 0
        immediate = {instruction[31:12], 12'b0};

      default:
        immediate = 32'd0;
    endcase
  end

endmodule