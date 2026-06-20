-------------------------------------------------------------------------------
-- display_unit.vhd  —  Exibe um inteiro de 32 bits COM SINAL em 6 displays.
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Decisão A4: decimal com sinal + indicador de overflow.
--   * value tratado como complemento de 2;
--   * magnitude convertida a BCD (6 dígitos, double dabble);
--   * zeros à esquerda apagados;
--   * se negativo, '-' aparece à esquerda do dígito mais significativo;
--     se todos os 6 dígitos forem usados (sem espaço para o '-'), o sinal
--     fica só no LED de sinal;
--   * overflow ('1' quando |value| >= 1.000.000) acende um LED — os displays
--     então mostram os 6 dígitos decimais menos significativos.
--
-- Saídas hex0..hex5 são ativo-baixo (hex0 = dígito menos significativo).
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_unit is
    port (
        value    : in  std_logic_vector(31 downto 0);
        hex0     : out std_logic_vector(6 downto 0);
        hex1     : out std_logic_vector(6 downto 0);
        hex2     : out std_logic_vector(6 downto 0);
        hex3     : out std_logic_vector(6 downto 0);
        hex4     : out std_logic_vector(6 downto 0);
        hex5     : out std_logic_vector(6 downto 0);
        sign_led : out std_logic;
        ovf_led  : out std_logic
    );
end entity display_unit;

architecture rtl of display_unit is
    constant MINUS : std_logic_vector(3 downto 0) := "1010";  -- 10 -> '-'
    constant BLANK : std_logic_vector(3 downto 0) := "1111";  -- 15 -> apagado

    signal sign    : std_logic;
    signal mag     : std_logic_vector(31 downto 0);
    signal bcd     : std_logic_vector(23 downto 0);

    type code_arr is array (0 to 5) of std_logic_vector(3 downto 0);
    signal code : code_arr;

    type seg_arr is array (0 to 5) of std_logic_vector(6 downto 0);
    signal seg : seg_arr;
begin
    sign <= value(31);

    -- magnitude (valor absoluto)
    mag <= std_logic_vector(0 - signed(value)) when sign = '1' else value;

    -- conversão para BCD (6 dígitos)
    u_bcd : entity work.bin2bcd
        generic map (IN_W => 32, DIGITS => 6)
        port map (bin => mag, bcd => bcd);

    -- overflow: magnitude não cabe em 6 dígitos decimais
    ovf_led  <= '1' when unsigned(mag) >= to_unsigned(1000000, 32) else '0';
    sign_led <= sign;

    -- monta os códigos dos 6 dígitos (blanking + sinal)
    process(bcd, sign)
        variable d   : code_arr;
        variable msd : integer range 0 to 5;
    begin
        for i in 0 to 5 loop
            d(i) := bcd(i*4+3 downto i*4);
        end loop;

        -- dígito mais significativo não-zero
        msd := 0;
        for i in 1 to 5 loop
            if d(i) /= "0000" then
                msd := i;
            end if;
        end loop;

        -- dígitos: mostra 0..msd, apaga acima
        for i in 0 to 5 loop
            if i <= msd then
                code(i) <= d(i);
            else
                code(i) <= BLANK;
            end if;
        end loop;

        -- sinal de menos à esquerda do MSD, se houver espaço
        if sign = '1' and msd < 5 then
            code(msd+1) <= MINUS;
        end if;
    end process;

    -- 6 decodificadores de 7 segmentos
    g_seg : for i in 0 to 5 generate
        u : entity work.seg7 port map (code => code(i), seg => seg(i));
    end generate;

    hex0 <= seg(0);
    hex1 <= seg(1);
    hex2 <= seg(2);
    hex3 <= seg(3);
    hex4 <= seg(4);
    hex5 <= seg(5);

end architecture rtl;
