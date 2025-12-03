    addi x31, x0, 1      # CHK1: Inicio del programa (Si x31=1, al menos arrancó)
    addi x5, x0, 5       # x5 = n = 5
    addi x6, x0, 1       # x6 = res = 1

loop_fact:
    addi x30, x5, 0      # DEBUG: Guardar valor actual de n en x30 antes de evaluar
    beq  x5, x0, end     # if n == 0 -> terminar

    # multiplicar res = res * n usando sumas
    addi x7, x0, 0       # x7 = acumulador = 0
    addi x8, x5, 0       # x8 = contador = n
    addi x29, x0, 2      # CHK2: Entrando a loop_mul (Si x29=2, entra al bucle)

loop_mul:
    beq  x8, x0, mul_done   # si contador == 0 -> fin multiplicación
    add  x7, x7, x6         # acumulador += res
    addi x8, x8, -1         # contador--
    jal  x0, loop_mul       # repetir

mul_done:
    addi x6, x7, 0       # res = acumulador
    addi x5, x5, -1      # n = n - 1
    addi x28, x6, 0      # DEBUG: Guardar resultado parcial en x28
    jal  x0, loop_fact   # repetir factorial

end:
    addi x31, x0, 4      # CHK4: ÉXITO TOTAL (Si x31=4, terminó bien)
    addi x10, x6, 0      # a0 = resultado final (120)
    ebreak
