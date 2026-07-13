#!/usr/bin/env bash
# Scaffold a new bot.   Usage: ./add-bot.sh <name> <node|python|java> [entrypoint]
# Then put your code in bots/<name>/app/, set DISCORD_TOKEN in bots/<name>/.env,
# and run ./start-bot.sh <name>.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

name="${1:-}"; runtime="${2:-node}"; entry="${3:-}"
[ -n "$name" ] || die "usage: ./add-bot.sh <name> <node|python|java> [entrypoint]"
[[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || die "name must be letters/numbers/-/_ only"

botdir="$BOTS_DIR/$name"; app="$botdir/app"
mkdir -p "$app"

case "$runtime" in
  node)   image="node:20-alpine";              def="node index.js"
          [ -f "$app/package.json" ] || printf '{"name":"%s","private":true,"dependencies":{"discord.js":"^14.16.0"}}\n' "$name" > "$app/package.json";;
  python) image="python:3.12-alpine";          def="python bot.py"
          [ -f "$app/requirements.txt" ] || echo 'discord.py' > "$app/requirements.txt";;
  java)   image="eclipse-temurin:21-jre-alpine"; def="java -jar bot.jar";;
  *)      die "unknown runtime '$runtime' (node | python | java)";;
esac
entry="${entry:-$def}"

echo "$image" > "$botdir/.image"
[ -f "$botdir/.env" ] || printf '# Paste your Discord bot token (from discord.com/developers → your app → Bot → Reset Token)\nDISCORD_TOKEN=\n' > "$botdir/.env"

# Startup wrapper: installs deps (into the mounted volume) then runs the bot.
cat > "$botdir/run.sh" <<EOF
#!/bin/sh
set -e
cd /bot/app
[ -f package.json ]    && npm  install --omit=dev --no-audit --no-fund --cache /tmp/.npm >/dev/null 2>&1 || true
[ -f requirements.txt ] && pip  install --no-cache-dir -r requirements.txt >/dev/null 2>&1 || true
exec $entry
EOF
chmod +x "$botdir/run.sh"

log "Scaffolded '$name' ($runtime) → $app"
log "  1. put your bot code in:  $app"
log "  2. set the token in:      $botdir/.env"
log "  3. start it:              ./start-bot.sh $name"
