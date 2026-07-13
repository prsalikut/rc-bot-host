# RentCompute bot host — start the test bot and show its logs.
# Run on the ThinkPad after adding your token:   iex (irm https://is.gd/START)
Write-Host '== Starting testbot ==' -ForegroundColor Cyan
wsl -d Ubuntu -u root -- bash -c "cd /root/rc-bot-host && ./start-bot.sh testbot && sleep 5 && echo '----- LOGS -----' && docker logs rcbot-testbot 2>&1 | tail -n 25"
Write-Host ''
Write-Host "If you see 'Online as <name>' above, your bot is live. If not, copy the logs to Claude." -ForegroundColor Yellow
