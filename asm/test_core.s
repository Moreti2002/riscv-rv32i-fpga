# test_core.s — Programa de validação do núcleo RV32I single-cycle.
# Projeto: Processador RISC-V na DE10-Lite. Autor: João Moreti.
#
# Exercita tipo-R, tipo-I, shifts, SLT, branches, load/store, LUI, AUIPC, JAL/JALR.
# Cada resultado cai num registrador conhecido para o testbench conferir.
# Termina em loop infinito (halt) em DONE.

        auipc s6, 2          # s6 = PC(0) + (2<<12) = 0x2000
        addi  t0, x0, 10     # t0 = 10
        addi  t1, x0, 3      # t1 = 3
        add   t2, t0, t1     # t2 = 13
        sub   s0, t0, t1     # s0 = 7
        and   s1, t0, t1     # s1 = 2
        or    a0, t0, t1     # a0 = 11
        xor   a1, t0, t1     # a1 = 9
        slli  a2, t1, 2      # a2 = 12
        srli  a3, t0, 1      # a3 = 5
        slti  a4, t1, 5      # a4 = 1
        slt   a5, t0, t1     # a5 = 0

        beq   t0, t0, L1     # tomado
        addi  a6, x0, 99     # pulado
L1:     addi  a6, x0, 7      # a6 = 7
        bne   t0, t1, L2     # tomado
        addi  a7, x0, 88     # pulado
L2:     addi  a7, x0, 42     # a7 = 42

        sw    t2, 0(x0)      # mem[0] = 13
        lw    s2, 0(x0)      # s2 = 13

        lui   s3, 1          # s3 = 0x1000

        jal   ra, FUNC       # chama FUNC (ra = retorno)
        addi  s5, x0, 100    # s5 = 100 (após retorno)
        beq   x0, x0, DONE

FUNC:   addi  s4, x0, 55     # s4 = 55
        ret                  # volta (jalr x0, ra, 0)

DONE:   beq   x0, x0, DONE   # halt
