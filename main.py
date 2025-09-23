from lexer import RISCVLexer
from parserlabel import ParserLabel  # importa tu parser

def main():
    # Leer el código ensamblador desde archivo
    with open("test.s", "r") as f:
        code = f.read()

    # Lexer
    lexer = RISCVLexer()
    tokens = lexer.tokenize(code)

    # Parser
    parser = ParserLabel()
    result = parser.parse(tokens)

    print("===== RESULTADO FINAL =====")
    print(result)

if __name__ == "__main__":
    main()
