.data
var1: .word 100       # variable de 4 bytes
var2: .byte 0x7F      # variable de 1 byte
var3: .half 300       # variable de 2 bytes

.text
main:
    # Instrucciones LOAD
    lb   x5, 0(x2)     # cargar byte con signo desde memoria
    lbu  x6, 0(x2)     # cargar byte sin signo
    lh   x7, 2(x2)     # cargar halfword con signo
    lhu  x8, 2(x2)     # cargar halfword sin signo
    lw   x9, 4(x2)     # cargar word

    # Instrucciones STORE
    sb   x5, 0(x2)     # guardar byte
    sh   x7, 2(x2)     # guardar halfword
    sw   x9, 4(x2)     # guardar word
