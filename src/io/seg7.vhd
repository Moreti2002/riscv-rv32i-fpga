-------------------------------------------------------------------------------
-- seg7.vhd  —  Decodificador BCD -> 7 segmentos (ativo-baixo, DE10-Lite).
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Os displays HEX da DE10-Lite são ATIVOS EM BAIXO (segmento aceso = '0') e têm
-- pinos dedicados por display (não há multiplexação). Mapeamento de segmentos:
--   seg(0)=a  seg(1)=b  seg(2)=c  seg(3)=d  seg(4)=e  seg(5)=f  seg(6)=g
--
-- Código de entrada:
--   0..9  -> dígito decimal
--   10    -> sinal de menos ('-')
--   outro -> apagado (blank)
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity seg7 is
    port (
        code : in  std_logic_vector(3 downto 0);
        seg  : out std_logic_vector(6 downto 0)   -- ativo-baixo, seg(0)=a
    );
end entity seg7;

architecture rtl of seg7 is
    -- Padrões ATIVOS EM ALTO (1=aceso), ordem gfedcba (bit6=g ... bit0=a).
    -- Convertidos para ativo-baixo na saída.
    function pat(c : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case c is
            when "0000" => return "0111111"; -- 0: a b c d e f
            when "0001" => return "0000110"; -- 1: b c
            when "0010" => return "1011011"; -- 2: a b d e g
            when "0011" => return "1001111"; -- 3: a b c d g
            when "0100" => return "1100110"; -- 4: b c f g
            when "0101" => return "1101101"; -- 5: a c d f g
            when "0110" => return "1111101"; -- 6: a c d e f g
            when "0111" => return "0000111"; -- 7: a b c
            when "1000" => return "1111111"; -- 8: todos
            when "1001" => return "1101111"; -- 9: a b c d f g
            when "1010" => return "1000000"; -- '-' : só g
            when others => return "0000000"; -- apagado
        end case;
    end function;
    signal p : std_logic_vector(6 downto 0);
begin
    p   <= pat(code);
    seg <= not p;   -- ativo-baixo
end architecture rtl;
