#!/usr/bin/env bash
# Sets up Docker + cron on this Linux box (WSL Ubuntu or a VPS). Idempotent —
# safe to re-run. Run from inside WSL (or on the VPS): ./install.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
log "Installing RentCompute bot host in $RC_DIR"

# ── Docker ──────────────────────────────────────────────────
if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker (official convenience script)…"
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER" 2>/dev/null || true
fi
# Start the daemon (systemd if present — WSL needs systemd=true in /etc/wsl.conf)
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now docker 2>/dev/null || sudo service docker start 2>/dev/null || true
else
  sudo service docker start 2>/dev/null || true
fi
docker info >/dev/null 2>&1 || die "Docker isn't running. In WSL: enable systemd (see README), run 'wsl --shutdown' from Windows, reopen, and re-run. (A fresh docker-group add may also need a new login.)"

# ── cron (backups, bandwidth guard, monthly reset) ──────────
command -v crontab >/dev/null 2>&1 || { sudo apt-get update -y && sudo apt-get install -y cron; }
sudo service cron start 2>/dev/null || sudo systemctl enable --now cron 2>/dev/null || true

chmod +x "$RC_DIR"/*.sh
CRON_TMP="$(mktemp)"
crontab -l 2>/dev/null | grep -v 'rc-bot-host' > "$CRON_TMP" || true
{
  echo "15 * * * * $RC_DIR/bandwidth-guard.sh >> $STATE_DIR/guard.log 2>&1 # rc-bot-host"
  echo "30 4 * * * $RC_DIR/backup.sh          >> $STATE_DIR/backup.log 2>&1 # rc-bot-host"
  echo "5 0 1 * * $RC_DIR/monthly-reset.sh    >> $STATE_DIR/guard.log 2>&1 # rc-bot-host"
} >> "$CRON_TMP"
crontab "$CRON_TMP" && rm -f "$CRON_TMP"

log "Done."
log "  bandwidth guard: hourly   (cap ${BANDWIDTH_CAP_GB} GB/mo egress per bot)"
log "  backups:         daily 04:30  (keep ${BACKUP_KEEP})"
log "Add a bot with:   ./add-bot.sh <name> <node|python|java>"
