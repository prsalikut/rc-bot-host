# RentCompute bot host — one-line installer.
# Run on the ThinkPad in PowerShell:   iex (irm https://is.gd/SETUP)
# (WSL2 + Ubuntu are already installed on this machine, so no reboot needed.)
$ErrorActionPreference = 'Continue'
Write-Host '== RentCompute bot host: setup ==' -ForegroundColor Cyan

Write-Host '[1/3] Enabling systemd in WSL...'
wsl -d Ubuntu -u root -- bash -c "grep -q '^\[boot\]' /etc/wsl.conf 2>/dev/null || printf '[boot]\nsystemd=true\n' >> /etc/wsl.conf"
wsl --shutdown
Start-Sleep -Seconds 5

Write-Host '[2/3] Installing Docker + bot host inside WSL (a few minutes, let it run)...'
wsl -d Ubuntu -u root -- bash -c "export DEBIAN_FRONTEND=noninteractive; apt-get update -y >/dev/null 2>&1; apt-get install -y git ca-certificates >/dev/null 2>&1; rm -rf /root/rc-bot-host; git clone --depth 1 https://github.com/prsalikut/rc-bot-host /root/rc-bot-host && cd /root/rc-bot-host && sed -i 's/\r$//' *.sh && chmod +x *.sh && ./install.sh"

Write-Host '[3/3] Creating a test bot...'
wsl -d Ubuntu -u root -- bash -c "cd /root/rc-bot-host && ./add-bot.sh testbot node && cp examples/testbot-index.js bots/testbot/app/index.js"

Write-Host ''
Write-Host '== Bot host is READY ==' -ForegroundColor Green
Write-Host 'Two steps left:' -ForegroundColor Yellow
Write-Host '  1) Add your Discord token:   notepad \\wsl$\Ubuntu\root\rc-bot-host\bots\testbot\.env'
Write-Host '     put the token after  DISCORD_TOKEN=  then Save & close.'
Write-Host '  2) Start the bot:            iex (irm https://is.gd/START)'
