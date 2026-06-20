-------------------------------------------------------------------------------
-- regfile.vhd  —  Banco de registradores 32x32 do RV32I (Frente B, etapa 2).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
-- Características (espec. RV32I):
--   * 32 registradores de 32 bits (x0..x31);
--   * x0 é SEMPRE zero: leitura de x0 -> 0; escrita em x0 -> ignorada;
--   * 2 portas de leitura combinacionais (rs1, rs2) — modelo single-cycle;
--   * 1 porta de escrita síncrona (rising_edge), habilitada por we.
--
-- Política de leitura/escrita: escrita no fim do ciclo (borda), leitura
-- combinacional do valor ARMAZENADO → no mesmo ciclo lê-se o valor antigo
-- (correto para single-cycle: o valor escrito agora é usado no próximo ciclo).
--
-- Sem reset explícito: x0 é zero por construção; os demais são definidos pelo
-- programa antes do uso (ver decisão A7 do projeto).
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile is
    generic (
        XLEN : natural := 32                       -- largura dos registradores
    );
    port (
        clk : in  std_logic;
        we  : in  std_logic;                       -- write enable
        rs1 : in  std_logic_vector(4 downto 0);    -- endereço leitura 1
        rs2 : in  std_logic_vector(4 downto 0);    -- endereço leitura 2
        rd  : in  std_logic_vector(4 downto 0);    -- endereço escrita
        wd  : in  std_logic_vector(XLEN-1 downto 0); -- dado a escrever
        rd1 : out std_logic_vector(XLEN-1 downto 0); -- saída leitura 1
        rd2 : out std_logic_vector(XLEN-1 downto 0)  -- saída leitura 2
    );
end entity regfile;

architecture rtl of regfile is
    type reg_array is array (0 to 31) of std_logic_vector(XLEN-1 downto 0);
    signal regs : reg_array := (others => (others => '0'));
begin

    -- Escrita síncrona; x0 (endereço 0) nunca é escrito.
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' and rd /= "00000" then
                regs(to_integer(unsigned(rd))) <= wd;
            end if;
        end if;
    end process;

    -- Leitura combinacional; x0 lê sempre zero.
    rd1 <= (others => '0') when rs1 = "00000"
           else regs(to_integer(unsigned(rs1)));
    rd2 <= (others => '0') when rs2 = "00000"
           else regs(to_integer(unsigned(rs2)));

end architecture rtl;
