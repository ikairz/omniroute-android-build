#!/data/data/com.termux/files/usr/bin/sh
set -eu

APP_DIR="${APP_DIR:-/data/data/com.termux/files/home/OmniRoute}"
PORT="${PORT:-20128}"
HOST="${HOST:-0.0.0.0}"

cd "$APP_DIR"
export NODE_ENV=production
export NEXT_TELEMETRY_DISABLED=1
export OMNIROUTE_DISABLE_BACKGROUND_SERVICES="${OMNIROUTE_DISABLE_BACKGROUND_SERVICES:-true}"
export PORT HOST

pkill -9 -f 'next start' 2>/dev/null || true
pkill -9 -f 'server.js' 2>/dev/null || true

if command -v termux-wake-lock >/dev/null 2>&1; then
  termux-wake-lock || true
fi

# Prefer the local Next CLI from the phone's own node_modules. Do not rely on cloud-built node_modules.
exec ./node_modules/.bin/next start -H "$HOST" -p "$PORT"
