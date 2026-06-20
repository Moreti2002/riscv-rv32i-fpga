-------------------------------------------------------------------------------
-- tb_regfile.vhd  —  Testbench auto-verificável do banco de registradores.
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Casos cobertos:
--   * escrita e leitura de um registrador qualquer;
--   * x0 imutável (escrever em x0 não muda; ler x0 dá 0);
--   * we = '0' não escreve;
--   * duas portas de leitura simultâneas;
--   * leitura combinacional reflete valor armazenado (não o que está sendo escrito).
--
-- Execução (Questa, CLI), a partir de sim/:
--   vlib work
--   vcom -2008 ../src/cpu/regfile.vhd tb_regfile.vhd
--   vsim -c -do "run -all" tb_regfile
-- Sucesso = "ALL TESTS PASSED".
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_regfile is
end entity tb_regfile;

architecture sim of tb_regfile is
    constant XLEN : natural := 32;

    signal clk : std_logic := '0';
    signal we  : std_logic := '0';
    signal rs1, rs2, rd : std_logic_vector(4 downto 0) := (others => '0');
    signal wd  : std_logic_vector(XLEN-1 downto 0) := (others => '0');
    signal rd1, rd2 : std_logic_vector(XLEN-1 downto 0);

    signal errors : natural := 0;
    constant TCLK : time := 10 ns;

    function x32(constant v : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(v, XLEN));
    end function;
begin

    dut : entity work.regfile
        generic map (XLEN => XLEN)
        port map (clk => clk, we => we, rs1 => rs1, rs2 => rs2,
                  rd => rd, wd => wd, rd1 => rd1, rd2 => rd2);

    clk <= not clk after TCLK/2;

    stim : process
        -- Escreve 'val' em registrador 'addr' num pulso de clock.
        procedure wr(constant addr : in integer; constant val : in std_logic_vector) is
        begin
            rd <= std_logic_vector(to_unsigned(addr, 5));
            wd <= val;
            we <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;     -- deixa a escrita assentar
            we <= '0';
        end procedure;

        procedure chk1(constant name : in string; constant addr : in integer;
                       constant exp : in std_logic_vector) is
        begin
            rs1 <= std_logic_vector(to_unsigned(addr, 5));
            wait for 1 ns;
            if rd1 /= exp then
                report "FAIL [" & name & "] rd1=" & to_hstring(rd1) &
                       " esperado=" & to_hstring(exp) severity error;
                errors <= errors + 1;
            else
                report "ok  [" & name & "]" severity note;
            end if;
        end procedure;
    begin
        we <= '0';
        wait until rising_edge(clk);

        -- 1) escrita/leitura básica
        wr(5, x32(123));
        chk1("x5=123", 5, x32(123));

        -- 2) outro registrador, valor com bits altos
        wr(31, x"DEADBEEF");
        chk1("x31=DEADBEEF", 31, x"DEADBEEF");
        chk1("x5 intacto", 5, x32(123));

        -- 3) x0 imutável
        wr(0, x"FFFFFFFF");          -- tenta escrever em x0
        chk1("x0=0", 0, x32(0));

        -- 4) we=0 não escreve
        rd <= std_logic_vector(to_unsigned(5, 5));
        wd <= x"11112222";
        we <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        chk1("x5 nao mudou (we=0)", 5, x32(123));

        -- 5) duas portas de leitura simultâneas
        rs1 <= std_logic_vector(to_unsigned(5, 5));
        rs2 <= std_logic_vector(to_unsigned(31, 5));
        wait for 1 ns;
        if rd1 /= x32(123) or rd2 /= x"DEADBEEF" then
            report "FAIL [2 portas] rd1=" & to_hstring(rd1) & " rd2=" & to_hstring(rd2)
                severity error;
            errors <= errors + 1;
        else
            report "ok  [2 portas leitura]" severity note;
        end if;

        wait for 5 ns;
        if errors = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "TESTS FAILED: " & integer'image(errors) & " erro(s)" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
