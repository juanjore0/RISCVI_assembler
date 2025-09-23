.data
var1: .word 100       # variable de 4 bytes (word)
var2: .byte 0x7F      # variable de 1 byte
var3: .half 300       # variable de 2 bytes (halfword)

.text
main:
    # ---- LOADS ----
    la   x10, var1        # cargar dirección de var1
    lw   x5, 0(x10)       # x5 = contenido de var1 (100)

    la   x11, var2        # cargar dirección de var2
    lb   x6, 0(x11)       # x6 = contenido de var2 (0x7F con signo)

    la   x12, var3        # cargar dirección de var3
    lh   x7, 0(x12)       # x7 = contenido de var3 (300 con signo)

    # ---- STORES ----
    li   x8, 200          # cargar inmediato en x8
    sw   x8, 0(x10)       # var1 = 200

    li   x9, -1
    sb   x9, 0(x11)       # var2 = -1 (0xFF)

    li   x13, 1234
    sh   x13, 0(x12)      # var3 = 1234

    # salir del programa (ecall en RARS)
    li   a7, 10
    ecall
