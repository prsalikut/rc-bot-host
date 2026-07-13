# RentCompute — Bot Host

Self-contained Discord-bot hosting you run on a Windows laptop via WSL2 (or on any
Ubuntu/Debian VPS). Each bot runs in its own sandboxed Docker container with a RAM
cap and a **50 GB/month egress cap**. Backups are automatic. Moving everything to a
VPS later is one command.

> ⚠️ **Untested on your exact machine.** These scripts were written for a Win11 +
> WSL2 setup but not run on it — treat the first run as a shakeout we debug together.

## Run it on the laptop (Windows 11)

1. Copy this whole folder onto the ThinkPad.
2. Right-click **`setup-windows.ps1`** → **Run with PowerShell** (it needs Administrator).
   - If it's the first time WSL is installed, Windows will ask to **reboot** — reboot and run it again.
   - It installs WSL2 + Ubuntu, enables systemd, installs Docker, and sets up cron.
3. Add your first bot:
   ```
   wsl -d Ubuntu -u root -- bash -c "cd /root/rc-bot-host && ./add-bot.sh mybot node"
   ```
   Then put your code in `bots/mybot/app/`, paste your token into `bots/mybot/.env`
   (`DISCORD_TOKEN=...`), and start it:
   ```
   wsl -d Ubuntu -u root -- bash -c "cd /root/rc-bot-host && ./start-bot.sh mybot"
   ```

**Keep the laptop plugged in and set to *never sleep*** — WSL (and your bots) pause when the machine sleeps.

## Commands (inside WSL, in this folder)

| Command | Does |
| --- | --- |
| `./add-bot.sh <name> <node\|python\|java>` | Scaffold a new bot |
| `./start-bot.sh <name>` | Start / restart a bot (sandboxed container) |
| `docker logs -f rcbot-<name>` | Tail a bot's logs |
| `docker stop rcbot-<name>` | Stop a bot |
| `./backup.sh` | Back up now (also runs daily at 04:30) |
| `./bandwidth-guard.sh` | Check egress now (also runs hourly) |
| `./transfer-to-vps.sh user@host` | Move everything to a VPS and start it there |

## Bandwidth cap

Each bot is capped at **50 GB/month egress** (`BANDWIDTH_CAP_GB`, set in `lib.sh`). The
guard runs hourly, and stops a bot that hits the cap; capped bots resume automatically
on the 1st. For normal (non-music) bots this basically never triggers — it's a safety net.

## Backups

`bots/` (code + config, minus `node_modules`) is tarred to `backups/` daily; the newest
14 are kept. Restore with `tar -C . -xzf backups/bots-YYYYMMDD-HHMMSS.tar.gz`.

## Move to a VPS later

When you rent a box, from the laptop's WSL:
```
./transfer-to-vps.sh root@your-vps-ip
```
It stops the local bots, rsyncs everything to the VPS, runs `install.sh` there, and
restarts every bot on the VPS. Because it's all Docker + a portable folder, the bots
run identically — nothing to rebuild. Once you've confirmed the VPS is serving them,
remove the local copies (the command is printed at the end).

## Sandboxing note

Bots run with `--cap-drop ALL`, `--security-opt no-new-privileges`, a PID limit, and a
RAM cap — sensible defaults for running bot code. If you'll host *customers'* AI-generated
bots (untrusted code), tighten further before that: add `--read-only` + a locked-down
egress policy, and consider one Docker network per bot.
