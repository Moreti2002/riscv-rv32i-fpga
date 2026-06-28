# riscv_de2.sdc — Constraints de timing para a DE2 (Cyclone II).
# Mesma lógica do SDC da DE10-Lite, mas o clock é o CLOCK_50 (pino N2).

# Clock de 50 MHz
create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]
derive_clock_uncertainty

# MULTICYCLE — coerente com o clock-enable (a CPU dá um passo a cada 16 ciclos).
set_multicycle_path -setup -end 16 -from [get_clocks CLOCK_50] -to [get_clocks CLOCK_50]
set_multicycle_path -hold  -end 15 -from [get_clocks CLOCK_50] -to [get_clocks CLOCK_50]

# Entradas/saídas assíncronas (chaves, botões, LEDs, displays) — sem timing rígido.
set_false_path -from [get_ports {SW[*] KEY[*]}] -to *
set_false_path -from * -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]
