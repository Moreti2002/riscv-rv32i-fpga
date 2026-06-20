-------------------------------------------------------------------------------
-- alu_fmax_wrapper.vhd  —  Wrapper de medição de Fmax da ULA (Frente A).
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Por quê: a ULA é puramente combinacional → não tem Fmax (Fmax é definido
-- ENTRE registradores). Para o Timing Analyzer medir o atraso do miolo
-- combinacional, envolvemos a ULA com:
--     registradores na ENTRADA  (a, b, alu_op)
--     registradores na SAÍDA     (result, zero)
-- O caminho crítico medido passa a ser reg -> ULA -> reg, exatamente o que
-- queremos caracterizar em 4/8/16/32/64 bits.
--
-- Este wrapper é INSTRUMENTO DE MEDIDA — não faz parte do processador.
-- Usar com o alu_fmax.sdc (define o create_clock).
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity alu_fmax_wrapper is
    generic (
        WIDTH : natural := 32
    );
    port (
        clk     : in  std_logic;
        a_in    : in  std_logic_vector(WIDTH-1 downto 0);
        b_in    : in  std_logic_vector(WIDTH-1 downto 0);
        op_in   : in  std_logic_vector(3 downto 0);
        res_out : out std_logic_vector(WIDTH-1 downto 0);
        zero_out: out std_logic
    );
end entity alu_fmax_wrapper;

architecture rtl of alu_fmax_wrapper is
    -- Registradores de entrada.
    signal a_r, b_r   : std_logic_vector(WIDTH-1 downto 0);
    signal op_r       : std_logic_vector(3 downto 0);
    -- Saída combinacional da ULA.
    signal res_c      : std_logic_vector(WIDTH-1 downto 0);
    signal zero_c     : std_logic;
begin

    u_alu : entity work.alu
        generic map (WIDTH => WIDTH)
        port map (
            a => a_r, b => b_r, alu_op => op_r,
            result => res_c, zero => zero_c
        );

    process(clk)
    begin
        if rising_edge(clk) then
            -- registra entradas
            a_r  <= a_in;
            b_r  <= b_in;
            op_r <= op_in;
            -- registra saídas
            res_out  <= res_c;
            zero_out <= zero_c;
        end if;
    end process;

end architecture rtl;
