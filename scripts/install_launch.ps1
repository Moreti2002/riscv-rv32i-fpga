# install_launch.ps1 — Lançador auto-elevável da instalação de Quartus+Questa.
#
# Projeto: Processador RISC-V na DE10-Lite. Autor: João Moreti.
#
# COMO USAR: dê duplo-clique neste arquivo (ou rode-o) e clique "Sim" no UAC.
# Ele eleva e chama install_tools.ps1, que instala Quartus Lite + Questa no D:.
# Quando terminar, avise o Claude para validar (síntese da Frente A não precisa
# de licença; a simulação no Questa precisa da licença gratuita — passo à parte).

$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $here 'install_tools.ps1'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Solicitando elevacao (UAC)..."
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$target`""
    )
    exit
}

# Já elevado: roda direto.
& $target
Write-Host ""
Write-Host "Instalacao finalizada. Log em D:\altera_installers\install_tools.log"
Write-Host "Pressione ENTER para fechar."
[void][System.Console]::ReadLine()
