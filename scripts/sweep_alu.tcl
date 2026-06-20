#-----------------------------------------------------------------------------
# sweep_alu.tcl  —  Experimento de escalabilidade da ULA (Frente A).
#
# Projeto: Processador RISC-V RV32I na DE10-Lite.  Autor: João Moreti.
#
# Para cada WIDTH em {4,8,16,32,64}:
#   1. cria um projeto Quartus alvo 10M50DAF484C7G (chip da DE10-Lite);
#   2. top-level = alu_fmax_wrapper (ULA entre dois bancos de registradores);
#   3. fixa o generic WIDTH via set_parameter;
#   4. compila (Analysis&Synthesis + Fitter + Timing Analyzer);
#   5. extrai LEs, registradores e Fmax dos relatórios e grava em CSV.
#
# Uso (na máquina com Quartus instalado, a partir da RAIZ do repo):
#   quartus_sh -t scripts/sweep_alu.tcl
#
# Saída: reports/alu_sweep.csv  +  reports/fmax/W<n>/ (projetos por largura).
#
# Nota Fmax: a ULA pura é combinacional e não tem Fmax; o wrapper com
# registradores é o que permite o Timing Analyzer medir o caminho reg->ULA->reg.
#-----------------------------------------------------------------------------
package require ::quartus::flow
package require ::quartus::project

set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize "$script_dir/.."]
set src_alu    "$repo_root/src/alu/alu.vhd"
set src_wrap   "$repo_root/src/alu/alu_fmax_wrapper.vhd"
set sdc_file   "$repo_root/sdc/alu_fmax.sdc"
set out_csv    "$repo_root/reports/alu_sweep.csv"
set work_base  "$repo_root/reports/fmax"
file mkdir $work_base

set widths {4 8 16 32 64}

# Cabeçalho do CSV (sobrescreve a cada execução).
set fh [open $out_csv w]
puts $fh "width,logic_elements,registers,fmax_mhz"
close $fh

# Retorna o 1º grupo capturado da 1ª linha que casa com 'pat', ou "NA".
proc grep_file {path pat} {
    if {![file exists $path]} { return "NA" }
    set f [open $path r]
    set data [read $f]
    close $f
    foreach line [split $data "\n"] {
        if {[regexp $pat $line all m]} { return [string map {, {}} $m] }
    }
    return "NA"
}

foreach w $widths {
    set rev  "alu_fmax_W$w"
    set pdir "$work_base/W$w"
    file mkdir $pdir
    cd $pdir

    if {[is_project_open]} { project_close }
    project_new $rev -overwrite

    set_global_assignment -name FAMILY "MAX 10"
    set_global_assignment -name DEVICE 10M50DAF484C7G
    set_global_assignment -name TOP_LEVEL_ENTITY alu_fmax_wrapper
    set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
    set_global_assignment -name VHDL_FILE $src_alu
    set_global_assignment -name VHDL_FILE $src_wrap
    set_global_assignment -name SDC_FILE  $sdc_file
    set_parameter         -name WIDTH     $w

    puts "==== Compilando WIDTH=$w ..."
    execute_flow -compile

    project_close

    # Extrai dados dos relatórios-texto (estáveis entre versões do Quartus).
    set le   [grep_file "$pdir/$rev.fit.summary" {Total logic elements\s*:\s*([0-9,]+)}]
    set regs [grep_file "$pdir/$rev.fit.summary" {Total registers\s*:\s*([0-9,]+)}]
    # 1ª linha "<num> MHz ; ... ; clk" da tabela Fmax Summary do STA (pior modelo).
    set fmax [grep_file "$pdir/$rev.sta.rpt"     {;\s*([0-9.]+)\s*MHz\s*;[^;]*;\s*clk\s*;}]

    set fh [open $out_csv a]
    puts $fh "$w,$le,$regs,$fmax"
    close $fh
    puts "==== WIDTH=$w  LE=$le  REG=$regs  Fmax=$fmax MHz\n"
}

puts "Sweep concluido. CSV: $out_csv"
