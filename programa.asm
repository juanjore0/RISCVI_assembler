.text
main:
    nop             # debería convertirse en addi x0, x0, 0
    mv x6, x5       # debería convertirse en addi x6, x5, 0
    not x7, x6      # debería convertirse en xori x7, x6, -1
    neg x8, x7      # debería convertirse en sub x8, x0, x7
    seqz x9, x8     # debería convertirse en sltiu x9, x8, 1
    snez x10, x9    # debería convertirse en sltu x10, x0, x9
    sltz x11, x10   # debería convertirse en slt x11, x10, x0
    sgtz x12, x11   # debería convertirse en slt x12, x0, x11

    beqz x5, etiqueta   # debería convertirse en beq x5, x0, etiqueta
    bnez x6, etiqueta   # debería convertirse en bne x6, x0, etiqueta
    blez x7, etiqueta   # debería convertirse en bge x0, x7, etiqueta
    bgez x8, etiqueta   # debería convertirse en bge x8, x0, etiqueta
    bltz x9, etiqueta   # debería convertirse en blt x9, x0, etiqueta
    bgtz x10, etiqueta  # debería convertirse en blt x0, x10, etiqueta

    j etiqueta      # debería convertirse en jal x0, etiqueta
    ret             # debería convertirse en jalr x0, x1, 0

etiqueta:
    ecall           # syscall para terminar
