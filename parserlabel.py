from sly import Parser
from lexer import RISCVLexer

class ParserLabel(Parser):
    tokens = RISCVLexer.tokens

    def __init__(self):
        self.count_line = 0   # contador de PC
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

    # Tipo R
    @_('INSTRUCION_TYPE_R REGISTER COMMA REGISTER COMMA REGISTER')
    def line(self, p):
        self.count_line += 4

    # Tipo I
    @_('INSTRUCION_TYPE_I REGISTER COMMA REGISTER COMMA NUMBER')
    def line(self, p):
        self.count_line += 4

    # Tipo S
    @_('INSTRUCION_TYPE_S REGISTER COMMA NUMBER LPAREN REGISTER RPAREN')
    def line(self, p):
        self.count_line += 4

    # Tipo U
    @_('INSTRUCION_TYPE_U REGISTER COMMA NUMBER')
    def line(self, p):
        self.count_line += 4

    # Tipo J
    @_('INSTRUCION_TYPE_J REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4

    # Tipo B
    @_('INSTRUCION_TYPE_B REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        self.count_line += 4

    # Comentarios
    @_('COMMENT')
    def line(self, p):
        pass

    # Línea en blanco
    @_('NEWLINE')
    def line(self, p):
        pass

    # ----------- Método para obtener etiquetas -----------
    def get_labels(self, input_file_path):
        with open(input_file_path, 'r+') as archivo:
            lineas = archivo.readlines()
            archivo.seek(0)

            # Escribir solo líneas no vacías
            for linea in lineas:
                if linea.strip():
                    archivo.write(linea)
            archivo.truncate()

        lexer = RISCVLexer()
        parser = ParserLabel()

        temp_lines = []  # almacena las líneas sin etiquetas

        for linea in lineas:
            if linea.strip():
                tokens = list(lexer.tokenize(linea))   # lista de tokens
                parser.parse(iter(tokens))             # parsea con iterador nuevo

                # Si no hay etiqueta en esa línea → guardarla
                if not any(t.type == "LABEL" for t in tokens):
                    temp_lines.append(linea)

        # Reescribir archivo sin las etiquetas
        with open(input_file_path, 'w') as archivo:
            for linea in temp_lines:
                if not linea.strip().endswith(":"):
                    archivo.write(linea)
            archivo.write("\n")

        return parser.label_dict