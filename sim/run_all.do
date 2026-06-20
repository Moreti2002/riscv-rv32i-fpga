# run_all.do — Compila toda a hierarquia e roda TODOS os testbenches no Questa.
#
# Projeto: Processador RISC-V RV32I na DE10-Lite. Autor: João Moreti.
#
# Uso (a partir de sim/, com Questa no PATH e licença configurada):
#   vsim -c -do run_all.do
#
# Sucesso global = cada testbench imprime "ALL TESTS PASSED" e nenhum "FAIL".

if {[file exists work]} { vdel -all }
vlib work

# --- Pacote e blocos ---
vcom -2008 ../src/cpu/riscv_pkg.vhd
vcom -2008 ../src/alu/alu.vhd
vcom -2008 ../src/alu/alu_fmax_wrapper.vhd
vcom -2008 ../src/cpu/regfile.vhd
vcom -2008 ../src/cpu/imm_gen.vhd
vcom -2008 ../src/cpu/control.vhd
vcom -2008 ../src/cpu/branch_unit.vhd
vcom -2008 ../src/cpu/imem.vhd
vcom -2008 ../src/cpu/dmem.vhd
vcom -2008 ../src/cpu/riscv_core.vhd
vcom -2008 ../src/cpu/riscv_system.vhd
vcom -2008 ../src/io/bin2bcd.vhd
vcom -2008 ../src/io/seg7.vhd
vcom -2008 ../src/io/display_unit.vhd
vcom -2008 ../src/io/riscv_de10lite.vhd

# --- Testbenches ---
vcom -2008 tb_alu.vhd
vcom -2008 tb_regfile.vhd
vcom -2008 tb_bin2bcd.vhd
vcom -2008 tb_core.vhd
vcom -2008 tb_calc.vhd

proc run_tb {top} {
    puts "\n================= $top ================="
    # +acc preserva visibilidade de sinais internos (necessário p/ external names)
    vsim -c -voptargs=+acc work.$top
    run -all
    quit -sim
}

run_tb tb_alu
run_tb tb_regfile
run_tb tb_bin2bcd
run_tb tb_core
run_tb tb_calc

puts "\n>>> Todos os testbenches executados. Procure por ALL TESTS PASSED / FAIL acima."
quit -f
