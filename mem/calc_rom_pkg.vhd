-- Gerado por asm.py — NÃO editar à mão.
-- ROM de instruções como constante VHDL.
library ieee;
use ieee.std_logic_1164.all;
use work.riscv_pkg.all;

package calc_rom_pkg is
    constant PROGRAM : word_array(0 to 41) := (
        x"000022B7",
        x"00000413",
        x"0282A023",
        x"0002A303",
        x"00835393",
        x"0033F393",
        x"0072A823",
        x"0042AE03",
        x"002E7E13",
        x"FE0E02E3",
        x"06C000EF",
        x"0042AE03",
        x"002E7E13",
        x"FC0E0AE3",
        x"0002A303",
        x"0FF37513",
        x"00835393",
        x"0033F393",
        x"00038E63",
        x"00100E93",
        x"01D38E63",
        x"00200E93",
        x"01D38E63",
        x"00A46433",
        x"01C0006F",
        x"00A40433",
        x"0140006F",
        x"40A40433",
        x"00C0006F",
        x"00A47433",
        x"0040006F",
        x"0282A023",
        x"0042AE03",
        x"002E7E13",
        x"FE0E1CE3",
        x"008000EF",
        x"F79FF06F",
        x"00001F37",
        x"BB8F0F13",
        x"FFFF0F13",
        x"FE0F1EE3",
        x"00008067"
    );
end package calc_rom_pkg;
