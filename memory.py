import struct

class MemoryManager:
    def __init__(self, base_addr=0x10010000):
       
        self.base_addr = base_addr
        self.memory = {}
        self.current_addr = base_addr

    # ======================
    # --- MANEJO DE DATA ---
    # ======================
    def add_data(self, label, dtype, value):
        """
        Agrega variables a la sección .data
        dtype puede ser: '.word', '.half', '.byte'
        """
        # Guardar en memoria
        if dtype == ".word":
            size = 4
        elif dtype == ".half":
            size = 2
        elif dtype == ".byte":
            size = 1
        else:
            raise ValueError(f"Tipo de dato no soportado: {dtype}")

         # Guardar en memoria
        self.memory[label] = {
            "addr": self.current_addr,
            "type": dtype,
            "value": value
        }

        self.current_addr += size
    
        print(f"[.data] {label}: {dtype} {value} almacenado en{hex(addr)} with value {value}")

    def dump_data(self):
        for label, info in self.memory.items():
            print(f"{label} ({info['type']}): addr={hex(info['addr'])}, value={info['value']}")