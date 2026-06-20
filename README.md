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
- ✅ Todo o código (VHDL, montador, testbenches, scripts, projeto da placa) escrito e
  estaticamente revisado (0 erros).
- ⏳ Falta: **instalar** Quartus/Questa (1 clique de elevação — `scripts\install_launch.ps1`),
  gerar a **licença gratuita do Questa** (só p/ simular) e a **placa física** (gravação/demo).

## Layout
`src/` VHDL · `sim/` testbenches · `scripts/` montador+automação · `asm/` programas ·
`mem/` ROM montada · `sdc/` timing · `docs/` documentação · `reports/` saídas Frente A.
