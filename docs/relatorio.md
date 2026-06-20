# Relatório — Processador RISC-V RV32I single-cycle na DE10-Lite

**Autor:** João Moreti — Arquitetura e Organização de Computadores, PUCPR, 2026/1
**Orientador:** Prof. Valter Klein Junior
**Placa:** DE10-Lite (Intel/Altera MAX 10 `10M50DAF484C7G`) · **Ferramentas:** Quartus Prime Lite 22.1 + Questa

> Seções marcadas com _[preencher após síntese/simulação]_ dependem de rodar as
> ferramentas (ver `GUIA.md`). O código e os testbenches estão completos.

---

## 1. Objetivo

Construir um processador **RISC-V RV32I** (subconjunto inteiro) em organização
**single-cycle**, em VHDL-2008, validá-lo por simulação e demonstrá-lo na DE10-Lite
através de uma **calculadora** escrita em assembly RISC-V rodando no próprio
processador. Em paralelo, caracterizar a **escalabilidade da ULA** em área e
frequência (Frente A).

## 2. Frente A — Escalabilidade da ULA

### 2.1 Metodologia
A ULA (`src/alu/alu.vhd`) é parametrizada na largura (`generic WIDTH`). Um wrapper
com registradores na entrada e na saída (`alu_fmax_wrapper.vhd`) isola o caminho
combinacional para o Timing Analyzer medir o Fmax (a ULA pura não tem Fmax, pois
não há registradores). O script `scripts/sweep_alu.tcl` compila automaticamente em
4, 8, 16, 32 e 64 bits e coleta LEs, registradores e Fmax.

### 2.2 Resultados
_[preencher após rodar `quartus_sh -t scripts/sweep_alu.tcl` — tabela e gráficos]_

| Largura (bits) | Logic Elements | Registradores | Fmax (MHz) |
|---:|---:|---:|---:|
| 4   | _..._ | _..._ | _..._ |
| 8   | _..._ | _..._ | _..._ |
| 16  | _..._ | _..._ | _..._ |
| 32  | _..._ | _..._ | _..._ |
| 64  | _..._ | _..._ | _..._ |

Referência (síntese prévia na faculdade, ULA 32 bits combinacional sem wrapper):
**684 LEs, 0 registradores**, ~94 LEs em modo aritmético (cadeias de carry) e ~590
em modo normal (lógicas + muxes dos barrel shifters).

Gráficos: `docs/alu_le_vs_width.png`, `docs/alu_fmax_vs_width.png`.

### 2.3 Análise
_[preencher]_ Esperado: somador e lógicas crescem ~linearmente com a largura; o
**barrel shifter** domina e cresce de forma superlinear (≈ N·log N em área). O Fmax
tende a cair com a largura (caminho de carry do somador e profundidade do shifter).
Nota: 64 bits **não é mais RV32I** — é o instrumento de medida esticado além da ISA
para observar a tendência de área.

## 3. Frente B — Processador RV32I single-cycle

### 3.1 ISA implementada (cobertura intermediária)
- **Tipo-R:** ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU.
- **Tipo-I aritm.:** ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI.
- **Branches:** BEQ, BNE, BLT, BGE, BLTU, BGEU.
- **Memória:** LW, SW (arquitetura preparada para LB/LH/SB/SH).
- **Saltos:** JAL, JALR. **Tipo-U:** LUI, AUIPC.

### 3.2 Organização (datapath single-cycle)
PC de 32 bits → ROM de instruções (256×32) → decodificação dos campos →
banco de registradores (32×32, x0=0) + gerador de imediatos → ULA / unidade de
branch → memória de dados (256×32) e I/O → write-back. Endereçamento por byte,
PC+4. Reset síncrono (PC←0) pelo KEY0 (ativo-baixo).

Contrato `alu_op = {instr[30], funct3}` deixa a geração de controle da ULA quase
trivial. Detalhe crítico tratado: em I-type, `instr[30]` faz parte do imediato,
então só vira funct7 nos shifts (SRLI/SRAI) — evita transformar ADDI em "SUBI".

### 3.3 Cálculo de alvos de desvio
- `PC+4` (sequência), `PC+imm` (branch tomado e JAL, somador dedicado),
  `(rs1+imm) & ~1` (JALR, via ULA com bit 0 zerado).

### 3.4 I/O e calculadora (etapa 7)
I/O mapeado em memória: SW/KEY (entrada) e LEDR/display (saída). O display mostra
inteiros de 32 bits em **decimal com sinal**, via conversão binário→BCD
(*double dabble*) e decodificação 7-segmentos; **overflow** (|valor|≥10⁶) acende um
LED. Na DE10-Lite os 6 displays têm pinos dedicados (sem multiplexação).
A calculadora (`asm/calc.s`) é um programa assembly que lê as chaves, opera e exibe.

### 3.5 Validação por simulação
Testbenches auto-verificáveis (Questa):
- `tb_alu` — casos-armadilha (SLT/SLTU, SRA/SRL, shamt de 5 bits).
- `tb_regfile` — x0 imutável, 2 leituras, escrita síncrona.
- `tb_bin2bcd` — conversão decimal, inclusive truncamento.
- `tb_core` — programa que exercita toda a ISA, conferindo registradores.
- `tb_calc` — calculadora ( +, −, &, | ), conferindo o valor exibido.

Resultados: _[preencher após rodar `vsim -c -do run_all.do` — esperado ALL TESTS PASSED]_

### 3.6 Síntese do processador completo
_[preencher após `quartus_map riscv_de10lite` — LEs, registradores, blocos M9K]_
Estimativa do plano: ~2.000–4.000 LEs (≈5–10% do chip) + blocos M9K para memórias.

## 4. Limitações conscientes
- Desalinhamento e instruções inválidas **não** geram exceção (programas
  bem-comportados) — num processador real haveria traps.
- Memória de dados limitada a LW/SW (sub-word fica como extensão).
- Display: valores acima de 6 dígitos decimais mostram os 6 dígitos baixos + LED
  de overflow.

## 5. Como reproduzir
Ver `docs/GUIA.md` (instalação, licença, simulação, síntese, gravação).

## 6. Referências
- Patterson & Hennessy, *Computer Organization and Design, RISC-V Edition*.
- Harris & Harris, *Digital Design and Computer Architecture, RISC-V Edition* (cap. 7).
- *The RISC-V Instruction Set Manual, Vol. I: Unprivileged ISA* (RV32I).
- Terasic, *DE10-Lite User Manual* (pinout e periféricos).
