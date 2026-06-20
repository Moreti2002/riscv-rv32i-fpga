-------------------------------------------------------------------------------
-- imem.vhd  —  Memória de instruções (ROM) do RV32I (Frente B, etapa 3).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
--   * 256 palavras de 32 bits (cabe num bloco M9K);
--   * endereçada por byte: a palavra é addr(9:2) (PC avança de 4 em 4);
--   * leitura COMBINACIONAL (modelo single-cycle: busca a instrução no mesmo ciclo);
--   * inicializada a partir de um arquivo .hex (uma palavra de 8 dígitos hex por
--     linha, palavra 0 na 1ª linha). Se o arquivo não abrir, ROM = zeros.
--
-- O .hex é gerado pelo montador (asm/ -> mem/) — ver scripts/asm.py.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity imem is
    generic (
        WORDS     : natural := 256;
        INIT_FILE : string  := "program.hex"
    );
    port (
        addr  : in  std_logic_vector(31 downto 0);  -- endereço de byte (PC)
        instr : out std_logic_vector(31 downto 0)
    );
end entity imem;

architecture rtl of imem is
    type rom_t is array (0 to WORDS-1) of std_logic_vector(31 downto 0);

    impure function init_rom(fname : string) return rom_t is
        file     f      : text;
        variable l      : line;
        variable w      : std_logic_vector(31 downto 0);
        variable rom    : rom_t := (others => (others => '0'));
        variable status : file_open_status;
        variable i      : integer := 0;
    begin
        file_open(status, f, fname, read_mode);
        if status /= open_ok then
            return rom;                       -- arquivo ausente: tudo zero
        end if;
        while (not endfile(f)) and (i < WORDS) loop
            readline(f, l);
            if l.all'length > 0 then          -- ignora linhas em branco
                hread(l, w);
                rom(i) := w;
                i := i + 1;
            end if;
        end loop;
        file_close(f);
        return rom;
    end function;

    constant ROM : rom_t := init_rom(INIT_FILE);

    -- Índice de palavra (descarta os 2 bits baixos do endereço de byte).
    signal widx : integer range 0 to WORDS-1;
begin
    widx  <= to_integer(unsigned(addr(31 downto 2))) mod WORDS;
    instr <= ROM(widx);
end architecture rtl;
