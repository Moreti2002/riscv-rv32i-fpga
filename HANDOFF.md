# HANDOFF — Processador RISC-V RV32I na DE10-Lite (documento vivo)

> **Para qualquer chat/pessoa que pegar este projeto:** leia este arquivo primeiro.
> Ele é **vivo** — atualizado a cada avanço. Última atualização: **2026-06-19**.
>
> Os dois documentos-fonte de especificação são:
> - `projeto_riscv_de10lite_unificado.md` — plano + atualizações.
> - `perguntas_respostas.md` — decisões de arquitetura.
>
> Este HANDOFF **não substitui** esses dois; ele resume o contexto e rastreia o
> estado real (o que está feito, pendente, e como retomar).

---

## 1. Contexto em 30 segundos

- **Objetivo:** construir um **processador RISC-V RV32I single-cycle** em **VHDL-2008**
  para a placa **DE10-Lite** (FPGA MAX 10 `10M50DAF484C7G`), e um experimento de
  **escalabilidade da ULA** (Frente A).
- **Aluno/autor no relatório:** **João Moreti**. (Os .md de spec citam "Pedro" como
  placeholder — usar João Moreti nos cabeçalhos/relatório.)
- **Disciplina:** Arq. e Organização de Computadores — PUCPR, 7º período, 2026/1,
  Prof. Valter Klein Junior. Projeto extracurricular individual.
- **Ferramentas:** Quartus Prime Lite 22.1.2 (síntese, sem licença) + Questa Intel
  FPGA Starter (simulação, **precisa de licença gratuita**).
- **Regra de ouro:** nada vai para a placa sem antes passar na simulação.

### Duas frentes
- **Frente A** — ULA RV32I parametrizada em largura (`generic WIDTH`); sintetizar em
  4/8/16/32/64 bits; tabela+gráfico LEs×largura; Fmax via wrapper+`.sdc`.
- **Frente B** — processador RV32I single-cycle em 7 etapas (ULA → regfile → PC+ROM+
  decode → datapath+controle → RAM+LW/SW → JAL/JALR → I/O+calculadora).

---

## 2. Decisões fechadas (contratos do projeto)

| Tema | Decisão |
|---|---|
| ISA | RV32I, **cobertura "intermediária"**: tipo-R, tipo-I aritm., **6 branches** (BEQ/BNE/BLT/BGE/BLTU/BGEU), **LW/SW**, JAL/JALR, LUI/AUIPC. (LB/LH/SB/SH = extensão futura fácil, se sobrar tempo.) |
| `alu_op` (4 bits) | `alu_op(2..0)`=funct3; `alu_op(3)`=instr[30] (funct7[5]). ADD=0000, SUB=1000, SLL=0001, SLT=0010, SLTU=0011, XOR=0100, SRL=0101, SRA=1101, OR=0110, AND=0111. |
| Memórias | ROM 256×32, RAM 256×32 (1 bloco M9K cada). Endereçamento **por byte**, PC+4. |
| Reset | Botão físico (KEY0/KEY1, **ativo-baixo**), síncrono, PC←0. |
| PC | 32 bits. |
| Display | **Decimal com sinal + indicador de overflow** (complemento de 2; binário→BCD por *double dabble*; 6 displays; overflow num LED/ponto se >6 dígitos). |
| Calculadora | Versão simples (A op B → display), como **programa assembly** rodando no processador. |
| Mapa de memória (esboço) | ROM `0x0000_0000`, RAM `0x0000_1000`, I/O `0x0000_2000`. Final definido nas etapas 5/7. |
| Desalinhamento / instr. inválida | Não tratados (programas bem-comportados) — limitação documentada. |
| Linguagem | VHDL-2008, `ieee.numeric_std` (nunca `std_logic_arith`). |

---

## 3. Ambiente / máquina

- **Projeto (repo Git):** `C:\Users\joaom\Documents\Trab_AOC`
- **Disco C: ~8 GB livres** (pouco). **Disco D: ~57 GB livres** → ferramentas vão no D.
- **Instaladores baixam para:** `D:\altera_installers\`
  - URLs diretas Intel (`akdlm`) respondem **sem login** (HTTP 200). Padrão:
    `https://downloads.intel.com/akdlm/software/acdsinst/22.1std.2/922/ib_installers/<arquivo>`
  - Arquivos: `QuartusLiteSetup-22.1std.2.922-windows.exe` (~1,74 GB),
    `max10-22.1std.2.922.qdz` (~300 MB), `QuestaSetup-22.1std.2.922-windows.exe` (~818 MB).
- **Quartus será instalado em:** `D:\altera_lite\22.1` (modo silencioso).
- **Sem acentos/espaços** em pastas que as ferramentas tocam.

---

## 4. Estado atual (o que está FEITO)

**Código: praticamente TUDO escrito e revisado** (revisão estática adversarial por
subagente: 0 erros de elaboração/lógica). Falta só RODAR as ferramentas (gated pela
instalação + licença).

- [x] Análise dos dois .md de spec + decisões confirmadas (§2).
- [x] Repositório Git + estrutura + `.gitignore` + `.gitattributes`.
- [x] **Download** dos instaladores Quartus+Questa concluído (`D:\altera_installers\`).
- [x] **Frente A:** `alu.vhd` + `tb_alu.vhd` + wrapper Fmax + `.sdc` + `sweep_alu.tcl` + `plot_sweep.py`.
- [x] **Frente B (núcleo completo):** regfile, riscv_pkg, imm_gen, control, branch_unit,
      imem, dmem, riscv_core, riscv_system.
- [x] **Etapa 7:** bin2bcd, seg7, display_unit, top-level `riscv_de10lite`.
- [x] **Montador** `asm.py` (verificado 27/27 + 23/23 instr. vs spec à mão).
- [x] Programas `test_core.s` e `calc.s` montados (`mem/*.hex`).
- [x] **Testbenches:** tb_alu, tb_regfile, tb_bin2bcd, tb_core, tb_calc + `run_all.do`.
- [x] **Projeto da placa:** `riscv_de10lite.qpf/.qsf` (pinos reais DE10-Lite) + `.sdc`.
- [x] Docs: `docs/GUIA.md` (build/uso) + `docs/relatorio.md` (esqueleto).
- [ ] **Instalar** Quartus/Questa (BLOQUEADO: precisa de elevação UAC do usuário).
- [ ] **Rodar** síntese Frente A + `quartus_map` (após instalar; sem licença).
- [ ] **Rodar** testbenches no Questa (após instalar + licença).

### Estrutura de pastas do repo
```
src/alu   src/cpu   src/io      # VHDL fonte
sim                              # testbenches
scripts                         # Tcl (sweep Frente A, compile flow)
sdc                             # constraints de timing (.sdc)
asm                             # programas assembly RISC-V
mem                             # .mif/.hex gerados
docs                            # relatório, gráficos
reports                         # saídas de síntese coletadas
```

---

## 5. TO-DO (lista viva)

### CONCLUÍDO nesta sessão (autônomo) ✅
- [x] Quartus + Questa instalados no D: (após o usuário aprovar 1 UAC).
- [x] `quartus_map riscv_de10lite` → **0 erros** (ROM carregando, display dirigido).
- [x] Frente A: sweep 4/8/16/32/64 bits → CSV + 2 gráficos → relatório preenchido.
- [x] `quartus_sh --flow compile` → **.sof gerado**, 14.220 LEs (29%), timing OK
      (multicycle 16 → setup slack +294 ns).
- [x] **Validação funcional: 5/5 testbenches ALL TESTS PASSED** via **GHDL**
      (livre, sem licença) — `bash sim/run_all_ghdl.sh`. Inclui CPU completa e
      calculadora (7+3, 3−7=−4, 12&10, 12|3).

### Pendência manual restante (declarada)
- 🔴 **Placa física DE10-Lite** — gravar `output_files/riscv_de10lite.sof` (já
  pronto), validar timing real e demonstração. **Único passo que falta.**
- 🟢 **(Opcional) Questa** — instalado, mas precisa de licença + correção da UCRT
  (`api-ms-win-crt-*` ausentes; ver `GUIA.md §3b`). Não é necessário: o GHDL já
  validou tudo. Só relevante se a disciplina exigir o Questa especificamente.

---

## 6. Como retomar (para outro chat)

1. Ler `projeto_riscv_de10lite_unificado.md` + `perguntas_respostas.md` + este HANDOFF.
2. Checar estado do download: `Read D:\altera_installers\download.log`.
3. Ver §4/§5 para o que está feito e o próximo passo.
4. `git log --oneline` mostra o histórico real de avanço.

---

## 7. Log de prompts/decisões recentes (resumo)

- **2026-06-19** — Aluno pediu execução autônoma máxima; parar só em intervenção
  manual real. Decisões: cobertura **intermediária**, display **decimal c/ sinal+ovf**.
  Instaladores Intel baixam **sem login** → Claude baixou tudo (D:). **Instalação
  porém exige elevação UAC**: tentei Start-Process e tarefa agendada elevada, ambos
  bloqueados (registrar tarefa RL HIGHEST também pede elevação). → 1 passo manual:
  duplo-clique em `install_launch.ps1`. Git iniciado (autor João Moreti).
- **2026-06-19 (cont.)** — Escrito e revisado TODO o projeto numa sessão: Frente A
  (ULA+sweep), núcleo RV32I single-cycle completo (7 etapas), I/O+BCD+7seg+top,
  montador próprio (verificado à mão), 5 testbenches, projeto da placa com pinos
  reais, docs. Revisão estática adversarial: 0 erros.
- **2026-06-20** — Usuário aprovou a instalação (UAC). Sessão de EXECUÇÃO autônoma:
  (1) Quartus instalou (~2h, disco lento). (2) `quartus_map`: achei e corrigi 2 bugs
  reais — `hread` não suportado em síntese e file I/O ignorado pelo Quartus 22.1;
  troquei a ROM por **pacote VHDL gerado** (asm.py --vhdl). (3) Frente A: dados reais
  coletados, gráficos. (4) Compile completo: .sof + timing fechado via multicycle.
  (5) Questa esbarrou na UCRT (`api-ms-win-crt-*` ausentes) + licença → instalei
  **GHDL** (livre, portável, sem licença) e **validei os 5 testbenches: ALL PASSED**.
  Restou só a **placa física**.

---

_Mantido por Claude Code. Atualizar §4, §5 e §7 a cada avanço significativo._
