-------------------------------------------------------------------------------
-- imem.vhd  —  Memória de instruções (ROM) do RV32I (Frente B, etapa 3).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
--   * 256 palavras de 32 bits;
--   * endereçada por byte: a palavra é addr(9:2) (PC avança de 4 em 4);
--   * leitura COMBINACIONAL (modelo single-cycle: busca a instrução no mesmo ciclo);
--   * inicializada por um generic de array (INIT), preenchido por um pacote VHDL
--     gerado pelo montador (asm.py --vhdl). Isso funciona igual em Quartus
--     (síntese) e Questa (simulação) — diferente de ler .hex por textio, que o
--     Quartus 22.1 ignora na elaboração.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

entity imem is
    generic (
        WORDS : natural    := 256;
        INIT  : word_array := (0 => (others => '0'))   -- conteúdo da ROM
    );
    port (
        addr  : in  std_logic_vector(31 downto 0);  -- endereço de byte (PC)
        instr : out std_logic_vector(31 downto 0)
    );
end entity imem;

architecture rtl of imem is
    type rom_t is array (0 to WORDS-1) of std_logic_vector(31 downto 0);

    -- Copia INIT para uma ROM de tamanho fixo WORDS (resto = zero).
    function build_rom(src : word_array) return rom_t is
        variable r : rom_t := (others => (others => '0'));
    begin
        for i in src'range loop
            if i <= WORDS-1 then
                r(i) := src(i);
            end if;
        end loop;
        return r;
    end function;

    constant ROM : rom_t := build_rom(INIT);

    -- Índice de palavra (descarta os 2 bits baixos do endereço de byte).
    signal widx : integer range 0 to WORDS-1;
begin
    widx  <= to_integer(unsigned(addr(31 downto 2))) mod WORDS;
    instr <= ROM(widx);
end architecture rtl;
