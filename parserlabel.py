from sly import Parser
from lexer import RISCVLexer

class ParserLabel(Parser):
    tokens = RISCVLexer.tokens

    def __init__(self):
        self.count_line = 0  # contador de PC
        self.label_dict = {}  # diccionario de etiquetas
        self.data_section = [] #variables en .data
        self.text_section = [] #instrucciones en .text

    # ----------- Reglas principales -----------

    @_('program')
    def statement(self, p):
        return p.program
    
    @_('line program')
    def program(self, p):
        return (p.line if isinstance(p.line, list) else [p.line]) + p.program

    @_('line')
    def program(self, p):
        return p.line if isinstance(p.line, list) else [p.line]

    # ----------- Reglas de línea -----------

    # Directivas - agregar regla para manejar .text y .data
    @_('DIRECTIVE')
    def line(self, p):
        return ('directive', p.DIRECTIVE)

    # Solo etiqueta con dos puntos
    @_('LABEL COLON')
    def line(self, p):
        self.label_dict[p.LABEL] = self.count_line
        return ('label', p.LABEL)

     # ----------- DATA DEFINITIONS -----------

    @_('LABEL COLON DATA_DIRECTIVE NUMBER')
    def line(self, p):
        # Ejemplo: x: .word 10
        return ('data_def', {
            'label': p.LABEL,
            'type': p.DATA_DIRECTIVE,
            'value': p.NUMBER
        })
    
    # Definición de datos con lista de números (ej. x: .word 1, 2, 3)
    @_('LABEL COLON DATA_DIRECTIVE number_list')
    def line(self, p):
        return ('data_def', {
            'label': p.LABEL,
            'type': p.DATA_DIRECTIVE,
            'value': p.number_list
        })
    
    # ----------- LISTAS DE NÚMEROS -----------

    @_('NUMBER')
    def number_list(self, p):
        return [p.NUMBER]

    @_('NUMBER COMMA number_list')
    def number_list(self, p):
        return [p.NUMBER] + p.number_list
    


    # ----------- INSTRUCCIONES BASE -----------

    # Tipo R
    @_('INSTRUCTION_TYPE_R REGISTER COMMA REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('instruction_r', p.INSTRUCTION_TYPE_R)

    # Tipo I
    @_('INSTRUCTION_TYPE_I REGISTER COMMA REGISTER COMMA NUMBER')
    def line(self, p):
        self.count_line += 4
        return ('instruction_i', p.INSTRUCTION_TYPE_I)

    # Tipo I Load
    @_('INSTRUCTION_TYPE_I_LOAD REGISTER COMMA NUMBER LPAREN REGISTER RPAREN')
    def line(self, p):
        self.count_line += 4
        return ('instruction_i', p.INSTRUCTION_TYPE_I_LOAD)

    # Tipo S
    @_('INSTRUCTION_TYPE_S REGISTER COMMA NUMBER LPAREN REGISTER RPAREN')
    def line(self, p):
        self.count_line += 4
        return ('instruction_s', p.INSTRUCTION_TYPE_S)

    # Tipo U
    @_('INSTRUCTION_TYPE_U REGISTER COMMA NUMBER')
    def line(self, p):
        self.count_line += 4
        return ('instruction_u', p.INSTRUCTION_TYPE_U)

    # Tipo J
    @_('INSTRUCTION_TYPE_J REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('instruction_j', p.INSTRUCTION_TYPE_J)

    # Tipo B
    @_('INSTRUCTION_TYPE_B REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('instruction_b', p.INSTRUCTION_TYPE_B)
    
    # TIPO I (EBREAK,ECALL)
    @_('INSTRUCTION_TYPE_I_CB')
    def line(self, p):
        self.count_line += 4
        return ('instruction_i', p.INSTRUCTION_TYPE_I_CB)

    # ----------- PSEUDOINSTRUCCIONES -----------

    # PSEUDOINSTRUCCIONES SIN OPERANDOS
    @_('NOP')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.NOP)

    @_('RET')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.RET)

    # PSEUDOINSTRUCCIONES CON DOS OPERANDOS (rd, rs)
    @_('MV REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.MV)

    @_('NOT REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.NOT)

    @_('NEG REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.NEG)

    @_('SEQZ REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.SEQZ)

    @_('SNEZ REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.SNEZ)

    @_('SLTZ REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.SLTZ)

    @_('SGTZ REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.SGTZ)

    # SALTOS CONDICIONALES CON UN OPERANDO
    @_('BEQZ REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BEQZ)

    @_('BNEZ REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BNEZ)

    @_('BLEZ REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BLEZ)

    @_('BGEZ REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BGEZ)

    @_('BLTZ REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BLTZ)

    @_('BGTZ REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BGTZ)

    # SALTOS CONDICIONALES CON DOS OPERANDOS
    @_('BGT REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BGT)

    @_('BLE REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BLE)

    @_('BGTU REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BGTU)

    @_('BLEU REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.BLEU)

    # SALTOS INCONDICIONALES
    @_('J_PSEUDO LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', 'j')

    @_('JAL_PSEUDO LABEL')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', 'jal_pseudo')

    @_('JR REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', p.JR)

    @_('JALR_PSEUDO REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('pseudo_instruction', 'jalr_pseudo')

    # Líneas vacías
    @_('NEWLINE')
    def line(self, p):
        return []

    # ----------- Método para obtener etiquetas -----------
    def get_labels(self, input_file_path):
        """
        Lee el archivo, parsea para encontrar etiquetas y devuelve el diccionario.
        """
        with open(input_file_path, 'r') as archivo:
            full_text = archivo.read()
        
        lexer = RISCVLexer()
        tokens = lexer.tokenize(full_text)
        
        # Necesitamos un nuevo analizador para la primera pasada
        parser_pass_one = ParserLabel()
        try:
            parser_pass_one.parse(tokens)
        except Exception as e:
            print(f"Error durante la primera pasada: {e}")
        
        return parser_pass_one.label_dict

    def error(self, p):
        if p is not None:
            print(f"Error sintáctico en la línea {p.lineno}: Token inesperado '{p.value}'")
        else:
            print(f"Error sintáctico: Token inesperado al final del archivo")