# run_alu.do  —  Roda o testbench da ULA no Questa (modo console).
#
# Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
#
# Uso (a partir da pasta sim/, com Questa no PATH e licença configurada):
#   vsim -c -do run_alu.do
# ou direto:
#   vsim -c -do "do run_alu.do; quit -f"
#
# Sucesso = aparece "ALL TESTS PASSED" no transcript. Qualquer FAIL aborta.

# Biblioteca de trabalho limpa.
if {[file exists work]} { vdel -all }
vlib work

# Compila ULA + testbench em VHDL-2008.
vcom -2008 ../src/alu/alu.vhd
vcom -2008 tb_alu.vhd

# Simula sem GUI e roda até o fim.
vsim -c work.tb_alu
run -all
quit -f
