###############################################
#   PROGRAMA RISC-V CON FUNCIONES Y SHIFTS
#   Calcula promedio y clasifica números
###############################################

main:
    # Inicializar valores
    addi x10, x0, 16       # x10 = 16 (primer número)
    addi x11, x0, -8       # x11 = -8 (segundo número)
    addi x12, x0, 24       # x12 = 24 (tercer número)
    
    # Llamar a función promedio
    jal x1, promedio       # Calcula promedio, resultado en x13
    
    # Clasificar el resultado
    jal x1, clasificar     # Clasifica según rango
    
    # Probar shifts aritméticos
    jal x1, test_shifts
    
    # Terminar programa
    jal x0, fin

###############################################
# FUNCIÓN: promedio
# Calcula (x10 + x11 + x12) / 4
# Entrada: x10, x11, x12
# Salida: x13 (promedio)
###############################################
promedio:
    add x13, x10, x11      # x13 = x10 + x11
    add x13, x13, x12      # x13 = x13 + x12
    srai x13, x13, 2       # x13 = x13 >> 2 (dividir por 4, aritmético)
    jalr x0, x1, 0         # Retornar

###############################################
# FUNCIÓN: clasificar
# Clasifica x13 en rangos
# Si x13 < 0  → x14 = 1 (negativo)
# Si x13 < 10 → x14 = 2 (pequeño)
# Si x13 >= 10 → x14 = 3 (grande)
###############################################
clasificar:
    # Verificar si es negativo
    slti x15, x13, 0       # x15 = 1 si x13 < 0
    bne x15, x0, es_negativo
    
    # Verificar si es pequeño
    slti x15, x13, 10      # x15 = 1 si x13 < 10
    bne x15, x0, es_pequeno
    
    # Es grande
    addi x14, x0, 3        # x14 = 3 (grande)
    jalr x0, x1, 0         # Retornar
    
es_negativo:
    addi x14, x0, 1        # x14 = 1 (negativo)
    jalr x0, x1, 0         # Retornar
    
es_pequeno:
    addi x14, x0, 2        # x14 = 2 (pequeño)
    jalr x0, x1, 0         # Retornar

###############################################
# FUNCIÓN: test_shifts
# Prueba diferentes tipos de shifts
# Entrada: usa x10 (16) y x11 (-8)
###############################################
test_shifts:
    # Shifts con número positivo (x10 = 16)
    slli x20, x10, 1       # x20 = 16 << 1 = 32
    srli x21, x10, 2       # x21 = 16 >> 2 = 4 (lógico)
    srai x22, x10, 2       # x22 = 16 >> 2 = 4 (aritmético)
    
    # Shifts con número negativo (x11 = -8)
    srli x23, x11, 1       # x23 = 0xFFFFFFF8 >> 1 = 0x7FFFFFFC (lógico)
    srai x24, x11, 1       # x24 = -8 >> 1 = -4 (aritmético)
    
    # Comparaciones unsigned vs signed
    slt x25, x11, x10      # x25 = 1 (-8 < 16, con signo)
    sltu x26, x11, x10     # x26 = 0 (0xFFFFFFF8 > 16, sin signo)
    
    # Comparaciones con inmediatos
    slti x27, x10, 20      # x27 = 1 (16 < 20)
 
    jalr x0, x1, 0         # Retornar

###############################################
# FIN: Loop infinito
###############################################
fin:
    beq x0, x0, fin        # Loop infinito


###############################################
# VALORES ESPERADOS AL FINAL:
# x10 = 16
# x11 = -8 (0xFFFFFFF8)
# x12 = 24
# x13 = 8 (promedio: (16-8+24)/4 = 32/4 = 8)
# x14 = 2 (clasificación: pequeño, porque 8 < 10)
# x20 = 32 (16 << 1)
# x21 = 4 (16 >> 2 lógico)
# x22 = 4 (16 >> 2 aritmético)
# x23 = 0x7FFFFFFC (shift lógico de negativo)
# x24 = -4 (0xFFFFFFFC) (shift aritmético de negativo)
# x25 = 1 (comparación con signo)
# x26 = 0 (comparación sin signo)
# x27 = 1 (16 < 20)
# x28 = 0 (0xFFFFFFF8 > 5 sin signo)
###############################################