# Processador RISC-V RV32I em FPGA

Processador **RISC-V RV32I single-cycle** implementado em **VHDL-2008**, com uma
**calculadora em assembly** rodando sobre ele. O mesmo código RTL foi sintetizado e
executado em duas placas FPGA diferentes: **DE10-Lite (MAX 10)** e **DE2 (Cyclone II)**.

## Características

| Item | Descrição |
|---|---|
| ISA | RISC-V RV32I (inteiro, 32 bits) |
| Microarquitetura | Single-cycle (uma instrução por ciclo) |
| Instruções | Tipo-R, tipo-I, 6 branches (BEQ/BNE/BLT/BGE/BLTU/BGEU), LW/SW, JAL/JALR, LUI/AUIPC |
| Registradores | 32 × 32 bits (x0 fixo em zero) |
| ULA | 10 operações (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU) |
| Memórias | ROM 256×32 (instruções) e RAM 256×32 (dados), endereçadas por byte |
| Entrada/Saída | Mapeada em memória (chaves, botões, LEDs e displays) |
| Display | Decimal com sinal (conversão binário→BCD por *double-dabble*) |
| Linguagem | VHDL-2008 |
| Verificação | 5 testbenches em GHDL (todos passam) |

## A calculadora

A demonstração é um programa em assembly (`asm/calc.s`) do tipo **acumulador**, que roda
no próprio processador.

| Controle | Função |
|---|---|
| `SW[7:0]` | Valor a aplicar (0–255, em binário) |
| `SW[9:8]` | Operação: `00`=+ · `01`=− · `10`=& · `11`=\| |
| `KEY1` | Enter/= (aplica `acc = acc <op> valor`) |
| `KEY0` | Limpar (zera o acumulador) |
| `HEX0–5` | Resultado em decimal com sinal |
| `LEDR8` / `LEDR9` | Sinal negativo / overflow |

## Estrutura do repositório

```
.
├── riscv_de10lite.qpf / .qsf   Projeto Quartus (DE10-Lite / MAX 10)
├── src/
│   ├── alu/   alu.vhd, alu_fmax_wrapper.vhd
│   ├── cpu/   riscv_pkg, regfile, imm_gen, control, branch_unit,
│   │          imem, dmem, riscv_core, riscv_system
│   └── io/    bin2bcd, seg7, display_unit, riscv_de10lite (top-level)
├── asm/       calc.s (calculadora), calc_simple.s, test_core.s
├── mem/       calc.hex / .mif / calc_rom_pkg.vhd (ROM gerada)
├── sim/       testbenches (tb_*.vhd) + run_all_ghdl.sh
├── sdc/       constraints de timing
├── scripts/   asm.py (montador), sweep_alu.tcl, plot_sweep.py
└── board_de2/ porte para a DE2 (Cyclone II): riscv_de2.vhd, .qsf, .sdc, .qpf
```

## Como compilar, simular e gravar

> São necessárias duas versões do Quartus por causa das famílias: **Quartus Prime Lite 22.1**
> para o MAX 10 (DE10-Lite) e **Quartus II 13.0sp1** para o Cyclone II (DE2), que é uma
> família legada não suportada pelo Quartus moderno.

**1. Montar a calculadora (assembly para ROM):**
```bash
python scripts/asm.py asm/calc.s -o mem/calc.hex --mif mem/calc.mif \
       --vhdl mem/calc_rom_pkg.vhd --words 256
```

**2. Simular (GHDL, livre e sem licença):**
```bash
bash sim/run_all_ghdl.sh        # esperado: os 5 testbenches imprimem "ALL TESTS PASSED"
```

**3. Sintetizar e gravar na DE10-Lite (Quartus Prime 22.1):**
```bash
quartus_sh --flow compile riscv_de10lite
quartus_pgm -m jtag -o "p;output_files/riscv_de10lite.sof"
```

**4. Sintetizar e gravar na DE2 (Quartus II 13.0sp1):**
```bash
cd board_de2
quartus_sh --flow compile riscv_de2
quartus_pgm -m jtag -o "p;output_files/riscv_de2.sof"
```

O bitstream (`.sof`) é saída de build (não versionado); gere-o com os comandos acima.

## Portabilidade

O núcleo do processador é o mesmo nas duas placas. Para a DE2 (Cyclone II), apenas um
*wrapper* (`board_de2/riscv_de2.vhd`) adapta o clock e a largura dos displays — o RTL do
processador não é alterado.

## Ferramentas

- **Quartus Prime Lite 22.1** — síntese para MAX 10.
- **Quartus II 13.0sp1** — síntese para Cyclone II (família legada).
- **GHDL** — simulação VHDL-2008.
- **Python** — montador próprio (`scripts/asm.py`).
