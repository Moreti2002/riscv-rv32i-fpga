-------------------------------------------------------------------------------
-- tb_calc.vhd  —  Testbench da calculadora (top-level riscv_de10lite).
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Carrega mem/calc.hex, dirige as chaves (SW) e confere o valor exibido lendo o
-- registrador interno disp_reg via EXTERNAL NAME (VHDL-2008). Cobre +, - (sinal
-- negativo) e AND.
--
-- SW[3:0]=A, SW[7:4]=B, SW[9:8]=op (00=+ 01=- 10=& 11=|).
--
-- Execução (Questa, CLI) — compilar toda a hierarquia + I/O, depois:
--   vsim -c -do "run -all" tb_calc
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_calc is
end entity tb_calc;

architecture sim of tb_calc is
    signal clk  : std_logic := '0';
    signal SW   : std_logic_vector(9 downto 0) := (others => '0');
    signal KEY  : std_logic_vector(1 downto 0) := "11";   -- não pressionado
    signal LEDR : std_logic_vector(9 downto 0);
    signal HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : std_logic_vector(7 downto 0);

    signal errors : natural := 0;
    constant TCLK : time := 10 ns;

    function sw_of(a, b, op : integer) return std_logic_vector is
        variable r : std_logic_vector(9 downto 0);
    begin
        r(3 downto 0) := std_logic_vector(to_unsigned(a, 4));
        r(7 downto 4) := std_logic_vector(to_unsigned(b, 4));
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

        procedure chk(name : string; a, b, op, expected : integer) is
            -- espia o registrador interno do top via external name (em runtime)
            variable dv : std_logic_vector(31 downto 0);
        begin
            SW <= sw_of(a, b, op);
            run_cycles(400);              -- deixa o laço recalcular
            wait for 1 ns;
            dv := << signal dut.disp_reg : std_logic_vector(31 downto 0) >>;
            if signed(dv) /= to_signed(expected, 32) then
                report "FAIL [" & name & "] disp=" & integer'image(to_integer(signed(dv))) &
                       " esperado=" & integer'image(expected) severity error;
                errors <= errors + 1;
            else
                report "ok  [" & name & "] disp=" & integer'image(expected) severity note;
            end if;
        end procedure;
    begin
        -- pulso de reset
        KEY <= "10";                      -- KEY0 pressionado (reset)
        run_cycles(4);
        KEY <= "11";
        run_cycles(200);

        chk("7 + 3",   7, 3, 0, 10);
        chk("3 - 7",   3, 7, 1, -4);      -- negativo: exercita sinal
        chk("12 & 10", 12, 10, 2, 8);
        chk("12 | 3",  12, 3, 3, 15);

        wait for 5 ns;
        if errors = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "TESTS FAILED: " & integer'image(errors) & " erro(s)" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
