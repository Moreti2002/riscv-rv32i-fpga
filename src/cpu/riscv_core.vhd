-------------------------------------------------------------------------------
-- riscv_core.vhd  —  Núcleo RV32I single-cycle (Frente B, etapas 1–6).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
-- Amarra o datapath single-cycle: PC, ULA, banco de registradores, gerador de
-- imediatos, unidade de controle e unidade de branch. A memória de instruções e
-- a de dados ficam FORA (barramentos expostos), para o top-level rotear dados
-- entre RAM e I/O mapeado em memória (etapa 7).
--
-- Reset: síncrono, ativo em '1' aqui dentro (o top trata o botão ativo-baixo).
-- No reset, PC <- 0.
--
-- Cálculo dos alvos de desvio:
--   pc+4                 : sequência normal
--   pc + imm             : branch tomado e JAL (somador PC-relativo dedicado)
--   (rs1 + imm) & ~1     : JALR (usa a ULA p/ rs1+imm e zera o bit 0)
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;

entity riscv_core is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;                      -- síncrono, ativo-alto
        en          : in  std_logic := '1';               -- clock enable (passo da CPU)
        -- barramento de instruções
        pc_out      : out std_logic_vector(31 downto 0);
        instr       : in  std_logic_vector(31 downto 0);
        -- barramento de dados (LW/SW e I/O)
        dmem_addr   : out std_logic_vector(31 downto 0);
        dmem_wdata  : out std_logic_vector(31 downto 0);
        dmem_we     : out std_logic;
        dmem_re     : out std_logic;
        dmem_funct3 : out std_logic_vector(2 downto 0);
        dmem_rdata  : in  std_logic_vector(31 downto 0);
        -- depuração (só observação; tie-off no top)
        dbg_reg_addr : in  std_logic_vector(4 downto 0) := (others => '0');
        dbg_reg_data : out std_logic_vector(31 downto 0)
    );
end entity riscv_core;

architecture rtl of riscv_core is
    -- PC
    signal pc, pc_next, pc_plus4, pc_target, jalr_target : std_logic_vector(31 downto 0);

    -- Campos da instrução
    signal opcode  : std_logic_vector(6 downto 0);
    signal rd_addr : std_logic_vector(4 downto 0);
    signal rs1, rs2: std_logic_vector(4 downto 0);
    signal funct3  : std_logic_vector(2 downto 0);
    signal instr30 : std_logic;

    -- Controle
    signal reg_write, alu_src, alu_a_src        : std_logic;
    signal mem_read, mem_write                  : std_logic;
    signal branch, jump, jalr                   : std_logic;
    signal alu_op                               : std_logic_vector(3 downto 0);
    signal imm_sel                              : std_logic_vector(2 downto 0);
    signal wb_sel                               : std_logic_vector(1 downto 0);

    -- Datapath
    signal rd1, rd2, imm           : std_logic_vector(31 downto 0);
    signal alu_a, alu_b, alu_res   : std_logic_vector(31 downto 0);
    signal alu_zero                : std_logic;
    signal wb_data                 : std_logic_vector(31 downto 0);
    signal take_branch             : std_logic;
    signal rf_we                   : std_logic;
begin
    ---------------------------------------------------------------------------
    -- Campos da instrução
    ---------------------------------------------------------------------------
    opcode  <= instr(6 downto 0);
    rd_addr <= instr(11 downto 7);
    funct3  <= instr(14 downto 12);
    rs1     <= instr(19 downto 15);
    rs2     <= instr(24 downto 20);
    instr30 <= instr(30);

    ---------------------------------------------------------------------------
    -- Unidade de controle
    ---------------------------------------------------------------------------
    u_ctrl : entity work.control
        port map (
            opcode => opcode, funct3 => funct3, instr30 => instr30,
            reg_write => reg_write, alu_src => alu_src, alu_a_src => alu_a_src,
            alu_op => alu_op, imm_sel => imm_sel,
            mem_read => mem_read, mem_write => mem_write, wb_sel => wb_sel,
            branch => branch, jump => jump, jalr => jalr
        );

    ---------------------------------------------------------------------------
    -- Banco de registradores
    ---------------------------------------------------------------------------
    rf_we <= reg_write and en;

    u_rf : entity work.regfile
        generic map (XLEN => 32)
        port map (
            clk => clk, we => rf_we,
            rs1 => rs1, rs2 => rs2, rd => rd_addr, wd => wb_data,
            rd1 => rd1, rd2 => rd2,
            dbg_addr => dbg_reg_addr, dbg_data => dbg_reg_data
        );

    ---------------------------------------------------------------------------
    -- Gerador de imediatos
    ---------------------------------------------------------------------------
    u_imm : entity work.imm_gen
        port map (instr => instr, imm_sel => imm_sel, imm => imm);

    ---------------------------------------------------------------------------
    -- ULA  (A = rs1 ou PC;  B = rs2 ou imm)
    ---------------------------------------------------------------------------
    alu_a <= pc  when alu_a_src = '1' else rd1;
    alu_b <= imm when alu_src   = '1' else rd2;

    u_alu : entity work.alu
        generic map (WIDTH => 32)
        port map (a => alu_a, b => alu_b, alu_op => alu_op,
                  result => alu_res, zero => alu_zero);

    ---------------------------------------------------------------------------
    -- Unidade de branch (comparações próprias)
    ---------------------------------------------------------------------------
    u_br : entity work.branch_unit
        port map (a => rd1, b => rd2, funct3 => funct3,
                  branch => branch, take => take_branch);

    ---------------------------------------------------------------------------
    -- Barramento de dados
    ---------------------------------------------------------------------------
    dmem_addr   <= alu_res;     -- rs1 + imm
    dmem_wdata  <= rd2;
    dmem_we     <= mem_write and en;
    dmem_re     <= mem_read;
    dmem_funct3 <= funct3;

    ---------------------------------------------------------------------------
    -- Write-back mux
    ---------------------------------------------------------------------------
    with wb_sel select
        wb_data <= alu_res    when WB_ALU,
                   dmem_rdata when WB_MEM,
                   pc_plus4   when WB_PC4,
                   imm        when WB_IMM,
                   alu_res    when others;

    ---------------------------------------------------------------------------
    -- Próximo PC
    ---------------------------------------------------------------------------
    pc_plus4    <= std_logic_vector(unsigned(pc) + 4);
    pc_target   <= std_logic_vector(unsigned(pc) + unsigned(imm));      -- branch/JAL
    jalr_target <= alu_res(31 downto 1) & '0';                          -- JALR (LSB=0)

    process(pc_plus4, pc_target, jalr_target, take_branch, jump, jalr)
    begin
        if jalr = '1' then
            pc_next <= jalr_target;
        elsif (take_branch = '1') or (jump = '1') then
            pc_next <= pc_target;
        else
            pc_next <= pc_plus4;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Registrador de PC (síncrono, reset -> 0)
    ---------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pc <= (others => '0');
            elsif en = '1' then
                pc <= pc_next;
            end if;
        end if;
    end process;

    pc_out <= pc;

end architecture rtl;
