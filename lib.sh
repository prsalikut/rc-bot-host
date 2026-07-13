#!/usr/bin/env bash
# Shared config + helpers for the RentCompute bot host.
# Sourced by every other script. Edit the defaults below or override via env vars.
set -euo pipefail

# Bundle lives wherever this file is — everything is relative to it, so the whole
# folder is self-contained and portable (copy it anywhere and it still works).
RC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOTS_DIR="$RC_DIR/bots"
BACKUP_DIR="$RC_DIR/backups"
STATE_DIR="$RC_DIR/state"
mkdir -p "$BOTS_DIR" "$BACKUP_DIR" "$STATE_DIR"

# ── Tunables (override via env) ─────────────────────────────
: "${BOT_MEM:=512m}"            # RAM cap per bot
: "${BANDWIDTH_CAP_GB:=50}"     # monthly egress cap per bot (matches the 50 GB plan)
: "${BACKUP_KEEP:=14}"          # how many daily backups to retain

log()  { printf '[rc-bot-host] %s\n' "$*"; }
die()  { printf '[rc-bot-host] ERROR: %s\n' "$*" >&2; exit 1; }

# docker stats prints sizes like "1.23GB" / "45.6MB" / "789kB" / "12B" (SI, 1000-based).
to_bytes() {
  local v num unit
  v="$1"
  num="$(printf '%s' "$v" | grep -oE '^[0-9.]+' || echo 0)"
  unit="$(printf '%s' "$v" | grep -oE '[A-Za-z]+$' | tr '[:lower:]' '[:upper:]' || echo B)"
  case "$unit" in
    B|"")     awk "BEGIN{printf \"%d\", $num}";;
    KB|K)     awk "BEGIN{printf \"%d\", $num*1000}";;
    MB|M)     awk "BEGIN{printf \"%d\", $num*1000000}";;
    GB|G)     awk "BEGIN{printf \"%d\", $num*1000000000}";;
    TB|T)     awk "BEGIN{printf \"%d\", $num*1000000000000}";;
    *)        echo 0;;
  esac
}
