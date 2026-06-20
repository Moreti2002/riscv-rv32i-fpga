# calc.s — Calculadora: programa RISC-V que roda no próprio processador.
# Projeto: Processador RISC-V na DE10-Lite. Autor: João Moreti.
#
# Entradas pelas chaves (lidas em 0x2000):
#   SW[3:0] = operando A (0..15)
#   SW[7:4] = operando B (0..15)
#   SW[9:8] = operação:  00=A+B  01=A-B  10=A&B  11=A|B
# Saídas:
#   0x2020 = resultado (exibido em decimal com sinal nos 6 HEX)
#   0x2010 = LEDR (mostra o código da operação nos LEDs baixos)
#
# Laço infinito: lê chaves, calcula, mostra. KEY0 reinicia (reset físico).

        lui   t0, 2              # t0 = 0x2000 (base de I/O)
loop:
        lw    t1, 0(t0)          # t1 = SW
        andi  a0, t1, 0xF        # a0 = A = SW[3:0]
        srli  t2, t1, 4
        andi  a1, t2, 0xF        # a1 = B = SW[7:4]
        srli  t3, t1, 8
        andi  t3, t3, 0x3        # t3 = op = SW[9:8]

        beqz  t3, do_add         # op==0 -> add
        addi  t4, x0, 1
        beq   t3, t4, do_sub     # op==1 -> sub
        addi  t4, x0, 2
        beq   t3, t4, do_and     # op==2 -> and
        or    a2, a0, a1         # op==3 -> or
        j     show
do_add: add   a2, a0, a1
        j     show
do_sub: sub   a2, a0, a1
        j     show
do_and: and   a2, a0, a1
        j     show

show:
        sw    a2, 0x20(t0)       # display = resultado
        sw    t3, 0x10(t0)       # LEDR baixos = código da operação
        j     loop
