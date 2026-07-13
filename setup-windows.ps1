# RentCompute bot host — Windows 11 bootstrapper.
# Sets up WSL2 + Ubuntu + systemd, copies this bundle into WSL, and runs install.sh.
#
# HOW TO RUN: right-click this file -> "Run with PowerShell", OR in an *Administrator*
# PowerShell:   Set-ExecutionPolicy -Scope Process Bypass -Force ; .\setup-windows.ps1
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
Write-Host '== RentCompute bot host: WSL2 setup ==' -ForegroundColor Cyan

# 1) WSL + Ubuntu
if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
  Write-Host 'Installing WSL + Ubuntu... a REBOOT is likely required.' -ForegroundColor Yellow
  wsl --install -d Ubuntu
  Write-Host 'If Windows asks you to reboot, reboot and then run this script again.' -ForegroundColor Yellow
  exit 0
}
wsl --install -d Ubuntu 2>$null   # no-op if already installed
wsl --set-default-version 2 | Out-Null

# 2) Enable systemd in WSL (Docker needs it)
Write-Host 'Enabling systemd in WSL...'
wsl -d Ubuntu -u root -- bash -c "grep -q '^\[boot\]' /etc/wsl.conf 2>/dev/null || printf '[boot]\nsystemd=true\n' >> /etc/wsl.conf"
wsl --shutdown
Start-Sleep -Seconds 4

# 3) Copy this bundle into WSL and run install.sh (as root for a simple single-user host)
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$wslPath = '/root/rc-bot-host'
$unc     = '\\wsl$\Ubuntu\root\rc-bot-host'
Write-Host "Copying bundle into WSL ($wslPath)..."
wsl -d Ubuntu -u root -- bash -c "mkdir -p $wslPath"
robocopy $here $unc /E /XD backups state node_modules /NFL /NDL /NJH /NJS | Out-Null

Write-Host 'Running install.sh inside WSL...' -ForegroundColor Cyan
wsl -d Ubuntu -u root -- bash -c "cd $wslPath && sed -i 's/\r`$//' *.sh && chmod +x *.sh && ./install.sh"

Write-Host ''
Write-Host '== Done. ==' -ForegroundColor Green
Write-Host 'Add a bot:'
Write-Host '  wsl -d Ubuntu -u root -- bash -c "cd /root/rc-bot-host && ./add-bot.sh mybot node"'
Write-Host 'IMPORTANT: keep the laptop plugged in and set to NEVER sleep, or the bots stop when it sleeps.'
