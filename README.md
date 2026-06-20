# Processador RISC-V RV32I single-cycle na DE10-Lite

Projeto-desafio de Arquitetura e Organização de Computadores (PUCPR, 2026/1).
Autor: **João Moreti**.

Um processador **RISC-V RV32I** single-cycle em VHDL-2008 para a placa **DE10-Lite**
(MAX 10), com uma **calculadora** em assembly rodando no próprio processador, mais
um experimento de **escalabilidade da ULA** (área/Fmax × largura).

## Por onde começar
- **`HANDOFF.md`** — estado vivo do projeto, o que está feito e o que falta.
- **`docs/GUIA.md`** — instalar, simular, sintetizar, gravar (passo a passo).
- **`docs/relatorio.md`** — relatório (esqueleto; números após rodar as ferramentas).
- `projeto_riscv_de10lite_unificado.md` e `perguntas_respostas.md` — especificação.

## Status rápido
- ✅ Código completo (VHDL, montador, testbenches, scripts, projeto da placa).
- ✅ **Síntese:** `quartus_map` 0 erros; compile completo gera o `.sof`; 14.220 LEs
  (29%), timing fechado (multicycle 16 → slack +294 ns).
- ✅ **Frente A:** dados reais (LEs/Fmax × 4/8/16/32/64 bits) + gráficos.
- ✅ **Validação funcional:** 5/5 testbenches **ALL TESTS PASSED** (GHDL) — inclui a
  CPU completa e a calculadora. Rode: `bash sim/run_all_ghdl.sh`.
- 🔴 **Falta só:** gravar o `.sof` na **placa física** DE10-Lite e demonstrar.

## Layout
`src/` VHDL · `sim/` testbenches · `scripts/` montador+automação · `asm/` programas ·
`mem/` ROM montada · `sdc/` timing · `docs/` documentação · `reports/` saídas Frente A.
