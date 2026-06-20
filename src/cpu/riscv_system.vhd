-------------------------------------------------------------------------------
-- riscv_system.vhd  —  Sistema mínimo: núcleo + ROM + RAM (sem I/O).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
-- Junta o núcleo, a memória de instruções e a de dados num bloco fechado e
-- simulável. É o que o testbench tb_core exercita: carrega um programa no .hex,
-- pulsa o clock e observa registradores pela porta de depuração.
--
-- O top-level da placa NÃO usa este sistema diretamente (lá a memória de dados
-- divide espaço com o I/O mapeado); este existe para validar a CPU isolada.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.riscv_pkg.all;

entity riscv_system is
    generic (
        WORDS : natural    := 256;
        INIT  : word_array := (0 => (others => '0'))
    );
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        pc_out       : out std_logic_vector(31 downto 0);
        dbg_reg_addr : in  std_logic_vector(4 downto 0) := (others => '0');
        dbg_reg_data : out std_logic_vector(31 downto 0)
    );
end entity riscv_system;

architecture rtl of riscv_system is
    signal pc          : std_logic_vector(31 downto 0);
    signal instr       : std_logic_vector(31 downto 0);
    signal dmem_addr   : std_logic_vector(31 downto 0);
    signal dmem_wdata  : std_logic_vector(31 downto 0);
    signal dmem_rdata  : std_logic_vector(31 downto 0);
    signal dmem_we     : std_logic;
    signal dmem_re     : std_logic;
    signal dmem_funct3 : std_logic_vector(2 downto 0);
begin

    u_core : entity work.riscv_core
        port map (
            clk => clk, rst => rst,
            pc_out => pc, instr => instr,
            dmem_addr => dmem_addr, dmem_wdata => dmem_wdata,
            dmem_we => dmem_we, dmem_re => dmem_re, dmem_funct3 => dmem_funct3,
            dmem_rdata => dmem_rdata,
            dbg_reg_addr => dbg_reg_addr, dbg_reg_data => dbg_reg_data
        );

    u_imem : entity work.imem
        generic map (WORDS => WORDS, INIT => INIT)
        port map (addr => pc, instr => instr);

    u_dmem : entity work.dmem
        generic map (WORDS => WORDS)
        port map (
            clk => clk, we => dmem_we, addr => dmem_addr,
            wdata => dmem_wdata, rdata => dmem_rdata
        );

    pc_out <= pc;

end architecture rtl;
