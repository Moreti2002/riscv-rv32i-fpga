# Decisões de arquitetura — Perguntas & Respostas

> Complemento ao documento unificado do projeto RISC-V (DE10-Lite). Reúne as
> decisões de arquitetura que estavam em aberto na descrição do projeto, separando
> claramente:
> - **[ALUNO]** — decisão tomada pelo aluno (Pedro);
> - **[ASSUMIDO]** — default técnico que adotei por convenção; **precisa de
>   confirmação** do aluno, mas é seguro seguir com ele.
>
> Objetivo: transformar a descrição do projeto em especificação executável, sem
> deixar nenhuma escolha de projeto implícita. Junho/2026.

---

## Parte A — Decisões do aluno (respondidas)

### A1. Tamanho das memórias (ROM/RAM) — [ALUNO + ASSUMIDO]
**Pergunta:** os programas de teste e a calculadora final serão pequenos (dezenas
de instruções) ou maiores? Isso define quantas palavras reservar.

**Resposta:** seguir o recomendado.
- **ROM de instruções: 256 palavras de 32 bits.**
- **RAM de dados: 256 palavras de 32 bits.**
- Folgado para o escopo; cada uma ocupa um bloco M9K (a DE10-Lite tem de sobra).
- Endereçamento por byte (ver A6), então cada memória cobre 256×4 = 1024 bytes de
  espaço de endereço.

### A2. Reset — [ALUNO]
**Pergunta:** botão de reset físico, ou reset automático no power-on?

**Resposta:** **botão físico.**
- Usar um dos botões da placa (KEY0 ou KEY1) como reset.
- Mais demonstrável na defesa ("reinicio e o processador recomeça do início").
- Detalhe a confirmar na implementação: os botões da DE10-Lite são **ativos em
  zero** (lê '0' quando pressionado) — o reset precisa tratar isso.
- Estratégia de reset: ver A7 (decisão assumida).

### A3. Ambição da calculadora (etapa 7) — [ALUNO]
**Pergunta:** calculadora simples (dois operandos pelas chaves, operação
selecionável, resultado no display) ou algo mais elaborado (acumulador, sequência)?

**Resposta:** **versão simples.**
- Entra operando A e operando B pelas chaves (SW), seleciona a operação, vê o
  resultado nos displays.
- A calculadora é um **programa em assembly RISC-V** rodando no próprio processador
  (não lógica dedicada) — é isso que prova que o processador funciona de verdade.

### A4. Formato do display — [ALUNO]
**Pergunta:** resultado em hexadecimal (trivial) ou decimal (exige conversão
binário→BCD)?

**Resposta:** **decimal, com conversão.**
- Exige um bloco de conversão **binário → BCD** (algoritmo clássico:
  *double dabble* / shift-and-add-3), depois cada dígito BCD vira segmentos.
- Custo: um bloco a mais e uma pergunta de defesa a mais ("como você converte
  binário para decimal em hardware?"). Decisão consciente do aluno.
- Nota de projeto: 6 displays mostram até 6 dígitos decimais (0–999999). Um valor
  de 32 bits chega a ~4,29 bilhões (10 dígitos), que **não cabe** em 6 displays.
  → A confirmar na implementação: limitar o range demonstrado, ou exibir só os
    6 dígitos decimais menos significativos, ou tratar sinal. (Decidir junto na
    etapa 7; não bloqueia o resto.)

### A5. Escopo do processador — [ALUNO]
**Pergunta:** RV32I single-cycle completo (7 etapas, JAL/JALR) ou subconjunto
demonstrável?

**Resposta:** **escopo completo** — todas as 7 etapas, incluindo JAL/JALR.
- O aluno avalia que há tempo.
- Recomendação registrada: implementar **nesta ordem de etapas** (a do documento),
  validando cada uma no Questa antes de seguir. Assim, se o tempo apertar perto do
  fim, há sempre uma versão funcional e demonstrável (degradação graciosa), em vez
  de tudo meio-pronto.

---

## Parte B — Defaults técnicos assumidos (convenção; confirmar)

> Estes não são preferências pessoais: são as escolhas-padrão de um RV32I
> single-cycle didático. Adotados para destravar a especificação. Marcados para
> revisão do aluno.

### A6. Endereçamento por byte — [ASSUMIDO / obrigatório pela ISA]
- A spec RISC-V usa **endereçamento por byte**. Não é escolha — é a ISA.
- PC e endereços avançam de **4 em 4** entre instruções (cada instrução = 4 bytes).
- Impacta o gerador de imediatos e o cálculo de alvo dos branches/jumps.

### A7. Estratégia de reset — [ASSUMIDO]
- **Reset síncrono, ativo conforme o botão (ativo-baixo) da placa.**
- No reset: **PC ← 0** (primeira instrução da ROM no endereço 0).
- Registradores do banco: não precisam de reset explícito (x0 é sempre zero por
  construção; os demais são definidos pelo programa antes do uso). O PC é o que
  importa resetar.

### A8. Largura do PC — [ASSUMIDO]
- **PC de 32 bits inteiros.**
- Economizar bits (já que a ROM só usa os baixos) seria otimização prematura que
  complica a defesa sem ganho real de área relevante.

### A9. Tratamento de desalinhamento e instruções inválidas — [ASSUMIDO]
- **Não tratados** (assume-se programas bem-comportados, alinhados).
- Comportamento padrão de processador didático single-cycle.
- Limitação **documentada**: num processador real haveria exceções (traps); aqui,
  fora de escopo. Boa de mencionar na defesa como "limitação conhecida e consciente".

### A10. Conjunto de instruções por etapa — [ASSUMIDO]
Enumeração derivada da spec RV32I, casada com as etapas do documento:
- **Etapa 4 (tipo-R + tipo-I aritm. + branches):**
  - Tipo-R: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU.
  - Tipo-I aritm.: ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI.
  - Branches: BEQ, BNE (e, se sobrar fôlego, BLT, BGE, BLTU, BGEU).
- **Etapa 5 (memória):** LW, SW (e opcionalmente LB/LH/LBU/LHU/SB/SH se quiser
  cobrir todos os tamanhos — confirmar; LW/SW já fecham o essencial).
- **Etapa 6 (saltos):** JAL, JALR.
- **Tipo-U:** LUI, AUIPC (necessárias para montar imediatos de 32 bits; incluir).
- A confirmar com o aluno quão exaustiva fica a cobertura (essencial vs. RV32I
  100% completo). O contrato de `alu_op` já fixado cobre todas as operações de ULA
  necessárias.

### A11. Wrapper de Fmax + arquivo SDC — [ASSUMIDO]
- Para medir Fmax da ULA combinacional: criar um **wrapper** com registrador na
  entrada e registrador na saída, isolando o caminho combinacional entre dois
  flip-flops.
- Criar um arquivo **`.sdc`** com um `create_clock` no clock do wrapper; o
  `quartus_sta` então reporta o Fmax (slack do caminho registrador→registrador).
- Sem o `.sdc`, o Timing Analyzer não dá Fmax útil. Esse wrapper é só instrumento
  de medida da Frente A — não faz parte do processador.

### A12. Nota sobre a ULA de 64 bits (Frente A) — [ASSUMIDO / esclarecimento]
- A ULA é parametrizável e compila em 64 bits para o experimento de escalabilidade.
- **Isso não é mais RV32I** — é o instrumento de medida esticado além da ISA, só
  para observar como a área (sobretudo o barrel shifter) cresce com a largura.
- Registrar isso explicitamente evita a pergunta-armadilha "por que 64 bits se a
  ISA é de 32?". Resposta: é experimento de escalabilidade, não parte do processador.

---

## Parte C — Itens que continuam dependendo de hardware/decisão futura

Não são lacunas de especificação, mas ficam registrados para não se perderem:

1. **Mapa de memória (endereços de ROM, RAM e I/O):** ainda a definir em detalhe na
   etapa 5/7. Esboço inicial sugerido (a confirmar):
   - ROM de instruções: base `0x0000_0000`.
   - RAM de dados: base `0x0000_1000` (ou outra região não sobreposta).
   - I/O mapeado (chaves, botões, displays): base alta, ex. `0x0000_2000`, com
     endereços distintos para entrada (SW/KEY) e saída (displays/LEDs).
   - Decisão final quando chegar nas etapas 5 e 7.
2. **Arquivo de pinos (.qsf) da DE10-Lite:** clock P11, SW, KEY, LEDR, HEX0–HEX5.
   Há um `.qsf`/pin assignment de referência da Terasic que economiza digitação —
   buscar no material da placa.
3. **Driver dos displays de 7 segmentos:** decodificador de dígito→segmentos +
   multiplexação dos 6 displays. Bloco a especificar na etapa 7 (e agora também a
   conversão binário→BCD por causa da decisão A4).
4. **Tudo que exige a placa física:** gravação do `.sof`, validação de timing real,
   teste de chaves/botões/displays, demonstração final. (Ver documento unificado,
   Parte II, seção 3.)

---

## Resumo das pendências de confirmação

Para o aluno revisar quando puder (nenhuma bloqueia o início):
- **A4:** como exibir 32 bits em 6 dígitos decimais (limitar range? sinal?).
- **A10:** cobertura de instruções — essencial (LW/SW) ou RV32I completo
  (LB/LH/.../SB/SH)?
- **Parte C.1:** endereços finais do mapa de memória.
