import os
from sly import Parser
from lexer import RISCVLexer
from diccionarios import ins_type_R, ins_type_I, ins_type_S, ins_type_U, ins_type_B, ins_type_J, Registros
from parserlabel import ParserLabel

# Variable global para el contador de línea
count_line = 0

def num_binary(numero, bits):
    """
    Convierte un número entero a su representación binaria de 'bits' de longitud.
    Maneja tanto números positivos como negativos (utilizando complemento a dos).
    """
    if numero >= 0:
        return bin(numero)[2:].zfill(bits)
    else:
        # Complemento a dos para números negativos
        return bin(2**bits + numero)[2:]

class RISCVParser(Parser):
    tokens = RISCVLexer.tokens

    def __init__(self, label_dict):
        super().__init__()
        self.label_dict = label_dict

    # Reglas para un programa completo
    @_('line program')
    def program(self, p):
        return [p.line] + p.program

    @_('line')
    def program(self, p):
        return [p.line]
    
    # Reglas para una sola línea (instrucción, etiqueta o comentario)
    @_('LABEL COLON')
    def line(self, p):
        return ('label', p.LABEL)
        
    @_('INSTRUCION_TYPE_R REGISTER COMMA REGISTER COMMA REGISTER')
    def line(self, p):
        global count_line
        ins_info = ins_type_R[p.INSTRUCION_TYPE_R]
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        rs2 = Registros(p.REGISTER2)
        binary_instruction = f"{ins_info['funct7']}{rs2}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_r', binary_instruction)
    
    @_('INSTRUCION_TYPE_I REGISTER COMMA REGISTER COMMA NUMBER')
    def line(self, p):
        global count_line
        ins_info = ins_type_I[p.INSTRUCION_TYPE_I]
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        imm = num_binary(int(p.NUMBER), 12)
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)
    
    @_('INSTRUCION_TYPE_I_LOAD REGISTER COMMA NUMBER LPAREN REGISTER RPAREN')
    def line(self, p):
        global count_line
        ins_info = ins_type_I[p.INSTRUCION_TYPE_I_LOAD]
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        imm = num_binary(int(p.NUMBER), 12)
        binary_instruction = f"{imm}{rs1}{ins_info['funct3']}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_i', binary_instruction)
    
    @_('INSTRUCION_TYPE_S REGISTER COMMA NUMBER LPAREN REGISTER RPAREN')
    def line(self, p):
        global count_line
        ins_info = ins_type_S[p.INSTRUCION_TYPE_S]
        rs1 = Registros(p.REGISTER1)
        rs2 = Registros(p.REGISTER0)
        imm = num_binary(int(p.NUMBER), 12)
        imm_high = imm[:7]  # Bits 11 a 5
        imm_low = imm[7:]   # Bits 4 a 0
        binary_instruction = f"{imm_high}{rs2}{rs1}{ins_info['funct3']}{imm_low}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_s', binary_instruction)
    
    @_('INSTRUCION_TYPE_U REGISTER COMMA NUMBER')
    def line(self, p):
        global count_line
        ins_info = ins_type_U[p.INSTRUCION_TYPE_U]
        rd = Registros(p.REGISTER)
        imm = num_binary(int(p.NUMBER), 20)
        binary_instruction = f"{imm}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_u', binary_instruction)
    
    @_('INSTRUCION_TYPE_B REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        global count_line
        ins_info = ins_type_B[p.INSTRUCION_TYPE_B]
        rs1 = Registros(p.REGISTER0)
        rs2 = Registros(p.REGISTER1)
        offset = self.label_dict[p.LABEL] - count_line
        imm = num_binary(offset, 13)
        # Extraer los bits del inmediato para el formato B
        imm12 = imm[0]
        imm11 = imm[1]
        imm10_5 = imm[2:8]
        imm4_1 = imm[8:12]
        
        binary_instruction = f"{imm12}{imm10_5}{rs2}{rs1}{ins_info['funct3']}{imm4_1}{imm11}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_b', binary_instruction)
    
    @_('INSTRUCION_TYPE_J REGISTER COMMA LABEL')
    def line(self, p):
        global count_line
        ins_info = ins_type_J[p.INSTRUCION_TYPE_J]
        rd = Registros(p.REGISTER)
        offset = self.label_dict[p.LABEL] - count_line
        imm = num_binary(offset, 21)
        # Extraer los bits del inmediato para el formato J
        imm20 = imm[0]
        imm10_1 = imm[10:20]
        imm11 = imm[9]
        imm19_12 = imm[1:9]
        
        binary_instruction = f"{imm20}{imm10_1}{imm11}{imm19_12}{rd}{ins_info['opcode']}"
        count_line += 4
        return ('instruction_j', binary_instruction)

    @_('COMMENT')
    def line(self, p):
        return ('comment', p.COMMENT)

    @_('NEWLINE')
    def line(self, p):
        return None

    def error(self, p):
        if p is not None:
            print(f"Error sintáctico en la línea {p.lineno}: Token inesperado '{p.value}'")
        else:
            print(f"Error sintáctico: Token inesperado al final del archivo")

if __name__ == '__main__':
    label_parser = ParserLabel()
    input_file_path = 'archivo.s48'
    output_file_path = 'instrucciones.txt'
    
    # Restablecer count_line antes de la primera pasada
    count_line = 0
    dict_label = label_parser.get_labels(input_file_path)

    lexer = RISCVLexer()
    parser = RISCVParser(dict_label)

    # Procesar todo el archivo a la vez
    with open(input_file_path, 'r') as archivo:
        full_text = archivo.read()
    
    ast = parser.parse(lexer.tokenize(full_text))

    if ast is not None:
        instrucciones = ast
    else:
        instrucciones = []

    with open(output_file_path, 'w') as output_file:
        for instruccion in instrucciones:
            if instruccion is not None:
                if instruccion[0] in ('instruction_r', 'instruction_i', 'instruction_s', 'instruction_u', 'instruction_b', 'instruction_j'):
                    output_file.write(f"{instruccion[1]}\n")
                    print(f"{instruccion[1]}")

        print(f"Total de instrucciones: {count_line // 4}")
        if count_line // 4 < 1024:
            for i in range((1024 - count_line // 4)):
                if (i == (1024 - count_line // 4) - 1):
                    output_file.write(f"00000000000000000000000000000000")
                else:
                    output_file.write(f"00000000000000000000000000000000\n")

    print(f"Instrucciones guardadas en {output_file_path}")
    print("Diccionario de Etiquetas:")
    for label, line_number in dict_label.items():
        print(f"{label}: {line_number}")