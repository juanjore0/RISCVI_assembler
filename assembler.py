from lexer import RISCVLexer
from parserPrincipal import RISCVParser
from parserlabel import ParserLabel
from memory import MemoryManager

#python assembler.py programa.asm programa.hex programa.bin
def main(asm_file, hex_file, bin_file):

    memory = MemoryManager()
    #primera pasada
    label_parser = ParserLabel()
    symbol_table = label_parser.get_labels(asm_file)
    print("pass 1 complete. Symbol Table:")
    print(symbol_table)

    #segunda pasada: instrucciones
    lexer = RISCVLexer()
    parser = RISCVParser(symbol_table)

    with open(asm_file, 'r') as f:
        source_code = f.read()

    tokens = lexer.tokenize(source_code)
    ast = parser.parse(tokens)

    machine_code = []
    for instr in ast:
        if instr and instr[0].startswith("instruction_"):
            # convierto de string binario a entero
            bin_str = instr[1]
            instruction_code = int(bin_str, 2)
            machine_code.append(instruction_code)

    # Guardar resultados
    with open(hex_file, 'w') as f_hex, open(bin_file, 'w') as f_bin:
        for instruction_code in machine_code:
            f_hex.write(f"{instruction_code:08x}\n")
            f_bin.write(f"{instruction_code:032b}\n")
    
    print("\n--- Data Section ---")
    memory.dump_data()

    print(f"Assembly complete. Output files: {hex_file}, {bin_file}")


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 4:
        print("Usage: python assembler.py <input.asm> <output.hex> <output.bin>")
    else:
        main(sys.argv[1], sys.argv[2], sys.argv[3])

