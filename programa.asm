.text
main:
    addi x1, x2, 10
    lw x3, 0(x1)
    sw x3, 4(x2) # store word
    beq x1, x2, main