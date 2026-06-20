-------------------------------------------------------------------------------
-- branch_unit.vhd  —  Decisão de desvio condicional do RV32I.
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
-- Calcula as comparações próprias (eq, lt com sinal, lt sem sinal) a partir de
-- rs1/rs2 — desacoplado da ULA, que fica livre para outras operações. Decide se
-- o branch é tomado conforme funct3.
--
--   BEQ  (000): a == b        BNE  (001): a != b
--   BLT  (100): a <  b (sgn)  BGE  (101): a >= b (sgn)
--   BLTU (110): a <  b (uns)  BGEU (111): a >= b (uns)
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

entity branch_unit is
    port (
        a       : in  std_logic_vector(31 downto 0);  -- rs1
        b       : in  std_logic_vector(31 downto 0);  -- rs2
        funct3  : in  std_logic_vector(2 downto 0);
        branch  : in  std_logic;                      -- instrução é branch
        take    : out std_logic                       -- desvio tomado
    );
end entity branch_unit;

architecture rtl of branch_unit is
    signal eq, lt, ltu : std_logic;
begin
    eq  <= '1' when a = b else '0';
    lt  <= '1' when signed(a)   < signed(b)   else '0';
    ltu <= '1' when unsigned(a) < unsigned(b) else '0';

    process(funct3, branch, eq, lt, ltu)
        variable cond : std_logic;
    begin
        case funct3 is
            when F3_BEQ  => cond := eq;
            when F3_BNE  => cond := not eq;
            when F3_BLT  => cond := lt;
            when F3_BGE  => cond := not lt;
            when F3_BLTU => cond := ltu;
            when F3_BGEU => cond := not ltu;
            when others  => cond := '0';
        end case;
        take <= branch and cond;
    end process;

end architecture rtl;
