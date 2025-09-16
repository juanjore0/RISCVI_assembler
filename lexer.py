import re
from sly import Lexer

class RV32ILexer(Lexer):
    # Set of supported tokens
    tokens = {
        INSTRUCTION, REGISTER, NUMBER, LABEL,
        COMMA, LPAREN, RPAREN, COMMENT, DIRECTIVE
    }

    # Palabras clave y aliases de registros
    # Mapeo de registros de alias a sus números (ej. 'zero' -> 'x0')
    aliases = {
        'zero': 'x0', 'ra': 'x1', 'sp': 'x2', 'gp': 'x3', 'tp': 'x4',
        't0': 'x5', 't1': 'x6', 't2': 'x7',
        's0': 'x8', 'fp': 'x8', 's1': 'x9',
        'a0': 'x10', 'a1': 'x11', 'a2': 'x12', 'a3': 'x13', 'a4': 'x14',
        'a5': 'x15', 'a6': 'x16', 'a7': 'x17',
        's2': 'x18', 's3': 'x19', 's4': 'x20', 's5': 'x21', 's6': 'x22',
        's7': 'x23', 's8': 'x24', 's9': 'x25', 's10': 'x26', 's11': 'x27',
        't3': 'x28', 't4': 'x29', 't5': 'x30', 't6': 'x31'
    }

    # Definición de expresiones regulares para los tokens
    # Todas las instrucciones RV32I base y pseudoinstrucciones
    instructions = [
        'lui', 'auipc', 'jal', 'jalr', 'beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu',
        'lw', 'lb', 'lh', 'lbu', 'lhu', 'sw', 'sb', 'sh',
        'addi', 'slti', 'sltiu', 'xori', 'ori', 'andi', 'slli', 'srli', 'srai',
        'add', 'sub', 'sll', 'slt', 'sltu', 'xor', 'srl', 'sra', 'or', 'and',
        'li', 'mv', 'not', 'neg', 'nop', 'la', 'ret', 'call', 'tail', 'jr', 'jalr',
        'j', 'beq', 'bne', 'beqz', 'bnez', 'bltz', 'bgez', 'blt', 'bge', 'bgt', 'ble',
        'bgtu', 'bleu', 'seqz', 'snez', 'sltz', 'sgtz'
    ]
    
    # Expresión regular para reconocer instrucciones
    INSTRUCTION = r'|'.join(instructions)

    # Expresión regular para registros (x0-x31 y sus alias)
    @_(r'(x[0-9]{1,2})|' + '|'.join(aliases.keys()))
    def REGISTER(self, t):
        if t.value in self.aliases:
            t.value = self.aliases[t.value]
        # Validar el número de registro si es 'x' seguido de un número
        if t.value.startswith('x'):
            reg_num = int(t.value[1:])
            if not 0 <= reg_num <= 31:
                raise ValueError(f"Invalid register number: {t.value}")
        return t

    # Expresión regular para números decimales y hexadecimales
    @_(r'0x[0-9a-fA-F]+|-?[0-9]+')
    def NUMBER(self, t):
        if t.value.startswith('0x'):
            t.value = int(t.value, 16)
        else:
            t.value = int(t.value)
        return t

    # Símbolos
    COMMA     = r','
    LPAREN    = r'\('
    RPAREN    = r'\)'
    
    # Comentarios y etiquetas
    @_ (r'[a-zA-Z_][a-zA-Z0-9_]*:')
    def LABEL(self, t):
        # Eliminar los dos puntos para obtener el nombre de la etiqueta
        t.value = t.value[:-1]
        return t

    @_ (r'#.*')
    def COMMENT(self, t):
        # Los comentarios no son necesarios para el parser
        pass
    
    @_ (r'\.text|\.data')
    def DIRECTIVE(self, t):
        return t

    # Ignorar espacios en blanco y tabulaciones
    ignore = ' \t'
    
    # Manejar nuevas líneas y mantener el conteo de la línea
    @_ (r'\n+')
    def newline(self, t):
        self.lineno += t.value.count('\n')

    # Manejo de errores de caracteres ilegales
    def error(self, t):
        print(f"Illegal character '{t.value[0]}' at line {self.lineno}")
        self.index += 1