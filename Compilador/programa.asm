    addi x5, x0, 5      # x5 = n = 5
    addi x6, x0, 1      # x6 = res = 1

loop_fact:
    beq  x5, x0, end    # if n == 0 -> terminar

    # multiplicar res = res * n usando sumas
    addi x7, x0, 0      # x7 = acumulador = 0
    addi x8, x5, 0      # x8 = contador = n

loop_mul:
    beq  x8, x0, mul_done   # si contador == 0 -> fin multiplicación
    add  x7, x7, x6         # acumulador += res
    addi x8, x8, -1         # contador--
    jal  x0, loop_mul       # repetir

mul_done:
    addi x6, x7, 0      # res = acumulador
    addi x5, x5, -1     # n = n - 1
    jal  x0, loop_fact  # repetir factorial

end:
    addi x10, x6, 0     # a0 = resultado final (120)
    ebreak