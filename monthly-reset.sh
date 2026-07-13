#!/usr/bin/env bash
# Runs on the 1st: clears bandwidth caps and resumes any bot that was stopped.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "Monthly reset — clearing caps, resuming stopped bots."
for f in "$STATE_DIR"/*.capped; do
  [ -e "$f" ] || continue
  bot="$(basename "$f" .capped)"
  rm -f "$f"
  docker start "rcbot-$bot" >/dev/null 2>&1 && log "resumed $bot" || true
done
# tidy last month's per-bot counters
find "$STATE_DIR" -name '*.bytes' -mtime +2 -delete 2>/dev/null || true
