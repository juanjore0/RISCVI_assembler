def main(asm_file, hex_file, bin_file):
    lexer = RV32ILexer()
    parser = RV32IParser()

    with open(asm_file, 'r') as f:
        source_code = f.read()

    try:
        # Pass 1: Build Symbol Table
        tokens = lexer.tokenize(source_code)
        parser.parse(tokens, pass_number=1, start_address=0)
        print("Pass 1 complete. Symbol Table:")
        print(parser.symbol_table)
        
        # Reset and Pass 2: Generate Machine Code
        tokens = lexer.tokenize(source_code)
        machine_code = parser.parse(tokens, pass_number=2, start_address=0)
        
        # Write outputs
        with open(hex_file, 'w') as f_hex, open(bin_file, 'w') as f_bin:
            for instruction_code in machine_code:
                # Assume instruction_code is a 32-bit integer
                hex_str = f"{instruction_code:08x}\n"
                bin_str = f"{instruction_code:032b}\n"
                f_hex.write(hex_str)
                f_bin.write(bin_str)

        print(f"Assembly complete. Output files: {hex_file}, {bin_file}")

    except Exception as e:
        print(f"Error during assembly: {e}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 4:
        print("Usage: python assembler.py <input.asm> <output.hex> <output.bin>")
    else:
        main(sys.argv[1], sys.argv[2], sys.argv[3])