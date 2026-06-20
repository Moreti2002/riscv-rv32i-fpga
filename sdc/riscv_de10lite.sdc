# riscv_de10lite.sdc — Constraints de timing da placa.
# Projeto: Processador RISC-V RV32I na DE10-Lite. Autor: João Moreti.

# Clock de 50 MHz (pino P11).
create_clock -name MAX10_CLK1_50 -period 20.000 [get_ports MAX10_CLK1_50]
derive_clock_uncertainty

# A CPU avança por clock-enable (en) a cada 2^CPU_DIV ciclos (default 16). O
# caminho combinacional single-cycle (ULA, memórias) tem, portanto, vários
# ciclos para assentar. Se o Timing Analyzer apontar violação no caminho da CPU
# rodando a 50 MHz "single-cycle", há duas saídas, nesta ordem de preferência:
#   1) aumentar CPU_DIV (mais folga, calculadora continua instantânea ao olho);
#   2) declarar multicycle aqui (set_multicycle_path) entre os registradores da
#      CPU, coerente com o fator de enable.
# Como o enable cobre PC + banco de registradores + RAM, o caminho de dados não
# é crítico para a demonstração da calculadora.

# Entradas assíncronas (chaves/botões) e saídas (LEDs/HEX) não têm requisito de
# timing rígido — relaxa para não poluir o relatório.
set_false_path -from [get_ports {SW[*] KEY[*]}] -to *
set_false_path -from * -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]
