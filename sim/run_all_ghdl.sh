#!/usr/bin/env bash
# run_all_ghdl.sh — Compila e roda TODOS os testbenches no GHDL (livre, sem licença).
#
# Projeto: Processador RISC-V RV32I na DE10-Lite. Autor: João Moreti.
#
# GHDL é uma alternativa livre ao Questa: mesmo VHDL-2008, sem licença nem as
# dependências de runtime do Questa. Usado para validação funcional deste projeto.
#
# Uso (a partir da RAIZ do repo, com ghdl no PATH):
#   bash sim/run_all_ghdl.sh
# Sucesso = cada testbench imprime "ALL TESTS PASSED" e o script termina com OK.

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
WORK="reports/ghdl"
mkdir -p "$WORK"
GHDL="${GHDL:-ghdl}"
FLAGS="--workdir=$WORK --std=08"

echo "== Analisando hierarquia =="
$GHDL -a $FLAGS \
  src/cpu/riscv_pkg.vhd \
  mem/calc_rom_pkg.vhd \
  mem/test_core_rom_pkg.vhd \
  src/alu/alu.vhd \
  src/alu/alu_fmax_wrapper.vhd \
  src/cpu/regfile.vhd \
  src/cpu/imm_gen.vhd \
  src/cpu/control.vhd \
  src/cpu/branch_unit.vhd \
  src/cpu/imem.vhd \
  src/cpu/dmem.vhd \
  src/cpu/riscv_core.vhd \
  src/cpu/riscv_system.vhd \
  src/io/bin2bcd.vhd \
  src/io/seg7.vhd \
  src/io/display_unit.vhd \
  src/io/riscv_de10lite.vhd \
  sim/tb_alu.vhd sim/tb_regfile.vhd sim/tb_bin2bcd.vhd sim/tb_core.vhd sim/tb_calc.vhd || {
    echo "ERRO na análise"; exit 1; }

run_tb() {
  local tb="$1" t="$2"
  echo ""
  echo "===== $tb ====="
  local out
  out=$($GHDL -r $FLAGS "$tb" --stop-time="$t" 2>&1)
  echo "$out" | grep -aiE "ALL TESTS PASSED|FAIL|TESTS FAILED"
  if echo "$out" | grep -aq "ALL TESTS PASSED" && ! echo "$out" | grep -aqi "TESTS FAILED"; then
    return 0
  fi
  echo ">>> $tb NAO passou"; return 1
}

fail=0
run_tb tb_alu     5us   || fail=1
run_tb tb_regfile 10us  || fail=1
run_tb tb_bin2bcd 5us   || fail=1
run_tb tb_core    50us  || fail=1
run_tb tb_calc    8ms   || fail=1

echo ""
if [ "$fail" -eq 0 ]; then
  echo "==================== TODOS OS TESTBENCHES PASSARAM ===================="
else
  echo "!!!!!!!!!!!!!!!!!!! ALGUM TESTBENCH FALHOU !!!!!!!!!!!!!!!!!!!"; exit 1
fi
