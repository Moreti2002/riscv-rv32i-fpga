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

- [x] Análise dos dois .md de spec.
- [x] Decisões de arquitetura confirmadas com o aluno (ver §2).
- [x] Repositório Git inicializado + estrutura de pastas + `.gitignore`.
- [x] Download dos instaladores Quartus+Questa disparado em background (D:).
- [ ] _(em andamento — atualizar abaixo)_

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

### Bloqueado por intervenção manual (declarado)
- 🔴 **Placa física DE10-Lite** — gravar `.sof`, timing real, demo final. **Não hoje.**
- 🟡 **Licença gratuita do Questa** — gerar na conta Intel (vinculada ao MAC,
  `ipconfig /all` → "Endereço Físico"), salvar `.dat`, apontar `LM_LICENSE_FILE`.
  **Sem isso o Questa não simula.** (Quartus/síntese NÃO precisa de licença.)

### Autônomo (Claude faz)
- [ ] Concluir download + instalar Quartus/Questa em silencioso no D:.
- [ ] **Frente A:** `alu.vhd` parametrizada + `tb_alu.vhd` + wrapper Fmax + `.sdc` + Tcl do sweep.
- [ ] Rodar síntese da Frente A (sem licença) → coletar LEs/Fmax 4/8/16/32/64 bits → tabela+gráfico.
- [ ] **Frente B etapa 2:** banco de registradores 32×32 + tb.
- [ ] **Etapa 3:** PC + ROM + decoder de formatos + gerador de imediatos + tb.
- [ ] **Etapa 4:** datapath + unidade de controle (tipo-R/I, branches) + tb.
- [ ] **Etapa 5:** memória de dados + LW/SW + tb.
- [ ] **Etapa 6:** JAL/JALR + tb.
- [ ] **Etapa 7:** I/O mapeado + BCD + driver 7-seg + multiplexação + tb.
- [ ] Assembly da calculadora + montagem → `.mif`/`.hex`.
- [ ] `.qsf` com pinos da DE10-Lite (clock P11, SW, KEY, LEDR, HEX0–5).
- [ ] Relatório final + gráficos.

### Esperando simulação (depende da licença Questa)
- [ ] Validar funcionalmente cada bloco no Questa (CLI: `vlib`/`vcom -2008`/`vsim -c -do "run -all"`).

---

## 6. Como retomar (para outro chat)

1. Ler `projeto_riscv_de10lite_unificado.md` + `perguntas_respostas.md` + este HANDOFF.
2. Checar estado do download: `Read D:\altera_installers\download.log`.
3. Ver §4/§5 para o que está feito e o próximo passo.
4. `git log --oneline` mostra o histórico real de avanço.

---

## 7. Log de prompts/decisões recentes (resumo)

- **2026-06-19** — Aluno pediu execução autônoma máxima; parar só em intervenção
  manual real. Confirmadas decisões: cobertura **intermediária**, display **decimal
  com sinal+overflow**. Descoberto que os instaladores Intel baixam **sem login** →
  Claude faz download+instalação sozinha (antes seria manual). Pendências manuais
  reduzidas a **placa física** e **licença Questa**. Git iniciado (autor João Moreti).
  Pedido este arquivo HANDOFF vivo.

---

_Mantido por Claude Code. Atualizar §4, §5 e §7 a cada avanço significativo._
