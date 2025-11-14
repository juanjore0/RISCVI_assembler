module immediate_generator (
  input  logic [31:0] instruction,
  input  logic [2:0]  imm_src,
  
  output logic [31:0] immediate
);

  always_comb begin
    case (imm_src)
      3'b000: // Tipo I (ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
        immediate = {{20{instruction[31]}}, instruction[31:20]};
		      
		  3'b001: // Tipo S (STORE) 
        // imm[11:5] = instruction[31:25]
        // imm[4:0]  = instruction[11:7]
        immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

      3'b010: // Tipo B (BRANCHES: BEQ, BNE, BLT, BGE, BLTU, BGEU)
        // imm[12|10:5] = instruction[31:25]
        // imm[4:1|11]  = instruction[11:7]
        // bit 0 siempre es 0 (alineación)
        immediate = {{19{instruction[31]}}, instruction[31], instruction[7], 
                     instruction[30:25], instruction[11:8], 1'b0};
      
      3'b011: // Tipo J (JAL)
        // imm[20|10:1|11|19:12] de instruction[31:12]
        immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
                     instruction[20], instruction[30:21], 1'b0};
      
      3'b100: // Tipo U (LUI, AUIPC)
        // imm[31:12] = instruction[31:12], bits [11:0] = 0
        immediate = {instruction[31:12], 12'b0};

      default:
        immediate = 32'd0;
    endcase
  end

endmodule