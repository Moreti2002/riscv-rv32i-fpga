# alu_fmax.sdc  —  Constraint de timing para medir Fmax da ULA (Frente A).
#
# Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
#
# Define um clock "virtual rápido" no pino clk do alu_fmax_wrapper. O quartus_sta
# então reporta o slack do caminho reg->ULA->reg; o Fmax sai do relatório de
# timing (report_clock_fmax_summary / sta report).
#
# Pedimos um período agressivo (2 ns = 500 MHz) de propósito: o caminho não vai
# fechar nessa frequência, mas o "Fmax" reportado pelo Timing Analyzer é a
# frequência máxima real do caminho — não depende do período pedido, só precisa
# existir um create_clock para o caminho ser analisado.

create_clock -name clk -period 2.000 [get_ports clk]

# Boa prática: contabiliza incerteza de clock derivada (jitter etc.).
derive_clock_uncertainty
