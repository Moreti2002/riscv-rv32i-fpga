-------------------------------------------------------------------------------
-- dmem.vhd  —  Memória de dados (RAM) do RV32I (Frente B, etapa 5).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
--   * 256 palavras de 32 bits;
--   * endereçada por byte: palavra = addr(9:2);
--   * escrita SÍNCRONA (rising_edge) quando we='1';
--   * leitura COMBINACIONAL (LW entrega o dado no mesmo ciclo — single-cycle).
--
-- Implementa LW/SW (palavra inteira). A interface já carrega funct3 (size) para
-- a extensão futura LB/LH/SB/SH ser um acréscimo local, sem mudar o datapath.
-- Por ora, acessos são tratados como palavra alinhada (ver limitação A9).
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dmem is
    generic (
        WORDS : natural := 256
    );
    port (
        clk   : in  std_logic;
        we    : in  std_logic;                      -- write enable (SW)
        addr  : in  std_logic_vector(31 downto 0);  -- endereço de byte
        wdata : in  std_logic_vector(31 downto 0);  -- dado a escrever
        rdata : out std_logic_vector(31 downto 0)   -- dado lido (LW)
    );
end entity dmem;

architecture rtl of dmem is
    type ram_t is array (0 to WORDS-1) of std_logic_vector(31 downto 0);
    signal ram  : ram_t := (others => (others => '0'));
    signal widx : integer range 0 to WORDS-1;
begin
    widx <= to_integer(unsigned(addr(31 downto 2))) mod WORDS;

    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(widx) <= wdata;
            end if;
        end if;
    end process;

    rdata <= ram(widx);   -- leitura combinacional
end architecture rtl;
