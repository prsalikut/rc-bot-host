#!/usr/bin/env bash
# Move the whole bot host (bots + config) to a VPS and start it there.
# Usage: ./transfer-to-vps.sh user@vps-host [remote-dir]
# Prereqs on the VPS: SSH access + Ubuntu/Debian. This copies everything, runs
# install.sh remotely, and restarts every bot on the VPS.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

target="${1:?usage: ./transfer-to-vps.sh user@host [remote-dir]}"
remote="${2:-rc-bot-host}"

log "Stopping local bots so their data is consistent for the move…"
docker ps --filter "name=rcbot-" --format '{{.Names}}' | xargs -r docker stop >/dev/null 2>&1 || true

log "Copying bundle + bots to $target:$remote  (node_modules/state/backups skipped)…"
rsync -az \
  --exclude 'node_modules' --exclude '__pycache__' \
  --exclude 'state' --exclude 'backups' \
  "$RC_DIR/" "$target:$remote/"

log "Installing + starting on the VPS…"
ssh "$target" "cd '$remote' && sed -i 's/\r\$//' *.sh && chmod +x *.sh && ./install.sh && for d in bots/*/; do [ -d \"\$d\" ] && ./start-bot.sh \"\$(basename \"\$d\")\"; done"

log "Done — bots now run on $target."
log "They're stopped here. Once you've confirmed the VPS is serving them, remove them locally:"
log "  docker ps -a --filter name=rcbot- --format '{{.Names}}' | xargs -r docker rm -f"
