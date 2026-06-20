-------------------------------------------------------------------------------
-- imm_gen.vhd  —  Gerador de imediatos do RV32I (Frente B, etapa 3).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
-- Extrai e estende em sinal o imediato conforme o formato da instrução.
-- Todos os imediatos são estendidos a 32 bits a partir de instr[31] (bit de sinal),
-- exceto o U que preenche os 12 bits baixos com zero.
--
-- Layout dos imediatos (RISC-V Unprivileged ISA):
--   I: imm[11:0]  = instr[31:20]
--   S: imm[11:5]  = instr[31:25], imm[4:0] = instr[11:7]
--   B: imm[12]    = instr[31], imm[11] = instr[7],
--      imm[10:5]  = instr[30:25], imm[4:1] = instr[11:8], imm[0] = 0
--   U: imm[31:12] = instr[31:12], imm[11:0] = 0
--   J: imm[20]    = instr[31], imm[19:12] = instr[19:12],
--      imm[11]    = instr[20], imm[10:1] = instr[30:21], imm[0] = 0
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

entity imm_gen is
    port (
        instr   : in  std_logic_vector(31 downto 0);
        imm_sel : in  std_logic_vector(2 downto 0);
        imm     : out std_logic_vector(31 downto 0)
    );
end entity imm_gen;

architecture rtl of imm_gen is
    signal s : std_logic;  -- bit de sinal (instr[31])
begin
    s <= instr(31);

    process(instr, imm_sel, s)
    begin
        case imm_sel is
            when IMM_I =>
                imm <= (31 downto 11 => s) & instr(30 downto 20);

            when IMM_S =>
                imm <= (31 downto 11 => s) & instr(30 downto 25) & instr(11 downto 7);

            when IMM_B =>
                imm <= (31 downto 12 => s) & instr(7) &
                       instr(30 downto 25) & instr(11 downto 8) & '0';

            when IMM_U =>
                imm <= instr(31 downto 12) & (11 downto 0 => '0');

            when IMM_J =>
                imm <= (31 downto 20 => s) & instr(19 downto 12) &
                       instr(20) & instr(30 downto 21) & '0';

            when others =>
                imm <= (others => '0');
        end case;
    end process;

end architecture rtl;
