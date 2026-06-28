-------------------------------------------------------------------------------
-- riscv_de2.vhd — Top-level para a placa DE2 (Cyclone II EP2C35F672C6).
--
-- Projeto: Processador RISC-V RV32I single-cycle. Autor: João Moreti.
--
-- Reaproveita TODO o processador já validado (entity riscv_de10lite) sem
-- modificá-lo: este wrapper só adapta o nome do clock (CLOCK_50) e os displays
-- de 7 segmentos da DE2, que têm 7 bits (a DE10-Lite usa 8, com o ponto decimal
-- no bit 7). Ligamos só os 7 segmentos (bits 6..0) e descartamos o ponto.
--
-- Assim o MESMO sistema roda na DE10-Lite e na DE2, sem quebrar nenhum dos dois.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity riscv_de2 is
    port (
        CLOCK_50 : in  std_logic;                       -- 50 MHz (pino N2)
        KEY      : in  std_logic_vector(1 downto 0);    -- botões (ativo-baixo)
        SW       : in  std_logic_vector(9 downto 0);    -- chaves
        LEDR     : out std_logic_vector(9 downto 0);    -- LEDs vermelhos
        HEX0     : out std_logic_vector(6 downto 0);    -- displays (7 segmentos)
        HEX1     : out std_logic_vector(6 downto 0);
        HEX2     : out std_logic_vector(6 downto 0);
        HEX3     : out std_logic_vector(6 downto 0);
        HEX4     : out std_logic_vector(6 downto 0);
        HEX5     : out std_logic_vector(6 downto 0)
    );
end entity riscv_de2;

architecture rtl of riscv_de2 is
    -- saídas de 8 bits do top original (bit 7 = ponto decimal, descartado)
    signal h0, h1, h2, h3, h4, h5 : std_logic_vector(7 downto 0);
begin
    u_sys : entity work.riscv_de10lite
        port map (
            MAX10_CLK1_50 => CLOCK_50,
            KEY  => KEY,
            SW   => SW,
            LEDR => LEDR,
            HEX0 => h0, HEX1 => h1, HEX2 => h2,
            HEX3 => h3, HEX4 => h4, HEX5 => h5
        );

    HEX0 <= h0(6 downto 0);
    HEX1 <= h1(6 downto 0);
    HEX2 <= h2(6 downto 0);
    HEX3 <= h3(6 downto 0);
    HEX4 <= h4(6 downto 0);
    HEX5 <= h5(6 downto 0);
end architecture rtl;
