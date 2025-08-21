#!/usr/bin/env bash
set -euo pipefail

# --- Minimal config (override via env if needed) ---
REPO_URL="${REPO_URL:-https://github.com/gui-awk/pizzaria-app.git}"
APP_DIR="${APP_DIR:-/opt/pizzaria-app}"
BRANCH="${BRANCH:-main}"

log(){ echo "[pizzaria] $(date '+%F %T') $*"; }

# --- 1) Prerequisites (Ubuntu/Debian) ---
# Installs git, Docker Engine and both compose variants (plugin & legacy) for safety.
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git docker.io docker-compose docker-compose-plugin || true
systemctl enable docker >/dev/null 2>&1 || true
systemctl start docker  >/dev/null 2>&1 || true

# --- 2) Sync repository (clone or fast-forward to remote) ---
mkdir -p "$APP_DIR"
if [ ! -d "$APP_DIR/.git" ]; then
  log "Cloning $REPO_URL into $APP_DIR (branch $BRANCH)"
  git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR"
else
  log "Updating repository"
  git -C "$APP_DIR" fetch origin "$BRANCH" --quiet
  LOCAL="$(git -C "$APP_DIR" rev-parse HEAD)"
  REMOTE="$(git -C "$APP_DIR" rev-parse origin/$BRANCH || echo "$LOCAL")"
  [ "$LOCAL" != "$REMOTE" ] && git -C "$APP_DIR" reset --hard "origin/$BRANCH"
fi

# --- 3) Ensure this script lives in APP_DIR (so cron can call it) ---
if [ "$(realpath "$0")" != "$APP_DIR/deploy.sh" ]; then
  install -m 0755 "$0" "$APP_DIR/deploy.sh"
fi

# --- 4) Rebuild + start stack (always rebuild image) ---
cd "$APP_DIR"
# Always rebuild to guarantee freshness; pulls newest base layers and ignores cache.
docker compose build --pull --no-cache
docker compose up -d --remove-orphans

# --- 5) Cron every 5 minutes (idempotent) ---
# Re-runs the same script; logs to /var/log/pizzaria-deploy.log
CRON_LINE="*/5 * * * * bash $APP_DIR/deploy.sh >> /var/log/pizzaria-deploy.log 2>&1"
( crontab -l 2>/dev/null | grep -v 'pizzaria-deploy' ; echo "$CRON_LINE" ) | crontab -

log "Done."
