# Guia de uso — Processador RISC-V RV32I na DE10-Lite

> Como instalar, simular, sintetizar e gravar. Autor: João Moreti.
> Veja também `../HANDOFF.md` (estado/pendências) e os dois `.md` de especificação.

---

## 0. Estrutura do repositório

```
src/alu/    alu.vhd, alu_fmax_wrapper.vhd          ULA parametrizada + wrapper de Fmax
src/cpu/    riscv_pkg, regfile, imm_gen, control,   núcleo RV32I single-cycle
            branch_unit, imem, dmem, riscv_core,
            riscv_system
src/io/     bin2bcd, seg7, display_unit,            I/O, display decimal e top-level
            riscv_de10lite
sim/        tb_*.vhd, run_all.do, run_alu.do        testbenches + scripts Questa
scripts/    asm.py, sweep_alu.tcl, plot_sweep.py,   montador, automação Frente A,
            install_tools.ps1, install_launch.ps1   instalação
sdc/        alu_fmax.sdc, riscv_de10lite.sdc        constraints de timing
asm/        test_core.s, calc.s                     programas assembly
mem/        *.hex, *.mif                             ROM montada
reports/    alu_sweep.csv, fmax/                     saídas da Frente A
docs/       GUIA.md, relatorio.md, *.png            documentação e gráficos
riscv_de10lite.qpf/.qsf                              projeto Quartus da placa
```

---

## 1. Instalação das ferramentas (passo manual — uma vez)

Os instaladores já estão baixados em `D:\altera_installers\`. A instalação exige
**elevação (UAC)**, que precisa de aprovação humana.

**Opção A (mais fácil):** dê duplo-clique em `scripts\install_launch.ps1` e clique
**"Sim"** no UAC. Instala Quartus Lite + Questa em `D:\altera_lite\22.1`
(silencioso, ~15–20 min). Log em `D:\altera_installers\install_tools.log`.

**Opção B:** abra o **PowerShell como Administrador** e rode:
```powershell
& 'C:\Users\joaom\Documents\Trab_AOC\scripts\install_tools.ps1'
```

Verificação: deve existir `D:\altera_lite\22.1\quartus\bin64\quartus_sh.exe`.

### PATH (para usar por linha de comando)
Adicione ao PATH da sessão (ou permanente):
```
D:\altera_lite\22.1\quartus\bin64
D:\altera_lite\22.1\questa_fse\win64     (ajuste se o nome da pasta diferir)
```

---

## 2. Licença gratuita do Questa (passo manual — só para SIMULAR)

O **Quartus (síntese) NÃO precisa de licença**. O **Questa precisa** de licença
gratuita, vinculada ao MAC da máquina:

1. Obtenha o MAC: `ipconfig /all` → campo **"Endereço Físico"** do adaptador
   principal (ex.: `AA-BB-CC-DD-EE-FF`).
2. Acesse o **Self-Service Licensing Center** da Intel/Altera, faça login e gere
   uma licença **Questa - Intel FPGA Starter Edition** para esse MAC.
3. Salve o `.dat` em pasta fixa **sem espaços/acentos** (ex.: `D:\altera_lite\license.dat`).
4. Defina a variável de ambiente:
   ```powershell
   setx LM_LICENSE_FILE "D:\altera_lite\license.dat"
   ```
   (reabra o terminal depois do `setx`).

---

## 3. Simulação (Questa) — valida a lógica

A partir de `sim/`:
```bash
# todos os testbenches de uma vez:
vsim -c -do run_all.do

# ou um por um, ex. a ULA:
vsim -c -do run_alu.do
```
**Sucesso** = cada testbench imprime `ALL TESTS PASSED` e nenhum `FAIL`.
Testbenches: `tb_alu`, `tb_regfile`, `tb_bin2bcd`, `tb_core` (programa completo),
`tb_calc` (calculadora).

---

## 4. Frente A — escalabilidade da ULA (Quartus, SEM licença)

A partir da raiz do repo:
```bash
quartus_sh -t scripts/sweep_alu.tcl     # compila 4/8/16/32/64 bits, gera CSV
python scripts/plot_sweep.py            # gera os gráficos em docs/
```
Saídas: `reports/alu_sweep.csv`, `docs/alu_le_vs_width.png`, `docs/alu_fmax_vs_width.png`.

---

## 5. Síntese do processador completo (Quartus, SEM licença)

```bash
# síntese (Analysis & Synthesis) — valida que todo o VHDL elabora:
quartus_map riscv_de10lite

# fluxo completo (síntese + fitter + timing + .sof):
quartus_sh --flow compile riscv_de10lite
```
O `.sof` sai em `output_files/riscv_de10lite.sof`.

---

## 6. Montar um novo programa assembly

```bash
python scripts/asm.py asm/calc.s -o mem/calc.hex --mif mem/calc.mif --words 256
```

---

## 7. Gravar na placa (passo manual — EXIGE a DE10-Lite física)

Com a placa conectada (USB-Blaster):
```bash
quartus_pgm -m jtag -o "p;output_files/riscv_de10lite.sof"
```
Depois: `SW[3:0]`=A, `SW[7:4]`=B, `SW[9:8]`=operação (00=+ 01=- 10=& 11=|),
resultado em decimal nos HEX, `KEY0`=reset.

---

## 8. O que ainda depende de intervenção manual

- 🔴 **Placa física DE10-Lite** — gravação do `.sof`, timing real, demonstração.
- 🟡 **Licença do Questa** — necessária só para simular (seção 2).
- 🟡 **Instalação** — aprovar a elevação uma vez (seção 1).
