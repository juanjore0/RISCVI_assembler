import os
from sly import Parser
from Lexer import RISCVLexer
from diccionarios import ins_type_R, ins_type_I, ins_type_S, ins_type_U, ins_type_B, ins_type_J, Registros
from parserlabel import parserlabel

count_line = 0

def offsen(label_name, label_dict):
    offset = label_dict[label_name] - count_line
    return offset

def numbits(offset, bits):
    if offset >= 0:
        return format(offset, f'0{bits}b')
    else:
        num = format(offset * -1, f'0{bits}b')
        num = num.replace('0', '2')
        num = num.replace('1', '0')
        num = num.replace('2', '1')
        num = int(num, 2) + 1
        return format(num, f'0{bits}b')

def num_binary(numero, bits):
    if numero >= 0:
        binary = bin(numero)[2:].zfill(bits)
    else:
        binary = bin(2**bits + numero)[2:]
    return binary

class RISCVParser(Parser):

    # Importa los tokens definidos en tu lexer
    tokens = RISCVLexer.tokens

    def __init__(self, label_dict):
        super().__init__()
        self.label_dict = label_dict  # Usa el diccionario de etiquetas que proviene del primer parser

    # Regla inicial
    @_('program')
    def statement(self, p):
        return p.program

    # Regla para un programa, que puede contener múltiples líneas
    @_('line NEWLINE program')
    def program(self, p):
        return [p.line] + p.program

    @_('line NEWLINE')
    def program(self, p):
        return [p.line]
    
    @_('NEWLINE program')
    def program(self, p):
        return [p.NEWLINE] + p.program

    #Regla para una línea, que puede ser una etiqueta, una instrucción o un comentario
    @_('LABEL')
    def line(self, p):
        return ('label', p.LABEL)
    
    @_('INS_TYPE_R REGISTER COMMA REGISTER COMMA REGISTER')
    def line(self, p):
        ins_info = ins_type_R[p.INS_TYPE_R]
        opcode = ins_info['opcode']
        funct3 = ins_info['funct3']
        funct7 = ins_info['funct7']
        rd = Registros(p.REGISTER0)    
        rs1 = Registros(p.REGISTER1)
        rs2 = Registros(p.REGISTER2)
        binary_instruction = f"{funct7}{rs2}{rs1}{funct3}{rd}{opcode}"
        global count_line
        count_line = count_line + 4
        return ('instruction_r',binary_instruction)
    
    @_('INS_TYPE_I REGISTER COMMA REGISTER COMMA INTEGER')
    def line(self, p):
        ins_info = ins_type_I[p.INS_TYPE_I]
        opcode = ins_info['opcode']
        funct3 = ins_info['funct3']
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        #imm = format(int(p.INTEGER), '012b')  
        imm = num_binary(int(p.INTEGER), 12)
        binary_instruction = f"{imm}{rs1}{funct3}{rd}{opcode}"
        global count_line
        count_line = count_line + 4
        return ('instruction_i',binary_instruction)
    
    @_('INS_TYPE_I_LOAD REGISTER COMMA INTEGER LPAREN REGISTER RPAREN')
    def line(self, p):
        ins_info = ins_type_I[p.INS_TYPE_I_LOAD]
        opcode = ins_info['opcode']
        funct3 = ins_info['funct3']
        rd = Registros(p.REGISTER0)
        rs1 = Registros(p.REGISTER1)
        #imm = format(int(p.INTEGER), '012b')  
        imm = num_binary(int(p.INTEGER), 12)
        binary_instruction = f"{imm}{rs1}{funct3}{rd}{opcode}"
        global count_line
        count_line = count_line + 4
        return ('instruction_i',binary_instruction)
    
    @_('INS_TYPE_S REGISTER COMMA INTEGER LPAREN REGISTER RPAREN')
    def line(self, p):
        ins_info = ins_type_S[p.INS_TYPE_S]
        opcode = ins_info['opcode']
        funct3 = ins_info['funct3']
        rs1 = Registros(p.REGISTER1)
        rs2 = Registros(p.REGISTER0)
        #imm = format(int(p.INTEGER), '012b')  
        imm = num_binary(int(p.INTEGER), 12)
        imm1 = imm[7:]
        imm2 = imm[:7]
        binary_instruction = f"{imm2}{rs2}{rs1}{funct3}{imm1}{opcode}"
        global count_line
        count_line = count_line + 4
        return ('instruction_s',binary_instruction)
    
    @_('INS_TYPE_U REGISTER COMMA INTEGER')
    def line(self, p):
        ins_info = ins_type_U[p.INS_TYPE_U]
        opcode = ins_info['opcode']
        rd = Registros(p.REGISTER)
        #imm = format(int(p.INTEGER), '020b')  
        imm = num_binary(int(p.INTEGER), 20)
        binary_instruction = f"{imm}{rd}{opcode}"
        global count_line
        count_line = count_line + 4
        return ('instruction_u',binary_instruction)
    
    @_('INS_TYPE_B REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        ins_info = ins_type_B[p.INS_TYPE_B]
        opcode = ins_info['opcode']
        funct3 = ins_info['funct3']
        rs1 = Registros(p.REGISTER0)
        rs2 = Registros(p.REGISTER1)
        offset = offsen(p.LABEL, self.label_dict)
        imm = numbits(offset, 13)
        imm12 = imm[0]
        imm11 = imm[1]
        imm10 = imm[2]
        imm9 = imm[3]
        imm8 = imm[4]
        imm7 = imm[5]
        imm6 = imm[6]
        imm5 = imm[7]
        imm4 = imm[8]
        imm3 = imm[9]
        imm2 = imm[10]
        imm1 = imm[11]
        binary_instruction = f"{imm12}{imm10}{imm9}{imm8}{imm7}{imm6}{imm5}{rs2}{rs1}{funct3}{imm4}{imm3}{imm2}{imm1}{imm11}{opcode}"
        global count_line
        count_line += 4
        return ('instruction_b', binary_instruction)
    
    @_('INS_TYPE_J REGISTER COMMA LABEL')
    def line(self, p):
        ins_info = ins_type_J[p.INS_TYPE_J]
        opcode = ins_info['opcode']
        rd = Registros(p.REGISTER)
        offset = offsen(p.LABEL, self.label_dict)
        imm = numbits(offset, 21)
        imm20 = imm[0]
        imm19 = imm[1]
        imm18 = imm[2]
        imm17 = imm[3]
        imm16 = imm[4]
        imm15 = imm[5]
        imm14 = imm[6]
        imm13 = imm[7]
        imm12 = imm[8]
        imm11 = imm[9]
        imm10 = imm[10]
        imm9 = imm[11]
        imm8 = imm[12]
        imm7 = imm[13]
        imm6 = imm[14]
        imm5 = imm[15]
        imm4 = imm[16]
        imm3 = imm[17]
        imm2 = imm[18]
        imm1 = imm[19]
        binary_instruction = f"{imm20}{imm10}{imm9}{imm8}{imm7}{imm6}{imm5}{imm4}{imm3}{imm2}{imm1}{imm11}{imm19}{imm18}{imm17}{imm16}{imm15}{imm14}{imm13}{imm12}{rd}{opcode}"
        global count_line
        count_line += 4
        return ('instruction_j', binary_instruction)

    @_('COMMENT')
    def line(self, p):
        return ('comment', p.COMMENT)
    
    # Ignorar líneas en blanco
    @_('NEWLINE')
    def line(self, p):
        return None  # Retorna None para líneas en blanco 

    def error(self, p):
        if p is not None:
            print(f"Error sintáctico en la línea {p.lineno}: Token inesperado '{p.value}'")
        else:
            print(f"Error sintáctico: Token inesperado al final del archivo")

if __name__ == '__main__':

    label_parser = parserlabel()
    input_file_path = 'archivo.s48'
    output_file_path = 'instrucciones.txt'
    dict_label = label_parser.get_labels(input_file_path)

    with open(input_file_path, 'r') as archivo:
        lineas = archivo.readlines()

    lexer = RISCVLexer()                                 
    parser = RISCVParser(dict_label)

    # Crear una lista para almacenar las instrucciones
    instrucciones = []

    for linea in lineas:                              
        ast = parser.parse(lexer.tokenize(linea))
        
        if ast is not None:
            instrucciones.extend(ast)

    # Abre el archivo de salida en modo escritura
    with open(output_file_path, 'w') as output_file:
        for instruccion in instrucciones:
            if instruccion is not None:
                if instruccion[0] in ('instruction_r', 'instruction_i', 'instruction_s', 'instruction_u', 'instruction_b', 'instruction_j'):
                    output_file.write(f"{instruccion[1]}\n")
                    print(f"{instruccion[1]}")

        print(f"Total de instrucciones: {count_line // 4}")
        if count_line // 4 < 1024:
            for i in range((1024 - count_line // 4)):
                if(i == (1024 - count_line // 4)-1):
                    output_file.write(f"00000000000000000000000000000000")
                else:
                    output_file.write(f"00000000000000000000000000000000\n")

    # Cierra el archivo de salida
    print(f"Instrucciones guardadas en {output_file_path}")

    # Imprime el diccionario de etiquetas
    print("Diccionario de Etiquetas:")
    for label, line_number in dict_label.items():
        print(f"{label}: {line_number}")