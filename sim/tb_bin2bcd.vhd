-------------------------------------------------------------------------------
-- tb_bin2bcd.vhd  —  Testbench do conversor binário->BCD (double dabble).
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Confere a conversão de vários valores, inclusive o caso de truncamento
-- (valor >= 10^6 entrega os 6 dígitos decimais baixos).
--
--   vsim -c -do "run -all" tb_bin2bcd
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_bin2bcd is
end entity tb_bin2bcd;

architecture sim of tb_bin2bcd is
    signal bin : std_logic_vector(31 downto 0) := (others => '0');
    signal bcd : std_logic_vector(23 downto 0);
    signal errors : natural := 0;
begin
    dut : entity work.bin2bcd
        generic map (IN_W => 32, DIGITS => 6)
        port map (bin => bin, bcd => bcd);

    stim : process
        procedure chk(v : integer; exp : std_logic_vector(23 downto 0)) is
        begin
            bin <= std_logic_vector(to_unsigned(v, 32));
            wait for 10 ns;
            if bcd /= exp then
                report "FAIL bin=" & integer'image(v) & " bcd=" & to_hstring(bcd) &
                       " esperado=" & to_hstring(exp) severity error;
                errors <= errors + 1;
            else
                report "ok  " & integer'image(v) & " -> " & to_hstring(bcd) severity note;
            end if;
        end procedure;
    begin
        chk(0,       x"000000");
        chk(5,       x"000005");
        chk(9,       x"000009");
        chk(42,      x"000042");
        chk(100,     x"000100");
        chk(123456,  x"123456");
        chk(999999,  x"999999");
        chk(1000000, x"000000");   -- trunca: 6 dígitos baixos
        chk(1000005, x"000005");   -- idem

        wait for 5 ns;
        if errors = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "TESTS FAILED: " & integer'image(errors) & " erro(s)" severity failure;
        end if;
        wait;
    end process;
end architecture sim;
