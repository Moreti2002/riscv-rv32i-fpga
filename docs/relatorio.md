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

Síntese do `alu_fmax_wrapper` (ULA entre registradores) no MAX 10 `10M50DAF484C7G`,
Quartus 22.1.2. Dados em `reports/alu_sweep.csv`.

| Largura (bits) | Logic Elements | Registradores | Fmax (MHz) |
|---:|---:|---:|---:|
| 4   | 53   | 17  | 210,3 |
| 8   | 137  | 29  | 180,1 |
| 16  | 326  | 53  | 134,4 |
| 32  | 703  | 101 | 116,3 |
| 64  | 1545 | 197 | 86,2  |

Gráficos: `docs/alu_le_vs_width.png` (LEs × largura) e `docs/alu_fmax_vs_width.png`
(Fmax × largura).

**Sanity checks:**
- Os registradores seguem exatamente **3·W + 5** (entradas a+b+op = 2W+4; saídas
  result+zero = W+1): 17, 29, 53, 101, 197 — confirma que o wrapper instanciou os
  flip-flops esperados e que a ULA em si é combinacional.
- A ULA de 32 bits com wrapper dá 703 LEs; bate com a síntese prévia da ULA pura
  (**684 LEs, 0 registradores**) mais a lógica de fronteira dos registradores.

### 2.3 Análise

**Área (LEs).** A cada vez que a largura dobra, os LEs crescem por um fator
**~2,1–2,6×** (53→137→326→703→1545), ou seja, **superlinearmente**. O somador e as
lógicas bit-a-bit (AND/OR/XOR) escalam linearmente, mas o **barrel shifter** (SLL/
SRL/SRA) escala como ≈ N·log N (são log₂N estágios de muxes de N bits) e domina o
crescimento — exatamente o previsto.

**Frequência (Fmax).** Cai monotonicamente de **210 MHz (4 bits) para 86 MHz
(64 bits)**. Duas causas combinadas no caminho crítico: a **cadeia de carry** do
somador/subtrator (cresce ~linear com a largura) e a **profundidade do barrel
shifter** (cresce com log₂N). Em 32 bits, 116 MHz — folga confortável sobre os
50 MHz da placa.

**Nota sobre 64 bits:** **não é mais RV32I** — é o instrumento de medida esticado
além da ISA, só para observar a tendência de área/atraso. A ISA do processador é
de 32 bits.

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

A elaboração de toda a hierarquia já foi confirmada na prática: `quartus_map
riscv_de10lite` compila com **0 erros** (e a ROM da calculadora é lida corretamente
— o display é dirigido pela CPU, sem saídas constantes). A **execução funcional** dos
testbenches no Questa fica pendente apenas da licença gratuita (ver `GUIA.md §2`);
esperado: `ALL TESTS PASSED` em todos. _[preencher saída do `run_all.do` após a licença]_

### 3.6 Síntese do processador completo

Compilação completa (Quartus 22.1.2, `10M50DAF484C7G`), top `riscv_de10lite` com a
calculadora na ROM. `.sof` gerado com sucesso (0 erros). Dados em
`reports/compile_board.log` e `output_files/riscv_de10lite.fit.summary`.

| Recurso | Uso | % do chip |
|---|---:|---:|
| Logic elements | 14.220 / 49.760 | 29% |
| Registradores | 9.263 / 49.760 | 19% |
| Pinos de I/O | 71 / 360 | 20% |
| Bits de memória (M9K) | 0 / 1.677.312 | 0% |

**Por que 14k LEs (e não os ~2–4k estimados no plano)?** A estimativa do plano
pressupunha as memórias em **blocos M9K**. Aqui elas ficaram **em lógica**
(`0 memory bits`): a organização single-cycle lê instrução e dado de forma
**combinacional** (assíncrona, no mesmo ciclo), e o M9K só suporta leitura
**registrada** (síncrona). Logo, a RAM de dados 256×32 foi sintetizada como
~8.000 flip-flops (daí os 9.263 registradores) e a ROM como lógica de seleção.
É um **trade-off consciente**: a leitura assíncrona mantém o datapath single-cycle
simples e didático, ao custo de área — que sobra (29% do chip).
*Otimização registrada (fora de escopo):* migrar para leitura síncrona mapearia as
memórias em M9K e derrubaria drasticamente LEs/registradores; isso casa bem com o
clock-enable já existente (que dá folga de latência), mas muda o modelo de leitura.

### 3.7 Timing

O caminho combinacional single-cycle (ULA + memórias em lógica + double-dabble do
display) atinge **~38 MHz** isolado — abaixo dos 50 MHz da placa. O design contorna
isso por construção: **todo registrador só é habilitado a cada 16 ciclos** (clock-
enable `en`, gerado por um contador), então cada instrução dispõe de **320 ns**
(16 × 20 ns), não de 20 ns. Declarando esse **multicycle de 16** no `.sdc`, o Timing
Analyzer confirma o fechamento com **slack de setup de +294 ns** (hold +0,3 ns),
0 violações. Throughput efetivo da CPU ≈ 50 MHz / 16 ≈ **3,1 MHz** — instantâneo ao
olho para a calculadora.

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
