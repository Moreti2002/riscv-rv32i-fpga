-- Gerado por asm.py — NÃO editar à mão.
-- ROM de instruções como constante VHDL.
library ieee;
use ieee.std_logic_1164.all;
use work.riscv_pkg.all;

package calc_rom_pkg is
    constant PROGRAM : word_array(0 to 22) := (
        x"000022B7",
        x"0002A303",
        x"00F37513",
        x"00435393",
        x"00F3F593",
        x"00835E13",
        x"003E7E13",
        x"000E0E63",
        x"00100E93",
        x"01DE0E63",
        x"00200E93",
        x"01DE0E63",
        x"00B56633",
        x"01C0006F",
        x"00B50633",
        x"0140006F",
        x"40B50633",
        x"00C0006F",
        x"00B57633",
        x"0040006F",
        x"02C2A023",
        x"01C2A823",
        x"FADFF06F"
    );
end package calc_rom_pkg;
