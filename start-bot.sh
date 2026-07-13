#!/usr/bin/env bash
# Start (or restart) a bot in a sandboxed container.  Usage: ./start-bot.sh <name>
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

name="${1:?usage: ./start-bot.sh <name>}"
botdir="$BOTS_DIR/$name"
[ -d "$botdir" ] || die "no such bot: $name (run ./add-bot.sh $name node first)"
img="$(cat "$botdir/.image" 2>/dev/null || echo node:20-alpine)"
grep -qE '^DISCORD_TOKEN=.+' "$botdir/.env" 2>/dev/null || log "warning: DISCORD_TOKEN looks empty in $botdir/.env"

docker rm -f "rcbot-$name" >/dev/null 2>&1 || true
docker run -d --name "rcbot-$name" \
  --restart unless-stopped \
  --memory "$BOT_MEM" --memory-swap "$BOT_MEM" --pids-limit 256 \
  --cap-drop ALL --security-opt no-new-privileges \
  -e HOME=/tmp --tmpfs /tmp:rw,size=256m \
  -v "$botdir:/bot" -w /bot/app \
  --env-file "$botdir/.env" \
  --entrypoint /bin/sh \
  "$img" /bot/run.sh

rm -f "$STATE_DIR/${name}.capped"
log "Started rcbot-$name  (RAM $BOT_MEM, ${BANDWIDTH_CAP_GB} GB/mo egress cap)."
log "Logs:  docker logs -f rcbot-$name"
