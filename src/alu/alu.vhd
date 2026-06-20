-------------------------------------------------------------------------------
-- alu.vhd  —  ULA do RISC-V RV32I, parametrizada em largura (Frente A + B etapa 1)
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite (MAX 10).
-- Autor:   João Moreti  —  Arq. e Org. de Computadores, PUCPR 2026/1.
--
-- Combinacional pura (sem registradores → 0 flip-flops; latch aqui = bug).
--
-- Contrato de alu_op (4 bits) — NÃO arbitrário; é o contrato com a futura
-- unidade de controle (Frente B, etapa 4):
--     alu_op(2 downto 0) = campo funct3 da instrução RISC-V
--     alu_op(3)          = instr[30] = funct7(5)  (distingue ADD/SUB e SRL/SRA)
--
--   ADD  = "0000"   SUB  = "1000"
--   SLL  = "0001"
--   SLT  = "0010"   (comparação com sinal)
--   SLTU = "0011"   (comparação sem sinal)
--   XOR  = "0100"
--   SRL  = "0101"   SRA  = "1101"
--   OR   = "0110"
--   AND  = "0111"
--
-- O parâmetro WIDTH permite sintetizar em 4/8/16/32/64 bits (experimento de
-- escalabilidade da Frente A). Para WIDTH /= 32 isso deixa de ser RV32I — é só
-- o instrumento de medida esticado para observar como a área cresce com a largura
-- (sobretudo o barrel shifter).  RV32I real usa WIDTH = 32.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    generic (
        WIDTH : natural := 32                       -- largura dos operandos
    );
    port (
        a      : in  std_logic_vector(WIDTH-1 downto 0);
        b      : in  std_logic_vector(WIDTH-1 downto 0);
        alu_op : in  std_logic_vector(3 downto 0);  -- {instr30, funct3}
        result : out std_logic_vector(WIDTH-1 downto 0);
        zero   : out std_logic                      -- '1' quando result = 0
    );
end entity alu;

architecture rtl of alu is

    ---------------------------------------------------------------------------
    -- Codificação das operações (ver cabeçalho).
    ---------------------------------------------------------------------------
    constant OP_ADD  : std_logic_vector(3 downto 0) := "0000";
    constant OP_SUB  : std_logic_vector(3 downto 0) := "1000";
    constant OP_SLL  : std_logic_vector(3 downto 0) := "0001";
    constant OP_SLT  : std_logic_vector(3 downto 0) := "0010";
    constant OP_SLTU : std_logic_vector(3 downto 0) := "0011";
    constant OP_XOR  : std_logic_vector(3 downto 0) := "0100";
    constant OP_SRL  : std_logic_vector(3 downto 0) := "0101";
    constant OP_OR   : std_logic_vector(3 downto 0) := "0110";
    constant OP_AND  : std_logic_vector(3 downto 0) := "0111";
    constant OP_SRA  : std_logic_vector(3 downto 0) := "1101";

    ---------------------------------------------------------------------------
    -- ceil(log2(WIDTH)) — nº de bits do shift amount (shamt).
    -- RV32I: shamt = 5 bits (b[4:0]).  Generaliza para qualquer WIDTH.
    ---------------------------------------------------------------------------
    function clog2(n : natural) return natural is
        variable r : natural := 0;
        variable v : natural := 1;
    begin
        while v < n loop
            v := v * 2;
            r := r + 1;
        end loop;
        return r;
    end function;

    constant SH_BITS : natural := clog2(WIDTH);

    -- Operandos com interpretação numérica.
    signal ua, ub   : unsigned(WIDTH-1 downto 0);
    signal sa       : signed(WIDTH-1 downto 0);
    signal shamt    : natural range 0 to WIDTH-1;

    signal res      : std_logic_vector(WIDTH-1 downto 0);

begin

    ua <= unsigned(a);
    ub <= unsigned(b);
    sa <= signed(a);

    -- Shift amount = SH_BITS bits baixos de b (RV32I usa b[4:0]).
    shamt <= to_integer(ub(SH_BITS-1 downto 0));

    ---------------------------------------------------------------------------
    -- Seleção da operação.
    ---------------------------------------------------------------------------
    process(a, b, ua, ub, sa, shamt, alu_op) is
        variable lt_s  : std_logic;  -- a <  b (com sinal)
        variable lt_u  : std_logic;  -- a <  b (sem sinal)
    begin
        -- Comparações (usadas por SLT/SLTU).
        if signed(a) < signed(b) then lt_s := '1'; else lt_s := '0'; end if;
        if ua        < ub        then lt_u := '1'; else lt_u := '0'; end if;

        case alu_op is
            when OP_ADD  => res <= std_logic_vector(ua + ub);
            when OP_SUB  => res <= std_logic_vector(ua - ub);
            when OP_AND  => res <= a and b;
            when OP_OR   => res <= a or  b;
            when OP_XOR  => res <= a xor b;
            when OP_SLL  => res <= std_logic_vector(shift_left (ua, shamt));
            when OP_SRL  => res <= std_logic_vector(shift_right(ua, shamt));
            when OP_SRA  => res <= std_logic_vector(shift_right(sa, shamt));
            when OP_SLT  => res <= (0 => lt_s, others => '0');
            when OP_SLTU => res <= (0 => lt_u, others => '0');
            when others  => res <= (others => '0');  -- código não usado
        end case;
    end process;

    result <= res;

    -- Flag zero: '1' quando o resultado é todo zero (usada p.ex. em BEQ via SUB).
    zero <= '1' when res = (res'range => '0') else '0';

end architecture rtl;
