###############################################
#   PROGRAMA RISC-V - CÁLCULO DE FACTORIAL
#   Calcula n! de forma iterativa
###############################################

main:
    # Inicializar valores
    addi x10, x0, 5        # x10 = 5 (calcular 5!)
    addi x11, x0, 7        # x11 = 7 (calcular 7!)
    addi x12, x0, 0        # x12 = 0 (calcular 0!)
    
    # Calcular factorial de x10 (5! = 120)
    add x28, x10, x0       # Argumento: n = 5
    jal x1, factorial      # Resultado en x29
    add x13, x29, x0       # Guardar en x13
    
    # Calcular factorial de x11 (7! = 5040)
    add x28, x11, x0       # Argumento: n = 7
    jal x1, factorial      # Resultado en x29
    add x14, x29, x0       # Guardar en x14
    
    # Calcular factorial de x12 (0! = 1)
    add x28, x12, x0       # Argumento: n = 0
    jal x1, factorial      # Resultado en x29
    add x15, x29, x0       # Guardar en x15
    
    # Terminar programa
    jal x0, fin


###############################################
# FUNCIÓN: factorial
# Calcula n! de forma iterativa
# Entrada: x28 (n)
# Salida: x29 (resultado n!)
###############################################
factorial:
    # Verificar casos base (0! = 1, 1! = 1)
    slti x30, x28, 2       # x30 = 1 si n < 2
    bne x30, x0, fact_base # Si n < 2, retornar 1
    
    # Inicializar
    addi x31, x0, 1        # x31 = 1 (acumulador)
    addi x30, x0, 2        # x30 = 2 (contador)
    
fact_loop:
    # Multiplicar: x31 * x30
    add x29, x0, x0        # x29 = 0 (resultado)
    add x6, x0, x0         # x6 = 0 (índice)
    
mult_loop:
    beq x6, x30, mult_done # Si terminó, salir
    add x29, x29, x31      # x29 += x31
    addi x6, x6, 1         # x6++
    jal x0, mult_loop
    
mult_done:
    add x31, x29, x0       # Actualizar acumulador
    addi x30, x30, 1       # Incrementar contador
    slt x6, x28, x30       # Verificar si terminamos
    beq x6, x0, fact_loop  # Continuar si falta
    
    add x29, x31, x0       # Resultado final
    jalr x0, x1, 0         # Retornar
    
fact_base:
    addi x29, x0, 1        # Retornar 1
    jalr x0, x1, 0


###############################################
# FIN: Loop infinito
###############################################
fin:
    beq x0, x0, fin


###############################################
# VALORES ESPERADOS:
# x10 = 5
# x11 = 7  
# x12 = 0
# x13 = 120    (5!)
# x14 = 5040   (7!)
# x15 = 1      (0!)
###############################################
