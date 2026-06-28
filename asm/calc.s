# calc.s — Calculadora ACUMULADOR: programa RISC-V rodando no próprio processador.
# Projeto: Processador RISC-V RV32I na DE10-Lite. Autor: João Moreti.
#
# IDEIA-CHAVE (multiplexação no tempo): em vez de exigir A e B nas chaves ao
# mesmo tempo (o que limitaria a 10 bits e somas <= ~62), reutilizamos as MESMAS
# chaves em momentos diferentes. O botão KEY1 ("Enter/=") confirma cada valor, e o
# processador GUARDA o acumulador num registrador (s0). Assim cada valor pode usar
# os 8 bits de chave (0..255) e o resultado cresce sem o limite de switches.
#
# Entradas:
#   SW[7:0] = valor a aplicar (0..255, binário)
#   SW[9:8] = operação:  00=+  01=-  10=&  11=|
#   KEY1    = "Enter/=": aplica  acc = acc <op> valor   (uma vez por pressão)
#   KEY0    = limpar (reset físico do processador -> acc volta a 0)
# Saídas:
#   0x2020 = acumulador (decimal com sinal nos 6 HEX; LEDR8=sinal, LEDR9=overflow)
#   0x2010 = LEDR baixos = código da operação selecionada
#
# Mapa de I/O (base 0x2000):
#   0x2000 (R) SW[9:0]                 0x2010 (W) LEDR
#   0x2004 (R) bit0=KEY0 bit1=KEY1     0x2020 (W) valor exibido
#
# Tratamento do botão (DEBOUNCE por software — detalhe defensável):
#   um botão mecânico "treme" (bounce) por alguns ms ao ser pressionado/solto.
#   Aqui: detecta a pressão -> espera o bounce assentar (delay) -> reconfirma ->
#   aplica UMA vez -> espera SOLTAR (+ delay). Isso garante 1 pressão = 1 operação.

        lui   t0, 2              # t0 = 0x2000 (base de I/O)
        addi  s0, x0, 0          # s0 = acumulador = 0
                                 #   (regs do banco NAO tem reset -> zerar a mao)
loop:
        sw    s0, 0x20(t0)       # display = acumulador (estavel entre pressoes)
        lw    t1, 0(t0)          # t1 = SW
        srli  t2, t1, 8
        andi  t2, t2, 0x3        # t2 = op = SW[9:8]
        sw    t2, 0x10(t0)       # LEDR baixos mostram a operacao escolhida

        lw    t3, 4(t0)          # t3 = KEY (bit1 = KEY1 pressionado)
        andi  t3, t3, 0x2        # isola KEY1
        beqz  t3, loop           # nao pressionado -> continua no laco

        # --- KEY1 pressionado: debounce + reconfirmacao ---
        jal   ra, delay          # espera o bounce da pressao assentar
        lw    t3, 4(t0)
        andi  t3, t3, 0x2
        beqz  t3, loop           # era ruido/glitch -> ignora

        # --- pressao confirmada: le valor+op no instante e aplica ---
        lw    t1, 0(t0)
        andi  a0, t1, 0xFF       # a0 = valor = SW[7:0]
        srli  t2, t1, 8
        andi  t2, t2, 0x3        # t2 = op
        beqz  t2, do_add         # op==0 -> +
        addi  t4, x0, 1
        beq   t2, t4, do_sub     # op==1 -> -
        addi  t4, x0, 2
        beq   t2, t4, do_and     # op==2 -> &
        or    s0, s0, a0         # op==3 -> |
        j     waitrel
do_add: add   s0, s0, a0
        j     waitrel
do_sub: sub   s0, s0, a0
        j     waitrel
do_and: and   s0, s0, a0
        j     waitrel

waitrel:
        sw    s0, 0x20(t0)       # atualiza o display com o novo acumulador
wr_lp:  lw    t3, 4(t0)          # espera o usuario SOLTAR o KEY1
        andi  t3, t3, 0x2
        bnez  t3, wr_lp          # ainda pressionado -> espera
        jal   ra, delay          # debounce da soltura
        j     loop

# Sub-rotina de atraso (busy-wait) — ~2,9 ms na placa (CPU a 3,125 MHz).
# Aumente a constante para um debounce mais agressivo; diminua para mais resposta.
delay:
        li    t5, 3000
d_lp:   addi  t5, t5, -1
        bnez  t5, d_lp
        ret
