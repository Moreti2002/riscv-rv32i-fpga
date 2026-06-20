-------------------------------------------------------------------------------
-- tb_core.vhd  —  Testbench de integração do núcleo RV32I single-cycle.
--
-- Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
--
-- Carrega mem/test_core.hex na ROM, roda o processador e confere o estado final
-- dos registradores pela porta de depuração. O programa test_core.s exercita
-- tipo-R, tipo-I, shifts, SLT, branches, LW/SW, LUI, AUIPC e JAL/JALR.
--
-- Execução (Questa, CLI), a partir de sim/:
--   vlib work
--   vcom -2008 ../src/cpu/riscv_pkg.vhd ../src/alu/alu.vhd \
--              ../src/cpu/regfile.vhd ../src/cpu/imm_gen.vhd \
--              ../src/cpu/control.vhd ../src/cpu/branch_unit.vhd \
--              ../src/cpu/imem.vhd ../src/cpu/dmem.vhd \
--              ../src/cpu/riscv_core.vhd ../src/cpu/riscv_system.vhd tb_core.vhd
--   vsim -c -do "run -all" tb_core
-- Sucesso = "ALL TESTS PASSED".
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;
use work.test_core_rom_pkg.all;

entity tb_core is
end entity tb_core;

architecture sim of tb_core is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal pc  : std_logic_vector(31 downto 0);
    signal dbg_addr : std_logic_vector(4 downto 0) := (others => '0');
    signal dbg_data : std_logic_vector(31 downto 0);

    signal errors : natural := 0;
    constant TCLK : time := 10 ns;

    function x32(constant v : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(v, 32));
    end function;
begin

    dut : entity work.riscv_system
        generic map (WORDS => 256, INIT => PROGRAM)
        port map (clk => clk, rst => rst, pc_out => pc,
                  dbg_reg_addr => dbg_addr, dbg_reg_data => dbg_data);

    clk <= not clk after TCLK/2;

    stim : process
        procedure chk(constant name : in string; constant rnum : in integer;
                      constant exp : in std_logic_vector(31 downto 0)) is
        begin
            dbg_addr <= std_logic_vector(to_unsigned(rnum, 5));
            wait for 1 ns;
            if dbg_data /= exp then
                report "FAIL [" & name & "] x" & integer'image(rnum) &
                       "=" & to_hstring(dbg_data) & " esperado=" & to_hstring(exp)
                    severity error;
                errors <= errors + 1;
            else
                report "ok  [" & name & "] = " & to_hstring(dbg_data) severity note;
            end if;
        end procedure;
    begin
        -- Reset por 2 ciclos.
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst <= '0';

        -- Executa o programa (folga: ~50 ciclos para ~22 instruções + halt).
        for i in 0 to 49 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        -- Confere resultados (x-num, valor esperado).
        chk("auipc s6",  22, x"00002000");
        chk("t0",         5, x32(10));
        chk("t1",         6, x32(3));
        chk("add t2",     7, x32(13));
        chk("sub s0",     8, x32(7));
        chk("and s1",     9, x32(2));
        chk("or  a0",    10, x32(11));
        chk("xor a1",    11, x32(9));
        chk("slli a2",   12, x32(12));
        chk("srli a3",   13, x32(5));
        chk("slti a4",   14, x32(1));
        chk("slt  a5",   15, x32(0));
        chk("a6 (branch)",16, x32(7));
        chk("a7 (branch)",17, x32(42));
        chk("lw s2",     18, x32(13));
        chk("lui s3",    19, x"00001000");
        chk("jal ra",     1, x32(88));
        chk("jal s4",    20, x32(55));
        chk("ret s5",    21, x32(100));

        wait for 5 ns;
        if errors = 0 then
            report "ALL TESTS PASSED" severity note;
        else
            report "TESTS FAILED: " & integer'image(errors) & " erro(s)" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
