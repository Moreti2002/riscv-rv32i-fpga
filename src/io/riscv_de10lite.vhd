-------------------------------------------------------------------------------
-- riscv_de10lite.vhd  —  Top-level do processador na DE10-Lite (Frente B, etapa 7).
--
-- Projeto: Processador RISC-V RV32I single-cycle na DE10-Lite.  Autor: João Moreti.
--
-- Junta núcleo + ROM + RAM + I/O mapeado em memória + display decimal.
-- A "calculadora" é um PROGRAMA em assembly (mem/calc.hex) rodando no processador.
--
-- Clock-enable (tick): a CPU dá um passo a cada 2^CPU_DIV ciclos de 50 MHz.
-- Isso dá folga de timing ao caminho single-cycle (ver multicycle no .sdc da placa)
-- sem criar clock derivado de lógica — tudo continua no domínio de 50 MHz.
--
-- Reset: KEY0 (ativo-baixo) -> rst interno ativo-alto.
--
-- Mapa de I/O (no barramento de dados):
--   0x0000_1xxx : RAM de dados (256 palavras)
--   0x0000_2000 : (R) SW[9:0]           -- operandos/seleção
--   0x0000_2004 : (R) KEY pressionado    -- bit0=KEY0, bit1=KEY1 (1 = pressionado)
--   0x0000_2010 : (W) LEDR[9:0]
--   0x0000_2020 : (W) valor a exibir (decimal com sinal nos 6 HEX)
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.riscv_pkg.all;
use work.calc_rom_pkg.all;                 -- ROM da calculadora (gerada por asm.py)

entity riscv_de10lite is
    generic (
        CPU_DIV : natural := 4             -- passo da CPU a cada 2^4 = 16 ciclos
    );
    port (
        MAX10_CLK1_50 : in  std_logic;                       -- 50 MHz (pino P11)
        KEY           : in  std_logic_vector(1 downto 0);    -- ativo-baixo
        SW            : in  std_logic_vector(9 downto 0);
        LEDR          : out std_logic_vector(9 downto 0);
        HEX0          : out std_logic_vector(7 downto 0);
        HEX1          : out std_logic_vector(7 downto 0);
        HEX2          : out std_logic_vector(7 downto 0);
        HEX3          : out std_logic_vector(7 downto 0);
        HEX4          : out std_logic_vector(7 downto 0);
        HEX5          : out std_logic_vector(7 downto 0)
    );
end entity riscv_de10lite;

architecture rtl of riscv_de10lite is
    signal clk  : std_logic;
    signal rst  : std_logic;
    signal en   : std_logic;
    signal cnt  : unsigned(CPU_DIV-1 downto 0) := (others => '0');

    -- barramentos do núcleo
    signal pc          : std_logic_vector(31 downto 0);
    signal instr       : std_logic_vector(31 downto 0);
    signal dmem_addr   : std_logic_vector(31 downto 0);
    signal dmem_wdata  : std_logic_vector(31 downto 0);
    signal core_rdata  : std_logic_vector(31 downto 0);
    signal dmem_we     : std_logic;
    signal dmem_re     : std_logic;
    signal dmem_funct3 : std_logic_vector(2 downto 0);

    -- RAM
    signal ram_we   : std_logic;
    signal ram_q    : std_logic_vector(31 downto 0);

    -- decode
    signal sel_ram, sel_io : std_logic;
    signal io_off          : std_logic_vector(7 downto 0);

    -- registradores de I/O
    signal ledr_reg : std_logic_vector(9 downto 0) := (others => '0');
    signal disp_reg : std_logic_vector(31 downto 0) := (others => '0');

    -- display
    signal seg0, seg1, seg2, seg3, seg4, seg5 : std_logic_vector(6 downto 0);
    signal sign_led, ovf_led                  : std_logic;
begin
    clk <= MAX10_CLK1_50;
    rst <= not KEY(0);                 -- KEY0 ativo-baixo -> reset ativo-alto

    ---------------------------------------------------------------------------
    -- Gerador de tick (clock-enable): passo a cada 2^CPU_DIV ciclos.
    ---------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            cnt <= cnt + 1;
        end if;
    end process;
    en <= '1' when cnt = 0 else '0';

    ---------------------------------------------------------------------------
    -- Decodificação de endereço do barramento de dados
    ---------------------------------------------------------------------------
    sel_ram <= '1' when dmem_addr(15 downto 12) = x"1" else '0';   -- 0x1xxx
    sel_io  <= '1' when dmem_addr(15 downto 12) = x"2" else '0';   -- 0x2xxx
    io_off  <= dmem_addr(7 downto 0);

    ---------------------------------------------------------------------------
    -- Núcleo
    ---------------------------------------------------------------------------
    u_core : entity work.riscv_core
        port map (
            clk => clk, rst => rst, en => en,
            pc_out => pc, instr => instr,
            dmem_addr => dmem_addr, dmem_wdata => dmem_wdata,
            dmem_we => dmem_we, dmem_re => dmem_re, dmem_funct3 => dmem_funct3,
            dmem_rdata => core_rdata,
            dbg_reg_addr => (others => '0'), dbg_reg_data => open
        );

    ---------------------------------------------------------------------------
    -- Memória de instruções
    ---------------------------------------------------------------------------
    u_imem : entity work.imem
        generic map (WORDS => 256, INIT => PROGRAM)
        port map (addr => pc, instr => instr);

    ---------------------------------------------------------------------------
    -- RAM de dados (escrita só na região RAM)
    ---------------------------------------------------------------------------
    ram_we <= dmem_we and sel_ram;
    u_dmem : entity work.dmem
        generic map (WORDS => 256)
        port map (clk => clk, we => ram_we, addr => dmem_addr,
                  wdata => dmem_wdata, rdata => ram_q);

    ---------------------------------------------------------------------------
    -- Leitura do barramento de dados (mux RAM / I/O)
    ---------------------------------------------------------------------------
    process(sel_ram, sel_io, io_off, ram_q, SW, KEY)
    begin
        if sel_ram = '1' then
            core_rdata <= ram_q;
        elsif sel_io = '1' then
            case io_off is
                when x"00"  => core_rdata <= std_logic_vector(resize(unsigned(SW), 32));
                when x"04"  => core_rdata <= (0 => not KEY(0), 1 => not KEY(1), others => '0');
                when others => core_rdata <= (others => '0');
            end case;
        else
            core_rdata <= (others => '0');
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Escrita nos registradores de I/O
    ---------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ledr_reg <= (others => '0');
                disp_reg <= (others => '0');
            elsif (dmem_we = '1') and (sel_io = '1') then
                case io_off is
                    when x"10"  => ledr_reg <= dmem_wdata(9 downto 0);
                    when x"20"  => disp_reg <= dmem_wdata;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    LEDR <= ovf_led & sign_led & ledr_reg(7 downto 0);  -- LED9=ovf, LED8=sinal

    ---------------------------------------------------------------------------
    -- Display decimal com sinal
    ---------------------------------------------------------------------------
    u_disp : entity work.display_unit
        port map (
            value => disp_reg,
            hex0 => seg0, hex1 => seg1, hex2 => seg2,
            hex3 => seg3, hex4 => seg4, hex5 => seg5,
            sign_led => sign_led, ovf_led => ovf_led
        );

    -- HEX: bit7 = ponto decimal (apagado = '1'); bits 6..0 = segmentos.
    HEX0 <= '1' & seg0;
    HEX1 <= '1' & seg1;
    HEX2 <= '1' & seg2;
    HEX3 <= '1' & seg3;
    HEX4 <= '1' & seg4;
    HEX5 <= '1' & seg5;

end architecture rtl;
