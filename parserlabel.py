from sly import Parser
from lexer import RISCVLexer

class ParserLabel(Parser):
    tokens = RISCVLexer.tokens

    def __init__(self):
        self.count_line = 0  # contador de PC
        self.label_dict = {}  # diccionario de etiquetas

    # ----------- Reglas principales -----------

    @_('program')
    def statement(self, p):
        return p.program

    @_('line NEWLINE program')
    def program(self, p):
        return [p.line] + p.program

    @_('line NEWLINE')
    def program(self, p):
        return [p.line]

    # ----------- Reglas de línea -----------

    # Solo etiqueta
    @_('LABEL')
    def line(self, p):
        self.label_dict[p.LABEL] = self.count_line
        return ('label', p.LABEL)

    # Tipo R
    @_('INSTRUCION_TYPE_R REGISTER COMMA REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4
        return ('instruction_r', p.INSTRUCION_TYPE_R)

    # Tipo I
    @_('INSTRUCION_TYPE_I REGISTER COMMA REGISTER COMMA NUMBER')
    def line(self, p):
        self.count_line += 4
        return ('instruction_i', p.INSTRUCION_TYPE_I)

    # Tipo I
    @_('INSTRUCION_TYPE_I_LOAD REGISTER COMMA NUMBER LPAREN REGISTER RPAREN')
    def line(self, p):
        self.count_line += 4
        return ('instruction_i', p.INSTRUCION_TYPE_I_LOAD)

    # Tipo S
    @_('INSTRUCION_TYPE_S REGISTER COMMA NUMBER LPAREN REGISTER RPAREN')
    def line(self, p):
        self.count_line += 4
        return ('instruction_s', p.INSTRUCION_TYPE_S)

    # Tipo U
    @_('INSTRUCION_TYPE_U REGISTER COMMA NUMBER')
    def line(self, p):
        self.count_line += 4
        return ('instruction_u', p.INSTRUCION_TYPE_U)

    # Tipo J
    @_('INSTRUCION_TYPE_J REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('instruction_j', p.INSTRUCION_TYPE_J)

    # Tipo B
    @_('INSTRUCION_TYPE_B REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4
        return ('instruction_b', p.INSTRUCION_TYPE_B)

    # Comentarios
    @_('COMMENT')
    def line(self, p):
        return ('comment', p.COMMENT)

    # Línea en blanco
    @_('NEWLINE')
    def line(self, p):
        return None

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
        parser_pass_one.parse(tokens)
        
        return parser_pass_one.label_dict

    def error(self, p):
        if p is not None:
            print(f"Error sintáctico en la línea {p.lineno}: Token inesperado '{p.value}'")
        else:
            print(f"Error sintáctico: Token inesperado al final del archivo")
