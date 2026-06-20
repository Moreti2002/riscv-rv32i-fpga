-------------------------------------------------------------------------------
-- control.vhd  —  Unidade de controle single-cycle do RV32I (Frente B, etapa 4).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
-- Decodifica opcode + funct3 + instr[30] e gera os sinais de controle do datapath.
-- Aproveita o contrato alu_op (alu_op = {instr[30], funct3}) para deixar a
-- geração da ULA quase trivial.
--
-- SUTILEZA IMPORTANTE: em instruções I-type, instr[30] faz parte do IMEDIATO,
-- não de funct7. Logo, instr[30] só pode ir para alu_op(3) quando funct3 = "101"
-- (SRLI/SRAI). Em ADDI (funct3="000"), forçar alu_op(3)=0, senão um imediato com
-- bit 30 = 1 viraria SUBI por engano. Esse é o bug clássico aqui.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.riscv_pkg.all;

entity control is
    port (
        opcode    : in  std_logic_vector(6 downto 0);
        funct3    : in  std_logic_vector(2 downto 0);
        instr30   : in  std_logic;                       -- instr[30] = funct7(5)
        -- sinais de controle
        reg_write : out std_logic;
        alu_src   : out std_logic;                       -- ULA B: 0=rs2, 1=imm
        alu_a_src : out std_logic;                       -- ULA A: 0=rs1, 1=PC
        alu_op    : out std_logic_vector(3 downto 0);
        imm_sel   : out std_logic_vector(2 downto 0);
        mem_read  : out std_logic;
        mem_write : out std_logic;
        wb_sel    : out std_logic_vector(1 downto 0);
        branch    : out std_logic;                       -- é instrução de branch
        jump      : out std_logic;                       -- JAL
        jalr      : out std_logic                        -- JALR
    );
end entity control;

architecture rtl of control is
begin
    process(opcode, funct3, instr30)
    begin
        -- Defaults seguros (instrução não-reconhecida = NOP que não escreve nada).
        reg_write <= '0';
        alu_src   <= '1';
        alu_a_src <= '0';
        alu_op    <= "0000";          -- ADD
        imm_sel   <= IMM_I;
        mem_read  <= '0';
        mem_write <= '0';
        wb_sel    <= WB_ALU;
        branch    <= '0';
        jump      <= '0';
        jalr      <= '0';

        case opcode is
            ---------------------------------------------------------------
            when OPC_RTYPE =>
                reg_write <= '1';
                alu_src   <= '0';                 -- usa rs2
                alu_op    <= instr30 & funct3;    -- contrato direto
                wb_sel    <= WB_ALU;

            ---------------------------------------------------------------
            when OPC_ITYPE =>
                reg_write <= '1';
                alu_src   <= '1';                 -- usa imediato
                imm_sel   <= IMM_I;
                wb_sel    <= WB_ALU;
                if funct3 = F3_SR then
                    -- SRLI/SRAI: instr[30] distingue lógico/aritmético.
                    alu_op <= instr30 & funct3;
                else
                    -- demais I-type (ADDI, SLLI, etc.): bit 30 é imediato → 0.
                    alu_op <= '0' & funct3;
                end if;

            ---------------------------------------------------------------
            when OPC_LOAD =>
                reg_write <= '1';
                alu_src   <= '1';
                imm_sel   <= IMM_I;
                alu_op    <= "0000";              -- endereço = rs1 + imm
                mem_read  <= '1';
                wb_sel    <= WB_MEM;

            ---------------------------------------------------------------
            when OPC_STORE =>
                alu_src   <= '1';
                imm_sel   <= IMM_S;
                alu_op    <= "0000";              -- endereço = rs1 + imm
                mem_write <= '1';

            ---------------------------------------------------------------
            when OPC_BRANCH =>
                alu_src   <= '0';
                imm_sel   <= IMM_B;
                branch    <= '1';                 -- decisão fica no branch_unit

            ---------------------------------------------------------------
            when OPC_JAL =>
                reg_write <= '1';
                imm_sel   <= IMM_J;
                wb_sel    <= WB_PC4;              -- rd <- PC+4
                jump      <= '1';

            ---------------------------------------------------------------
            when OPC_JALR =>
                reg_write <= '1';
                alu_src   <= '1';
                imm_sel   <= IMM_I;
                alu_op    <= "0000";              -- alvo = rs1 + imm
                wb_sel    <= WB_PC4;
                jalr      <= '1';

            ---------------------------------------------------------------
            when OPC_LUI =>
                reg_write <= '1';
                imm_sel   <= IMM_U;
                wb_sel    <= WB_IMM;             -- rd <- imm (já com <<12)

            ---------------------------------------------------------------
            when OPC_AUIPC =>
                reg_write <= '1';
                alu_src   <= '1';
                alu_a_src <= '1';               -- ULA A = PC
                imm_sel   <= IMM_U;
                alu_op    <= "0000";            -- rd <- PC + imm
                wb_sel    <= WB_ALU;

            ---------------------------------------------------------------
            when others =>
                null;                            -- mantém defaults (NOP)
        end case;
    end process;

end architecture rtl;
