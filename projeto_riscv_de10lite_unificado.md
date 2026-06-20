# Projeto Desafio: Processador RISC-V em FPGA (DE10-Lite) — Documento Unificado

> Documento único reunindo o planejamento inicial (**Parte I**) e as atualizações
> posteriores (**Parte II**). Junho/2026.
>
> - **Parte I** — plano original: tudo que foi decidido na conversa de planejamento.
> - **Parte II** — atualizações: só o que é novo (decisões tomadas, fatos descobertos
>   na prática e o estado real de andamento, que não constavam no plano inicial).

---

# PARTE I — Planejamento inicial

## 1. Contexto

- **Disciplina:** Arquitetura e Organização de Computadores — PUCPR, Eng. de Computação, 7º período (2026/1), Prof. Valter Klein Junior.
- **Situação:** projeto-desafio **extracurricular e individual**, proposto pelo professor a pedido do aluno, que quis algo além do conteúdo da disciplina. O aluno **ainda não teve aula formal** sobre o assunto — o projeto avança em paralelo ao cronograma da disciplina.
- **A disciplina oficial** constrói um microprocessador didático de **8 bits com ISA própria** no Quartus II v9, em etapas: blocos básicos (LAB1–2) → ULA + máquina de estados (LAB3) → ROM + set de instruções + desvio condicional (LAB4) → RAM + LOAD/STORE (LAB5) → CALL/RET (LAB6).
- **O desafio** espelha essa progressão, mas usando a **ISA RISC-V real (RV32I)** em vez da ISA didática.

## 2. Decisões tomadas

| Item | Decisão | Justificativa |
|---|---|---|
| Placa | **DE10-Lite** (única placa do projeto) | MAX 10 10M50: ~50k LEs, ~1,6 Mbit RAM embarcada (M9K), 144 multiplicadores, 64 MB SDRAM, USB-Blaster embutido. DE2 e MAX II foram descartadas/devolvidas. |
| Chip alvo no Quartus | **10M50DAF484C7G** | FPGA da DE10-Lite. |
| Ferramenta | **Quartus Prime Lite 22.1** (+ Questa para simulação) | Suporta MAX 10, infere RAM em bloco automaticamente, timing analyzer moderno. O Quartus II 9.1 fica só para os LABs oficiais da disciplina. |
| ISA | **RISC-V RV32I** (subconjunto inteiro, 32 bits, 32 registradores) | ISA aberta, didática, referência do Patterson & Hennessy ed. RISC-V. |
| Organização | **Single-cycle** primeiro | Mais simples de entender/depurar; base para evoluir a multicycle/pipeline depois. |
| Linguagem | **VHDL** (parametrizado com `generic`) | Escolha do aluno. Usar **VHDL-2008** e a biblioteca `ieee.numeric_std` (nunca `std_logic_arith`). O Harris & Harris ed. RISC-V traz todos os exemplos também em VHDL. |
| Clock | 50 MHz da placa (pino P11) | Usar divisor/PLL se o caminho crítico exigir. |

## 3. As duas frentes do projeto

### Frente A — Experimento de escalabilidade da ULA ("quantos bits custam quanto")
Como a placa MAX II (CPLD de 240–570 LEs, sem RAM) foi devolvida, o experimento **"até estourar" virou um experimento comparativo** na própria DE10-Lite:

1. Escrever a **ULA do RV32I parametrizada em largura** (`generic (WIDTH : natural)`).
   - Operações exigidas pela ISA: **ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU**.
2. Sintetizar para **4, 8, 16, 32 e 64 bits**, anotando do *Compilation Report* do Quartus: LEs consumidos, registradores, Fmax.
3. Montar **tabela e gráfico LEs × largura** e analisar: o que cresce linear (somador, lógicas) vs. superlinear (barrel shifter)? O que limita Fmax?
4. (Opcional) Criar projeto apontando para um chip pequeno (ex.: MAX 10 10M02, ~2k LEs) só para *ver* o design apertar — compilação não exige a placa física.
5. Interface de demonstração na placa: operandos nas **chaves (SW)**, operação selecionável, resultado nos **LEDs/displays de 7 segmentos** — a "calculadora".

### Frente B — Processador RV32I single-cycle completo
Construído em etapas, sincronizado com o cronograma da disciplina:

| Etapa | Conteúdo | Espelha na disciplina |
|---|---|---|
| 1 | ULA RV32I (vem pronta da Frente A) | LAB3 |
| 2 | Banco de registradores 32×32 (x0 fixo em zero, 2 portas de leitura, 1 de escrita) | LAB1–2 |
| 3 | PC + memória de instruções (ROM inicializada com `.mif`/`.hex`) + decodificador dos formatos R/I/S/B/U/J + gerador de imediatos | LAB4 |
| 4 | Datapath single-cycle + unidade de controle: instruções tipo-R, ADDI e afins, BEQ/BNE | LAB4 |
| 5 | Memória de dados + **LW/SW** | LAB5 |
| 6 | **JAL/JALR** (chamadas de rotina via x1/ra) | LAB6 |
| 7 | I/O mapeado em memória (chaves e displays) → a calculadora vira **programa em assembly RISC-V rodando no próprio processador** | — |

**Validação em cada etapa:** testbench no Questa (simulação) **antes** de gravar na placa; depois teste físico com programas em assembly montados à mão ou com montador RISC-V.

## 4. Recursos da DE10-Lite relevantes

- FPGA MAX 10 10M50DAF484C7G: ~50.000 LEs, 1.638 Kbits RAM M9K, 144 mult. 18×18, ~5,9 Mbits de flash de configuração (UFM).
- 64 MB SDRAM externa (futuro: cache — conecta com o TDE01 da disciplina).
- 10 chaves deslizantes, 2 botões, 10 LEDs vermelhos, **6 displays de 7 segmentos**, acelerômetro, saída VGA, GPIO 2×20.
- Clock de 50 MHz. USB-Blaster II embutido (gravação direta via USB).
- Pinout completo: manual da Terasic / *System Builder*.

## 5. Ordem de grandeza esperada (sanidade)

- ULA 32 bits: algumas centenas de LEs (o shifter domina).
- RV32I single-cycle completo: ~2.000–4.000 LEs (≈5–10% do chip) + blocos M9K para memórias.
- Conclusão: cabe com enorme folga; o desafio técnico é **corretude e timing**, não área.

## 6. Próximos passos imediatos (começar pelo item 1)

> Nota: parte destes passos já foi executada — ver **Parte II, seções 4 e 7** para o estado atual.

1. Instalar Quartus Prime Lite 22.1 + Questa (o **Questa exige licença gratuita** — gerar no Self-Service Licensing Center da Intel e apontar a variável de ambiente `LM_LICENSE_FILE`); criar projeto alvo 10M50DAF484C7G.
2. Nas configurações do projeto, definir **VHDL-2008** (Settings → Compiler Settings → VHDL Input).
3. Escrever `alu.vhd` parametrizada (RV32I) + testbench; simular no Questa.
4. Sintetizar em 4/8/16/32/64 bits e preencher a tabela de recursos (Frente A).
5. Top-level "calculadora" com chaves/LEDs/7-seg e atribuição de pinos; gravar e demonstrar.
6. Partir para o banco de registradores (Frente B, etapa 2).

## 7. Referências de estudo

- **Patterson & Hennessy — Computer Organization and Design, RISC-V Edition** (bibliografia da disciplina; usar a edição RISC-V).
- **Harris & Harris — Digital Design and Computer Architecture, RISC-V Edition** (datapath single-cycle com exemplos em **VHDL** e SystemVerilog lado a lado, capítulo 7 — a referência mais direta para este projeto).
- Especificação oficial RISC-V (riscv.org) — *The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA* (capítulo RV32I).
- Manual da DE10-Lite (Terasic) — pinout e periféricos.
- RARS (RISC-V Assembler and Runtime Simulator) — para escrever/testar assembly antes de rodar no processador próprio.

---

# PARTE II — Atualizações do projeto

> Reúne **só o que é novo**: decisões tomadas, fatos descobertos na prática e o
> estado real de andamento, que não constavam (ou não estavam confirmados) na
> Parte I. Data desta atualização: junho/2026.

## 1. Mudança de estratégia: trabalho em casa, placa só em visitas

Decisão nova (não estava no plano original): o desenvolvimento passa a ser feito
**inteiramente em casa**, e a placa física na faculdade será usada **apenas em
idas pontuais** para gravar e testar no hardware. Motivação: evitar depender de
estar presencialmente com a DE10-Lite + Quartus para cada teste.

Isso é viável porque a maior parte do fluxo roda sem placa (ver seção 3).

## 2. Ambiente — estado real e fatos descobertos

### 2.1 Download mudou de lugar
O Quartus Prime Lite 22.1 e o Questa **não vêm pré-instalados** e agora são
distribuídos pelo site da **Altera** (a divisão de FPGAs da Intel voltou a operar
sob a marca Altera). Mesma ferramenta, URL nova:
`altera.com/downloads/...quartus-prime-lite-edition-design-software-version-22-1-2-windows`
(a 22.1.2 é a 22.1 com patches; a 22.1.1 também está disponível se quiser bater
exatamente com a versão da faculdade).

Para instalar do zero, baixar para a **mesma pasta temporária**:
- Quartus Prime Lite Edition (instalador principal);
- **MAX 10 device support** (`.qdz`) — sem ele o Quartus não reconhece o 10M50;
- Questa - Intel FPGA Starter Edition.

Espaço: ~14 GB (Lite) + ~5 GB (Questa).

### 2.2 Licença
- **Quartus Lite: não precisa de licença.**
- **Questa: precisa da licença gratuita.** Gerar no Self-Service Licensing Center
  da Intel/Altera, vinculada ao **MAC address** da máquina (obter com
  `ipconfig /all`, campo "Endereço Físico"). Salvar o `.dat` em pasta fixa e
  apontar a variável de ambiente `LM_LICENSE_FILE` para ele. A licença é por
  máquina — a de casa não conflita com a da faculdade, e pode-se gerar mais de uma
  na mesma conta.

### 2.3 Confusões de nomenclatura já identificadas (para não tropeçar de novo)
- A barra de título do Quartus mostra `...\Arq-DE10\DE10 - DE10`. Isso **não** é
  uma subpasta: é "pasta do projeto" + "nome do projeto". O projeto chama-se
  `DE10` e fica direto em `Arq-DE10` (onde está o `DE10.qpf`). **Não existe**
  subpasta `Arq-DE10\DE10`.
- O atalho do simulador no Iniciar aparece como **"Questa - Intel FPGA Starter
  Edition 2021.2 (Quartus Prime Pro 22.1std)"** — a rotulagem é confusa, mas é o
  simulador correto que acompanha o Lite.
- Arquivos `.vhd` aparecem no Windows como **"Arquivo de Imagem de disco"** (o
  Windows associa `.vhd` a Virtual Hard Disk). É só ícone; o conteúdo é texto.
  **Não dar duplo-clique** nesses arquivos fora do editor (o Windows tentaria
  "montar" como disco). Ativar "Extensões de nomes de arquivo" no Explorer para
  evitar confusão de nomes.
- `File → Change Directory` é comando do **Questa**, não do Quartus. Quartus
  (síntese) e Questa (simulação) são dois programas separados que se instalam
  juntos.

### 2.4 Estrutura de arquivos do projeto
Na pasta do projeto: `DE10.qpf` (ponteiro do projeto), `DE10.qsf` (onde mora tudo
que importa: lista de arquivos, chip, settings VHDL, futuros pinos — é texto puro)
e a pasta `db/` (lixo regenerável de compilação, pode apagar).

### 2.5 Cuidado com caminhos
Evitar acentos e espaços em qualquer pasta que Quartus/Questa toquem (as
ferramentas da Intel têm histórico ruim com isso). O usuário `pedro.braiti` com
ponto está ok.

## 3. O que roda SEM placa vs. o que EXIGE a placa (fato técnico confirmado)

Esta separação é a base da estratégia "tudo em casa". Foi verificada:

**Roda 100% em casa, por GUI ou por linha de comando/terminal:**
- Escrita de VHDL.
- **Simulação no Questa** — totalmente CLI: `vlib`, `vcom -2008`,
  `vsim -c -do "run -all"` (modo console, sem janela). Valida se a lógica calcula
  certo. É aqui que se passa a maior parte do tempo.
- **Síntese e relatórios no Quartus** — totalmente CLI via `quartus_map`
  (Analysis & Synthesis), `quartus_fit` (Fitter), `quartus_sta` (Timing Analyzer),
  `quartus_asm` (gera `.sof`), orquestráveis por scripts **Tcl**
  (`quartus_sh --flow compile`). Toda a coleta da Frente A (LEs/Fmax em 4/8/16/32/64
  bits) pode virar um loop de script — muito melhor que cliques manuais.
- Geração de `.mif`/`.hex`, montagem de assembly, gráficos/tabelas.

**Exige a placa fisicamente conectada (USB-Blaster):**
- **Gravar o `.sof` na FPGA** (`quartus_pgm`) — o comando existe, mas conversa com
  o USB-Blaster, que precisa de um DE10-Lite real plugado. Nenhum terminal simula
  o silício físico.
- Validação física: timing real, pinos, chaves/botões (com bounce), displays
  multiplexados, e a **demonstração final** para o professor.

Nuance técnica: a simulação padrão do Questa é **comportamental** (lógica pura,
sem atrasos). Existe a *gate-level/post-fit simulation* com timing (`.sdo`), mais
próxima do hardware, mas ainda é modelo — não substitui o teste físico no relatório
final.

Regra de ouro mantida do documento original: **nada vai para a placa sem antes
passar na simulação.**

## 4. Estado de andamento real (o que foi efetivamente feito)

Na máquina da faculdade, já realizado e confirmado:
- Projeto criado no Quartus, chip-alvo **10M50DAF484C7G**, VHDL-2008 ativado.
- `alu.vhd` (ULA RV32I parametrizada) escrita e **sintetizando limpo: 0 erros**.
- `tb_alu.vhd` (testbench com casos-armadilha) escrito.

**Resultados de síntese da ULA 32 bits (primeiro dado real da Frente A):**
- **684 logic elements** (dentro da previsão "algumas centenas" do documento).
- **0 registradores** (correto: ULA é puramente combinacional; registrador aqui
  indicaria latch inferido = bug).
- **101 pinos de I/O** (confere: a[32] + b[32] + alu_op[4] + result[32] + zero[1]).
- ~94 LEs em "arithmetic mode" (cadeias de carry do somador/subtrator); ~590 em
  "normal mode" (lógicas + muxes dos barrel shifters — o shifter domina, como
  previsto).

**Pendência crítica:** o testbench **ainda não foi executado** no Questa. A ULA
está *sintetizada* mas **não validada funcionalmente**. Síntese limpa só prova
sintaxe, não corretude (não garante, p.ex., que SLT/SLTU não estão trocados).
→ Primeiro passo assim que o ambiente de casa estiver pronto: rodar o testbench.

**Nota de portabilidade:** o ambiente de casa será instalado do zero (nada vem
pré-instalado). O projeto precisa ser recriado lá (New Project Wizard, mesmo chip,
VHDL-2008) e os arquivos `alu.vhd` e `tb_alu.vhd` já foram salvos para levar.
Sugestão registrada: versionar os arquivos de texto (`.vhd`, `.qsf`, `.qpf`) em
Git ou nuvem, deixando de fora as pastas regeneráveis (`db/`, `incremental_db/`,
`output_files/`), para evitar divergência entre a máquina de casa e a da faculdade.

## 5. Decisão de codificação já fixada na ULA (contrato para etapas futuras)

A codificação do sinal `alu_op` (4 bits) **não é arbitrária** e vira um contrato
com a futura unidade de controle (etapa 4 da Frente B):
- `alu_op(2 downto 0)` = campo **funct3** da instrução RISC-V;
- `alu_op(3)` = bit 30 da instrução (**funct7(5)**), que distingue ADD/SUB e
  SRL/SRA.

Tabela fixada: ADD=0000, SUB=1000, SLL=0001, SLT=0010, SLTU=0011, XOR=0100,
SRL=0101, SRA=1101, OR=0110, AND=0111. Isso deixará a unidade de controle quase
trivial mais à frente.

## 6. Sobre Fmax (esclarecimento técnico para a Frente A)

O Resource Usage Summary da síntese **não fornece Fmax** para a ULA, e o motivo é
conceitual: **Fmax é definido entre registradores**, e a ULA não tem nenhum. Para
medir o Fmax do caminho combinacional, será preciso um **wrapper** com registradores
na entrada e na saída, deixando o Timing Analyzer medir o miolo. Isso fica para a
fase de coleta da Frente A; por enquanto, LEs × largura já rende o gráfico principal.

## 7. Próximos passos concretos (ordem)

1. Instalar Quartus + Questa em casa (seção 2) e recriar o projeto.
2. **Rodar o testbench no Questa** e fechar a validação da ULA (débito atual).
3. Frente A: compilar a ULA em 4/8/16/32/64 bits, coletar LEs/Fmax, montar
   tabela e gráfico (automatizável por Tcl).
4. Seguir para o banco de registradores (Frente B, etapa 2).
