-- Gerado por asm.py — NÃO editar à mão.
-- ROM de instruções como constante VHDL.
library ieee;
use ieee.std_logic_1164.all;
use work.riscv_pkg.all;

package test_core_rom_pkg is
    constant PROGRAM : word_array(0 to 26) := (
        x"00002B17",
        x"00A00293",
        x"00300313",
        x"006283B3",
        x"40628433",
        x"0062F4B3",
        x"0062E533",
        x"0062C5B3",
        x"00231613",
        x"0012D693",
        x"00532713",
        x"0062A7B3",
        x"00528463",
        x"06300813",
        x"00700813",
        x"00629463",
        x"05800893",
        x"02A00893",
        x"00702023",
        x"00002903",
        x"000019B7",
        x"00C000EF",
        x"06400A93",
        x"00000663",
        x"03700A13",
        x"00008067",
        x"00000063"
    );
end package test_core_rom_pkg;
