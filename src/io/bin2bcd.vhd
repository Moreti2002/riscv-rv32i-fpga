-------------------------------------------------------------------------------
-- bin2bcd.vhd  —  Conversão binário -> BCD (algoritmo double dabble).
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Converte um inteiro sem sinal de IN_W bits em DIGITS dígitos BCD (4 bits cada).
-- Combinacional (shift-and-add-3 desenrolado). Se o valor exceder DIGITS dígitos
-- decimais, os dígitos de ordem mais alta "saem" pelo topo e o resultado fica
-- sendo (valor mod 10^DIGITS) — i.e., os DIGITS dígitos decimais menos
-- significativos, que é exatamente o que queremos exibir (o overflow é detectado
-- à parte no display_unit).
--
-- double dabble: para cada bit (do MSB ao LSB), corrige cada nibble >= 5
-- somando 3 e desloca tudo 1 à esquerda, trazendo o próximo bit do binário.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin2bcd is
    generic (
        IN_W   : natural := 32;   -- largura do binário de entrada
        DIGITS : natural := 6     -- nº de dígitos BCD de saída
    );
    port (
        bin : in  std_logic_vector(IN_W-1 downto 0);
        bcd : out std_logic_vector(DIGITS*4-1 downto 0)
    );
end entity bin2bcd;

architecture rtl of bin2bcd is
begin
    process(bin)
        constant BCD_W : natural := DIGITS*4;
        variable s : unsigned(BCD_W + IN_W - 1 downto 0);
        variable nib : unsigned(3 downto 0);
    begin
        s := (others => '0');
        s(IN_W-1 downto 0) := unsigned(bin);

        for i in 0 to IN_W-1 loop
            -- corrige cada nibble da região BCD (acima dos IN_W bits)
            for d in 0 to DIGITS-1 loop
                nib := s(IN_W + d*4 + 3 downto IN_W + d*4);
                if nib >= 5 then
                    s(IN_W + d*4 + 3 downto IN_W + d*4) := nib + 3;
                end if;
            end loop;
            -- desloca 1 à esquerda
            s := s(s'high-1 downto 0) & '0';
        end loop;

        bcd <= std_logic_vector(s(BCD_W + IN_W - 1 downto IN_W));
    end process;
end architecture rtl;
