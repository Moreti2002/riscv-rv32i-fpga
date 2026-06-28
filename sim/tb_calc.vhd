-------------------------------------------------------------------------------
-- tb_calc.vhd  —  Testbench da calculadora ACUMULADOR (top-level riscv_de10lite).
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Exercita a calculadora de acumulador: dirige o valor nas chaves (SW[7:0]) e a
-- operação (SW[9:8]), pulsa o botão KEY1 ("Enter/=") e confere o ACUMULADOR lido
-- do registrador interno disp_reg via EXTERNAL NAME (VHDL-2008). Cada pressão
-- aplica  acc = acc <op> valor.  Cobre +, -, & e | de forma encadeada.
--
--   SW[7:0]=valor  SW[9:8]=op (00=+ 01=- 10=& 11=|)  KEY1=Enter  KEY0=reset
--
-- O programa faz DEBOUNCE por software (~3000 iterações de espera). Por isso a
-- pressão é mantida por muitos ciclos antes de soltar (run_cycles abaixo).
--
-- Execução (GHDL): ver sim/run_all_ghdl.sh (--stop-time=8ms para este tb).
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_calc is
end entity tb_calc;

architecture sim of tb_calc is
    signal clk  : std_logic := '0';
    signal SW   : std_logic_vector(9 downto 0) := (others => '0');
    signal KEY  : std_logic_vector(1 downto 0) := "11";   -- nenhum pressionado
    signal LEDR : std_logic_vector(9 downto 0);
    signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector(7 downto 0);

    signal errors : natural := 0;
    constant TCLK : time := 10 ns;

    -- monta o vetor de chaves: valor em SW[7:0], operação em SW[9:8]
    function sw_of(value, op : integer) return std_logic_vector is
        variable r : std_logic_vector(9 downto 0);
    begin
        r(7 downto 0) := std_logic_vector(to_unsigned(value, 8));
        r(9 downto 8) := std_logic_vector(to_unsigned(op, 2));
        return r;
    end function;
begin

    dut : entity work.riscv_de10lite
        generic map (CPU_DIV => 1)
        port map (MAX10_CLK1_50 => clk, KEY => KEY, SW => SW, LEDR => LEDR,
                  HEX0 => HEX0, HEX1 => HEX1, HEX2 => HEX2,
                  HEX3 => HEX3, HEX4 => HEX4, HEX5 => HEX5);

    clk <= not clk after TCLK/2;

    stim : process
        procedure run_cycles(n : integer) is
        begin
            for i in 0 to n-1 loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        -- Aplica um valor/op via KEY1 e confere o acumulador resultante.
        procedure step(name : string; value, op, expected : integer) is
            variable dv : std_logic_vector(31 downto 0);
        begin
            SW  <= sw_of(value, op);
            run_cycles(2000);             -- chaves assentam; programa no laço
            KEY <= "01";                  -- pressiona KEY1 (ativo-baixo)
            run_cycles(40000);            -- segura > debounce; programa confirma+aplica
            KEY <= "11";                  -- solta
            run_cycles(40000);            -- debounce da soltura + atualização do display
            wait for 1 ns;
            dv := << signal dut.disp_reg : std_logic_vector(31 downto 0) >>;
            if signed(dv) /= to_signed(expected, 32) then
                report "FAIL [" & name & "] acc=" & integer'image(to_integer(signed(dv))) &
                       " esperado=" & integer'image(expected) severity error;
                errors <= errors + 1;
            else
                report "ok  [" & name & "] acc=" & integer'image(expected) severity note;
            end if;
        end procedure;
    begin
        -- pulso de reset (KEY0 pressionado): acumulador volta a 0
        KEY <= "10";
        run_cycles(8);
        KEY <= "11";
        run_cycles(400);

        -- sequência encadeada exercitando os 4 operadores + acumulação
        step("acc += 10",  10, 0,  10);   -- 0 + 10  = 10
        step("acc += 20",  20, 0,  30);   -- 10 + 20 = 30
        step("acc -= 5",    5, 1,  25);   -- 30 - 5  = 25
        step("acc &= 24",  24, 2,  24);   -- 25 & 24 = 24 (11001 & 11000)
        step("acc |= 1",    1, 3,  25);   -- 24 | 1  = 25

        wait for 5 ns;
        if errors = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "TESTS FAILED: " & integer'image(errors) & " erro(s)" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
