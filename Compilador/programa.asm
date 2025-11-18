# Programa de prueba simplificado - Todas las instrucciones base

.data
    val1: .word 100
    val2: .byte 50
    val3: .half 200

.text
main:
    # ========================================
    # TIPO R - Operaciones Registro-Registro
    # ========================================
    addi x1, zero, 20
    addi x2, zero, 10
    
    add x3, x1, x2
    sub x4, x1, x2
    and x5, x1, x2
    or x6, x1, x2
    xor x7, x1, x2
    sll x8, x1, x2
    srl x9, x1, x2
    sra x10, x1, x2
    slt x11, x1, x2
    sltu x12, x1, x2

    # ========================================
    # TIPO I - Operaciones Inmediatas
    # ========================================
    addi x13, x1, 50
    xori x14, x1, 15
    ori x15, x1, 7
    andi x16, x1, 31
    slli x17, x1, 2
    srli x18, x1, 1
    srai x19, x1, 1
    slti x20, x1, 25
    sltiu x21, x1, 25

    # ========================================
    # TIPO I - Load (con offset desde x0)
    # ========================================
    lw x22, 100(zero)
    lh x23, 104(zero)
    lhu x24, 106(zero)
    lb x25, 108(zero)
    lbu x26, 109(zero)

    # ========================================
    # TIPO S - Store
    # ========================================
    addi x27, zero, 123
    sw x27, 200(zero)
    sh x27, 204(zero)
    sb x27, 208(zero)

    # ========================================
    # TIPO B - Branch
    # ========================================
    addi x5, zero, 5
    addi x6, zero, 5
    addi x7, zero, 10
    
    beq x5, x6, l1
    addi x28, zero, 1

l1:
    bne x5, x7, l2
    addi x28, zero, 2

l2:
    blt x5, x7, l3
    addi x28, zero, 3

l3:
    bge x7, x5, l4
    addi x28, zero, 4

l4:
    bltu x5, x7, l5
    addi x28, zero, 5

l5:
    bgeu x7, x5, l6
    addi x28, zero, 6

l6:
    # ========================================
    # TIPO U - Upper Immediate
    # ========================================
    lui x29, 0x12345
    auipc x30, 0x100

    # ========================================
    # TIPO J - Jump and Link
    # ========================================
    jal x31, l7
    addi x28, zero, 99

l7:
    # ========================================
    # TIPO I - JALR
    # ========================================
    addi x5, zero, 100
    jalr x1, x5, 0

    # ========================================
    # PSEUDOINSTRUCCIONES SIMPLES
    # ========================================
    nop
    
    addi x8, zero, 42
    mv x9, x8
    not x10, x8
    neg x11, x8

    # ========================================
    # PSEUDOINSTRUCCIONES - Comparaciones
    # ========================================
    seqz x12, x8
    snez x13, x8
    sltz x14, x8
    sgtz x15, x8

    # ========================================
    # PSEUDOINSTRUCCIONES - Branch con Zero
    # ========================================
    addi x16, zero, 0
    addi x17, zero, 5
    addi x18, zero, -3
    
    beqz x16, l8
    addi x28, zero, 10

l8:
    bnez x17, l9
    addi x28, zero, 11

l9:
    blez x18, l10
    addi x28, zero, 12

l10:
    bgez x17, l11
    addi x28, zero, 13

l11:
    bltz x18, l12
    addi x28, zero, 14

l12:
    bgtz x17, l13
    addi x28, zero, 15

l13:
    # ========================================
    # PSEUDOINSTRUCCIONES - Branch extendidos
    # ========================================
    bgt x17, x16, l14
    addi x28, zero, 16

l14:
    ble x16, x17, l15
    addi x28, zero, 17

l15:
    bgtu x17, x16, l16
    addi x28, zero, 18

l16:
    bleu x16, x17, l17
    addi x28, zero, 19

l17:
    # ========================================
    # PSEUDOINSTRUCCIONES - Jump
    # ========================================
    j l18
    addi x28, zero, 20

l18:
    addi x19, zero, 50
    jr x19

l19:
    jal l20
    addi x28, zero, 21

l20:
    jal x1, subr
    addi x20, zero, 100

subr:
    addi x21, zero, 200
    ret

    # ========================================
    # PSEUDOINSTRUCCIÓN - Load Immediate
    # ========================================
    li x22, 500
    li x23, -100
    li x24, 2047
    li x25, -2048

    # ========================================
    # PSEUDOINSTRUCCIÓN - Call/Tail
    # ========================================
    call func
    tail end

func:
    addi x26, zero, 300
    ret

    # ========================================
    # TIPO SYSTEM
    # ========================================
    ecall
    ebreak

end:
    li x10, 10
    ecall
