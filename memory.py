
class MemoryManager:
    def __init__(self, base_address=0x10010000):
        self.base_address = base_address  # dirección base del segmento de datos
        self.current_address = base_address
        self.memory = {}  # dict {direccion: valor}
        self.symbol_table = {}  # diccionario de etiquetas -> dirección

    def allocate(self, label, dtype, value):
        # Define el tamaño según la directiva
        sizes = {'.byte': 1, '.half': 2, '.word': 4}
        size = sizes[dtype]

        # Guardar la dirección de la variable
        self.symbol_table[label] = self.current_address

        # Guardar el valor en memoria (simulado por bytes)
        for i in range(size):
            self.memory[self.current_address + i] = (value >> (8 * i)) & 0xFF

        # Avanzar el puntero de datos
        self.current_address += size

        return self.symbol_table[label]
