#!/usr/bin/env bash
# Backs up all bot code + config (not node_modules — those reinstall on start).
# Runs daily via cron; also runnable by hand: ./backup.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

ts="$(date +%Y%m%d-%H%M%S)"
out="$BACKUP_DIR/bots-$ts.tar.gz"
[ -n "$(ls -A "$BOTS_DIR" 2>/dev/null)" ] || { log "no bots to back up yet"; exit 0; }

log "Backing up bots → $out"
tar -C "$RC_DIR" \
  --exclude='bots/*/app/node_modules' \
  --exclude='bots/*/app/__pycache__' \
  -czf "$out" bots || die "backup failed"

# Rotate: keep the newest $BACKUP_KEEP
ls -1t "$BACKUP_DIR"/bots-*.tar.gz 2>/dev/null | tail -n +"$(( BACKUP_KEEP + 1 ))" | xargs -r rm -f
log "Backup done ($(du -h "$out" | cut -f1)); keeping newest $BACKUP_KEEP."
log "Restore with:  tar -C \"$RC_DIR\" -xzf $out"
