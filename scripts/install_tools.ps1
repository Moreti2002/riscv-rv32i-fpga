# install_tools.ps1 — Instalação silenciosa de Quartus Lite + Questa no D:.
#
# Projeto: Processador RISC-V RV32I na DE10-Lite. Autor: João Moreti.
#
# Rodado por uma tarefa agendada com privilégios elevados (os instaladores da
# Altera exigem UAC). Instala em D:\altera_lite\22.1. Idempotente o suficiente:
# se já instalado, o instalador detecta e finaliza.
#
# Log: D:\altera_installers\install_tools.log

$ErrorActionPreference = 'Continue'
$base = 'D:\altera_lite\22.1'
$inst = 'D:\altera_installers'
$log  = Join-Path $inst 'install_tools.log'

function Log($m) { "$(Get-Date -Format o)  $m" | Out-File -FilePath $log -Append -Encoding utf8 }

Log "==================== INICIO install_tools ===================="
Log ("Elevado: " + ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))

# --- Quartus Lite (inclui suporte MAX 10 via .qdz na mesma pasta) ---
$q  = Join-Path $inst 'QuartusLiteSetup-22.1std.2.922-windows.exe'
$qa = @('--mode','unattended','--unattendedmodeui','none','--installdir',$base,'--accept_eula','1')
Log "Instalando Quartus Lite..."
try {
    $p = Start-Process -FilePath $q -ArgumentList $qa -PassThru -Wait
    Log ("Quartus exit code: " + $p.ExitCode)
} catch {
    Log ("ERRO Quartus: " + $_.Exception.Message)
}

# --- Questa - Intel FPGA Starter Edition ---
$qs  = Join-Path $inst 'QuestaSetup-22.1std.2.922-windows.exe'
$qsa = @('--mode','unattended','--unattendedmodeui','none','--installdir',$base,'--accept_eula','1')
Log "Instalando Questa..."
try {
    $p2 = Start-Process -FilePath $qs -ArgumentList $qsa -PassThru -Wait
    Log ("Questa exit code: " + $p2.ExitCode)
} catch {
    Log ("ERRO Questa: " + $_.Exception.Message)
}

# --- Verificação ---
$qsh = Join-Path $base 'quartus\bin64\quartus_sh.exe'
Log ("quartus_sh existe: " + (Test-Path $qsh))
$vsim = Get-ChildItem -Path $base -Recurse -Filter 'vsim.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
Log ("vsim encontrado: " + ($null -ne $vsim) + " " + $vsim.FullName)
Log "==================== FIM install_tools ===================="
