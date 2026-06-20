# riscv_de10lite.sdc — Constraints de timing da placa.
# Projeto: Processador RISC-V RV32I na DE10-Lite. Autor: João Moreti.

# Clock de 50 MHz (pino P11).
create_clock -name MAX10_CLK1_50 -period 20.000 [get_ports MAX10_CLK1_50]
derive_clock_uncertainty

# MULTICYCLE — coerente com o clock-enable.
# Todo registrador do design (PC, banco de registradores, RAM de dados,
# registradores de I/O) só é habilitado a cada 2^CPU_DIV = 16 ciclos de 50 MHz
# (sinal "en", derivado do contador cnt). Logo, um dado lançado num pulso de
# enable só é capturado 16 ciclos depois: o caminho dispõe de 16*20 ns = 320 ns,
# não de 20 ns. Informamos isso ao Timing Analyzer com um multicycle de 16.
#
# É seguro aplicar globalmente: o ÚNICO elemento que comuta a cada ciclo é o
# contador cnt (4 bits) que gera o "en" — trivialmente rápido, fecha folgado
# mesmo sendo relaxado. Todo o resto é genuinamente multiciclo (1-em-16).
set_multicycle_path -setup -end 16 -from [get_clocks MAX10_CLK1_50] -to [get_clocks MAX10_CLK1_50]
set_multicycle_path -hold  -end 15 -from [get_clocks MAX10_CLK1_50] -to [get_clocks MAX10_CLK1_50]

# Entradas assíncronas (chaves/botões) e saídas (LEDs/HEX) não têm requisito de
# timing rígido — relaxa para não poluir o relatório.
set_false_path -from [get_ports {SW[*] KEY[*]}] -to *
set_false_path -from * -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]
