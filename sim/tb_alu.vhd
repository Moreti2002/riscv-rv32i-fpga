-------------------------------------------------------------------------------
-- tb_alu.vhd  —  Testbench auto-verificável da ULA RV32I (WIDTH = 32).
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Estratégia: casos-armadilha que pegam os bugs clássicos de uma ULA —
--   * SLT vs SLTU trocados (sinal vs não-sinal);
--   * SRA vs SRL (aritmético vs lógico) na presença de bit de sinal;
--   * shift amount usando só os 5 bits baixos (shift por 32 == shift por 0);
--   * SUB com resultado negativo (wrap em complemento de 2);
--   * flag zero em A==B.
--
-- Valores esperados são GOLD hardcoded (independentes do DUT) para os casos
-- críticos, garantindo que a checagem não replica um eventual bug do projeto.
--
-- Execução (Questa, CLI):
--   vlib work
--   vcom -2008 ../src/alu/alu.vhd tb_alu.vhd
--   vsim -c -do "run -all" tb_alu
-- Sucesso = "ALL TESTS PASSED". Qualquer falha imprime FAIL com detalhes.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_alu is
end entity tb_alu;

architecture sim of tb_alu is

    constant W : natural := 32;

    -- Códigos de operação (espelham o contrato alu_op).
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

    signal a, b    : std_logic_vector(W-1 downto 0) := (others => '0');
    signal alu_op  : std_logic_vector(3 downto 0)   := (others => '0');
    signal result  : std_logic_vector(W-1 downto 0);
    signal zero    : std_logic;

    signal errors  : natural := 0;

    -- Atalho para escrever constantes hex de 32 bits.
    function x32(constant v : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(v, W));
    end function;

begin

    ---------------------------------------------------------------------------
    -- DUT
    ---------------------------------------------------------------------------
    dut : entity work.alu
        generic map (WIDTH => W)
        port map (a => a, b => b, alu_op => alu_op, result => result, zero => zero);

    ---------------------------------------------------------------------------
    -- Estímulo + checagem
    ---------------------------------------------------------------------------
    stim : process
        -- Aplica um caso e compara result/zero com o esperado.
        procedure check(constant name   : in string;
                        constant op      : in std_logic_vector(3 downto 0);
                        constant va, vb  : in std_logic_vector(W-1 downto 0);
                        constant exp_res : in std_logic_vector(W-1 downto 0);
                        constant exp_zero: in std_logic) is
        begin
            a <= va; b <= vb; alu_op <= op;
            wait for 10 ns;
            if result /= exp_res then
                report "FAIL [" & name & "] result=" & to_hstring(result) &
                       " esperado=" & to_hstring(exp_res)
                    severity error;
                errors <= errors + 1;
            elsif zero /= exp_zero then
                report "FAIL [" & name & "] zero=" & std_logic'image(zero) &
                       " esperado=" & std_logic'image(exp_zero)
                    severity error;
                errors <= errors + 1;
            else
                report "ok  [" & name & "] = " & to_hstring(result) severity note;
            end if;
            wait for 1 ns;
        end procedure;
    begin
        -------------------------------------------------------------------
        -- Aritmética
        -------------------------------------------------------------------
        check("ADD basico",  OP_ADD,  x32(7),  x32(5),  x32(12), '0');
        check("ADD wrap",    OP_ADD,  x"FFFFFFFF", x32(1), x"00000000", '1'); -- -1 + 1 = 0
        check("SUB basico",  OP_SUB,  x32(9),  x32(4),  x32(5),  '0');
        check("SUB negativo",OP_SUB,  x32(4),  x32(9),  x32(-5), '0');       -- 4-9 = -5
        check("SUB zero",    OP_SUB,  x32(42), x32(42), x32(0),  '1');       -- A==B -> zero

        -------------------------------------------------------------------
        -- Lógicas
        -------------------------------------------------------------------
        check("AND", OP_AND, x"FF00FF00", x"0F0F0F0F", x"0F000F00", '0');
        check("OR",  OP_OR,  x"FF00FF00", x"0F0F0F0F", x"FF0FFF0F", '0');
        check("XOR", OP_XOR, x"FF00FF00", x"0F0F0F0F", x"F00FF00F", '0');
        check("XOR=0",OP_XOR,x"12345678", x"12345678", x"00000000", '1');

        -------------------------------------------------------------------
        -- Shifts — armadilha SRA vs SRL e shamt só 5 bits
        -------------------------------------------------------------------
        check("SLL 4",       OP_SLL, x"00000001", x32(4),  x"00000010", '0');
        check("SRL 4",       OP_SRL, x"80000000", x32(4),  x"08000000", '0'); -- lógico: entra 0
        check("SRA 4",       OP_SRA, x"80000000", x32(4),  x"F8000000", '0'); -- aritmético: estende sinal
        check("SRA pos",     OP_SRA, x"40000000", x32(4),  x"04000000", '0'); -- sinal 0 -> igual SRL
        -- shamt usa só b[4:0]: deslocar por 32 (0x20) == deslocar por 0
        check("SLL shamt32", OP_SLL, x"00000001", x32(32), x"00000001", '0');
        check("SRL shamt33", OP_SRL, x"80000000", x32(33), x"40000000", '0'); -- 33 mod 32 = 1

        -------------------------------------------------------------------
        -- SLT vs SLTU — a armadilha clássica
        -------------------------------------------------------------------
        -- a = -1 (0xFFFFFFFF), b = 1
        check("SLT  -1<1",   OP_SLT,  x"FFFFFFFF", x32(1), x32(1), '0'); -- com sinal: -1<1 -> 1
        check("SLTU -1<1",   OP_SLTU, x"FFFFFFFF", x32(1), x32(0), '1'); -- sem sinal: enorme<1 -> 0
        check("SLT  5<5",    OP_SLT,  x32(5), x32(5), x32(0), '1');
        check("SLT  2<7",    OP_SLT,  x32(2), x32(7), x32(1), '0');
        check("SLTU 7<2",    OP_SLTU, x32(7), x32(2), x32(0), '1');

        -------------------------------------------------------------------
        -- Encerramento
        -------------------------------------------------------------------
        wait for 5 ns;
        if errors = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "TESTS FAILED: " & integer'image(errors) & " erro(s)" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
