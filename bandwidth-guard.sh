#!/usr/bin/env bash
# Meters each bot's monthly egress and stops it at the cap. Runs hourly via cron.
# Tracks deltas so it survives container restarts (counter resets to 0 on restart).
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

month="$(date +%Y-%m)"
cap_bytes=$(( BANDWIDTH_CAP_GB * 1000000000 ))

for cname in $(docker ps --filter "name=rcbot-" --format '{{.Names}}' 2>/dev/null); do
  bot="${cname#rcbot-}"
  # docker stats NetIO = "RX / TX"; we cap on TX (egress).
  netio="$(docker stats --no-stream --format '{{.NetIO}}' "$cname" 2>/dev/null || echo '0B / 0B')"
  tx="$(printf '%s' "$netio" | awk -F'/' '{gsub(/ /,"",$2); print $2}')"
  cur="$(to_bytes "${tx:-0B}")"

  usefile="$STATE_DIR/${bot}.${month}.bytes"
  lastfile="$STATE_DIR/${bot}.last"
  used="$(cat "$usefile" 2>/dev/null || echo 0)"
  last="$(cat "$lastfile" 2>/dev/null || echo 0)"

  # delta since last run; negative means the container restarted → count cur as the delta
  if [ "$cur" -ge "$last" ]; then delta=$(( cur - last )); else delta="$cur"; fi
  used=$(( used + delta ))
  echo "$used" > "$usefile"
  echo "$cur"  > "$lastfile"

  if [ "$used" -ge "$cap_bytes" ]; then
    log "CAP: '$bot' hit ${BANDWIDTH_CAP_GB} GB this month ($(( used/1000000000 )) GB) — stopping."
    docker stop "$cname" >/dev/null 2>&1 || true
    touch "$STATE_DIR/${bot}.capped"
  fi
done
