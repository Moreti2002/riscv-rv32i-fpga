-------------------------------------------------------------------------------
-- riscv_pkg.vhd  —  Constantes da ISA RV32I (opcodes, funct3, formatos).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
-- Centraliza os campos da instrução para todos os módulos (decoder, controle,
-- gerador de imediatos) ficarem consistentes. Referência: RISC-V Unprivileged
-- ISA, capítulo RV32I.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package riscv_pkg is

    constant XLEN : natural := 32;

    -- Vetor de palavras de 32 bits — usado para inicializar a ROM de instruções
    -- como CONSTANTE VHDL (gerada pelo montador), evitando leitura de arquivo em
    -- síntese (o Quartus 22.1 não executa file I/O na elaboração).
    type word_array is array (natural range <>) of std_logic_vector(31 downto 0);

    ---------------------------------------------------------------------------
    -- Opcodes (instr[6:0]) usados nesta cobertura "intermediária".
    ---------------------------------------------------------------------------
    constant OPC_RTYPE  : std_logic_vector(6 downto 0) := "0110011"; -- ADD,SUB,...
    constant OPC_ITYPE  : std_logic_vector(6 downto 0) := "0010011"; -- ADDI,...
    constant OPC_LOAD   : std_logic_vector(6 downto 0) := "0000011"; -- LW (LB/LH/...)
    constant OPC_STORE  : std_logic_vector(6 downto 0) := "0100011"; -- SW (SB/SH)
    constant OPC_BRANCH : std_logic_vector(6 downto 0) := "1100011"; -- BEQ,BNE,...
    constant OPC_JAL    : std_logic_vector(6 downto 0) := "1101111"; -- JAL
    constant OPC_JALR   : std_logic_vector(6 downto 0) := "1100111"; -- JALR
    constant OPC_LUI    : std_logic_vector(6 downto 0) := "0110111"; -- LUI
    constant OPC_AUIPC  : std_logic_vector(6 downto 0) := "0010111"; -- AUIPC

    ---------------------------------------------------------------------------
    -- funct3 — significado depende do opcode.
    ---------------------------------------------------------------------------
    -- Aritmética/lógica (R-type e I-type): igual ao campo alu_op(2..0).
    constant F3_ADD_SUB : std_logic_vector(2 downto 0) := "000";
    constant F3_SLL     : std_logic_vector(2 downto 0) := "001";
    constant F3_SLT     : std_logic_vector(2 downto 0) := "010";
    constant F3_SLTU    : std_logic_vector(2 downto 0) := "011";
    constant F3_XOR     : std_logic_vector(2 downto 0) := "100";
    constant F3_SR      : std_logic_vector(2 downto 0) := "101";  -- SRL/SRA
    constant F3_OR      : std_logic_vector(2 downto 0) := "110";
    constant F3_AND     : std_logic_vector(2 downto 0) := "111";

    -- Branches (funct3 do opcode BRANCH).
    constant F3_BEQ     : std_logic_vector(2 downto 0) := "000";
    constant F3_BNE     : std_logic_vector(2 downto 0) := "001";
    constant F3_BLT     : std_logic_vector(2 downto 0) := "100";
    constant F3_BGE     : std_logic_vector(2 downto 0) := "101";
    constant F3_BLTU    : std_logic_vector(2 downto 0) := "110";
    constant F3_BGEU    : std_logic_vector(2 downto 0) := "111";

    -- Loads/Stores (largura do acesso). LW/SW são o essencial desta etapa.
    constant F3_LB      : std_logic_vector(2 downto 0) := "000";
    constant F3_LH      : std_logic_vector(2 downto 0) := "001";
    constant F3_LW      : std_logic_vector(2 downto 0) := "010";
    constant F3_LBU     : std_logic_vector(2 downto 0) := "100";
    constant F3_LHU     : std_logic_vector(2 downto 0) := "101";
    constant F3_SB      : std_logic_vector(2 downto 0) := "000";
    constant F3_SH      : std_logic_vector(2 downto 0) := "001";
    constant F3_SW      : std_logic_vector(2 downto 0) := "010";

    ---------------------------------------------------------------------------
    -- Seleção da fonte do imediato (gerador de imediatos).
    ---------------------------------------------------------------------------
    constant IMM_I : std_logic_vector(2 downto 0) := "000";
    constant IMM_S : std_logic_vector(2 downto 0) := "001";
    constant IMM_B : std_logic_vector(2 downto 0) := "010";
    constant IMM_U : std_logic_vector(2 downto 0) := "011";
    constant IMM_J : std_logic_vector(2 downto 0) := "100";

    ---------------------------------------------------------------------------
    -- Seleção da fonte do resultado a escrever no registrador (WB mux).
    ---------------------------------------------------------------------------
    constant WB_ALU  : std_logic_vector(1 downto 0) := "00"; -- saída da ULA
    constant WB_MEM  : std_logic_vector(1 downto 0) := "01"; -- dado da memória (LW)
    constant WB_PC4  : std_logic_vector(1 downto 0) := "10"; -- PC+4 (JAL/JALR)
    constant WB_IMM  : std_logic_vector(1 downto 0) := "11"; -- imediato (LUI)

end package riscv_pkg;
