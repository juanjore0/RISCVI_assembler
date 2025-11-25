module control_unit (
  input  logic [6:0] opcode,
  input  logic [2:0] funct3,
  input  logic [6:0] funct7,
  
  output logic       ru_write,
  output logic [3:0] alu_op,
  output logic [2:0] imm_src,
  output logic [1:0] alu_a_src,
  output logic       alu_b_src,
  output logic       dm_write,
  output logic [2:0] dm_ctrl,
  output logic [4:0] br_op,
  output logic [1:0] ru_data_src
);

  always_comb begin
    // Valores por defecto
    ru_write     = 1'b0;
    alu_op       = 4'b0000;
    imm_src      = 3'b000;
    alu_a_src    = 2'b00;
    alu_b_src    = 1'b0;
    dm_write     = 1'b0;
    dm_ctrl      = 3'b000;
    br_op        = 5'b00000;
    ru_data_src  = 2'b00;
    
    case (opcode)
      7'b0110011: begin // Tipo R
        ru_write     = 1'b1;
        alu_op       = {funct7[5], funct3};
        imm_src      = 3'bxxx;
        alu_a_src    = 2'b00;
        alu_b_src    = 1'b0;
        dm_write     = 1'b0;
        dm_ctrl      = 3'bxxx;
        br_op        = 5'b00000;
        ru_data_src  = 2'b00;
      end
      
      7'b0010011: begin // Tipo I (Operaciones inmediatas)
        ru_write     = 1'b1;
        imm_src      = 3'b000;
        alu_a_src    = 2'b00;
        alu_b_src    = 1'b1;
        dm_write     = 1'b0;
        dm_ctrl      = 3'bxxx;
        br_op        = 5'b00000;
        ru_data_src  = 2'b00;
        
        // Diferenciar shifts de otras operaciones
        case (funct3)
          3'b001, 3'b101: // SLLI, SRLI/SRAI (shifts usan funct7[5])
            alu_op = {funct7[5], funct3};
          default: // ADDI, SLTI, SLTIU, XORI, ORI, ANDI (no usan funct7[5])
            alu_op = {1'b0, funct3};
        endcase
      end
      
      7'b0000011: begin // Tipo I (Load)
        ru_write     = 1'b1;
        alu_op       = 4'b0000; // ADD
        imm_src      = 3'b000;
        alu_a_src    = 2'b00;
        alu_b_src    = 1'b1;
        dm_write     = 1'b0;
        dm_ctrl      = funct3;
        br_op        = 5'b00000;
        ru_data_src  = 2'b01;
      end
		
		  7'b0100011: begin // TIPO S (Store)
		    ru_write     = 1'b0;    // NO escribir en registros
        alu_op       = 4'b0000; // ADD (calcular dirección)
        imm_src      = 3'b001;  // Inmediato tipo S
        alu_a_src    = 2'b00;   // rs1 (registro base)
        alu_b_src    = 1'b1;    // Usar inmediato (offset)
        dm_write     = 1'b1;    // SÍ escribir en memoria
        dm_ctrl      = funct3;  // Control según tipo de store (SB, SH, SW)
        br_op        = 5'b00000;
        ru_data_src  = 2'bxx;   // No importa, no escribimos en registros
      end

      7'b1100011: begin // Tipo B (Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU)
		  ru_write     = 1'b0;    // NO escribir en registros
		  alu_op       = 4'b0000; // ✓ ADD (para calcular PC + immediate)
		  imm_src      = 3'b010;  // ✓ Inmediato tipo B
		  alu_a_src    = 2'b01;   // ✓ CAMBIO: Usar PC como operando A
		  alu_b_src    = 1'b1;    // ✓ CAMBIO: Usar immediate como operando B
		  dm_write     = 1'b0;    // NO escribir en memoria
		  dm_ctrl      = 3'b000;  // No importa
		  br_op        = {2'b01, funct3}; // Activar branch + tipo según funct3
		  ru_data_src  = 2'b00;   // No importa
		end
          
      7'b1101111: begin // JAL (Jump And Link)
        ru_write     = 1'b1;    // SÍ escribir en rd (dirección de retorno)
        alu_op       = 4'b0000; // ADD (PC + imm)
        imm_src      = 3'b011;  // Inmediato tipo J
        alu_a_src    = 2'b01;   // PC como operando A
        alu_b_src    = 1'b1;    // Inmediato como operando B
        dm_write     = 1'b0;
        dm_ctrl      = 3'b000;
        br_op        = 5'b10000; // Jump incondicional
        ru_data_src  = 2'b10;   // PC+4 (dirección de retorno)
      end

      7'b1100111: begin // JALR (Jump And Link Register)
        ru_write     = 1'b1;    // SÍ escribir en rd (dirección de retorno)
        alu_op       = 4'b0000; // ADD (rs1 + imm)
        imm_src      = 3'b000;  // Inmediato tipo I
        alu_a_src    = 2'b00;   // rs1 como operando A
        alu_b_src    = 1'b1;    // Inmediato como operando B
        dm_write     = 1'b0;
        dm_ctrl      = 3'bxxx;
        br_op        = 5'b10001; // Jump incondicional desde registro
        ru_data_src  = 2'b10;   // PC+4 (dirección de retorno)
      end

      7'b0110111: begin // LUI (Load Upper Immediate)
        ru_write     = 1'b1;    // SÍ escribir en rd
        alu_op       = 4'bxxxx; // ALU no se usa
        imm_src      = 3'b100;  // Inmediato tipo U
        alu_a_src    = 2'bxx;   // No importa
        alu_b_src    = 1'bx;    // No importa
        dm_write     = 1'b0;    // NO escribir en memoria
        dm_ctrl      = 3'bxxx;  // No importa
        br_op        = 5'b00000;
        ru_data_src  = 2'b11;   // Escribir directamente el inmediato
      end
      
      7'b0010111: begin // AUIPC (Add Upper Immediate to PC)
        ru_write     = 1'b1;    // SÍ escribir en rd
        alu_op       = 4'b0000; // ADD
        imm_src      = 3'b100;  // Inmediato tipo U
        alu_a_src    = 2'b01;   // Usar PC como operando A
        alu_b_src    = 1'b1;    // Usar inmediato como operando B
        dm_write     = 1'b0;    // NO escribir en memoria
        dm_ctrl      = 3'bxxx;  // No importa
        br_op        = 5'b00000;
        ru_data_src  = 2'b00;   // Resultado de ALU (PC + imm)
      end		

      7'b1110011: begin // SYSTEM (EBREAK)
        ru_write     = 1'b0;    // NO escribir en registros
        alu_op       = 4'bxxxx;
        imm_src      = 3'b000;
        alu_a_src    = 2'bxx;
        alu_b_src    = 1'bx;
        dm_write     = 1'b0;
        dm_ctrl      = 3'bxxx;
        br_op        = 5'b11000; // System call
        ru_data_src  = 2'bxx;
      end    
      
      default: begin
        ru_write     = 1'b0;
        alu_op       = 4'b0000;
        imm_src      = 3'b000;
        alu_a_src    = 2'b00;
        alu_b_src    = 1'b0;
        dm_write     = 1'b0;
        dm_ctrl      = 3'b000;
        br_op        = 5'b00000;
        ru_data_src  = 2'b00;
      end
    endcase
  end

endmodule