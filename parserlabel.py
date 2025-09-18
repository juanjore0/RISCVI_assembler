from sly import Parser
from Lexer import RISCVLexer

count_line = 0
label_dict = {}

class parserlabel(Parser):

    # Importa los tokens definidos en tu lexer
    tokens = RISCVLexer.tokens

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

    # Regla para una línea, que puede ser una etiqueta, una instrucción o un comentario
    @_('LABEL COLON')
    def line(self, p):
        label_name = p.LABEL
        # Guarda el nombre de la etiqueta en el diccionario y el número de línea actual + 4
        global label_dict
        label_dict[label_name] = count_line
    
    @_('INS_TYPE_R REGISTER COMMA REGISTER COMMA REGISTER')
    def line(self, p):
        global count_line
        count_line = count_line + 4
    
    @_('INS_TYPE_I REGISTER COMMA REGISTER COMMA INTEGER')
    def line(self, p):
        global count_line
        count_line = count_line + 4

    @_('INS_TYPE_S REGISTER COMMA INTEGER LPAREN REGISTER RPAREN')
    def line(self, p):
        global count_line
        count_line = count_line + 4

    @_('INS_TYPE_U REGISTER COMMA INTEGER')
    def line(self, p):
        global count_line
        count_line = count_line + 4

    @_('INS_TYPE_J REGISTER COMMA LABEL')
    def line(self, p):
        global count_line
        count_line = count_line + 4

    @_('INS_TYPE_B REGISTER COMMA REGISTER COMMA LABEL')
    def line(self, p):
        global count_line
        count_line = count_line + 4
    
    @_('COMMENT')
    def line(self, p):
        pass
    
    # Regla para líneas en blanco
    @_('NEWLINE')
    def line(self, p):
        pass  

    def get_labels(self, input_file_path):
        with open(input_file_path, 'r+') as archivo:
            # Lee el contenido del archivo en una lista de líneas
            lineas = archivo.readlines()
                
            # Coloca el puntero al principio del archivo
            archivo.seek(0)
                
            # Recorre las líneas y escribe solo las no vacías
            for linea in lineas:
                if linea.strip():  # Verifica si la línea no está en blanco después de eliminar espacios en blanco
                    archivo.write(linea)
                
                # Trunca el archivo para eliminar cualquier contenido restante
                archivo.truncate() 

            lexer = RISCVLexer()                                 
            parser = parserlabel()
            temp_lines = []  # Lista temporal para almacenar líneas no etiquetas

            for linea in lineas:
                # Verifica si la línea no está en blanco después de eliminar espacios en blanco
                if linea.strip():
                    # Tokeniza la línea actual
                    tokens = lexer.tokenize(linea)
                    # Parsea los tokens generados por el Lexer
                    ast = parser.parse(tokens)
                    # Verifica si la línea es una etiqueta
                    if 'LABEL' not in [t.type for t in tokens]:
                        temp_lines.append(linea)  # Agrega la línea no etiqueta a la lista temporal

            # Reescribe el archivo con las líneas no etiquetas
            with open(input_file_path, 'w') as archivo:
                for linea in temp_lines:
                    # Verifica si la línea no comienza con una etiqueta (cadena seguida de :)
                    if not linea.strip().endswith(":"):
                        archivo.write(linea)
                
                archivo.write("\n")

        return label_dict