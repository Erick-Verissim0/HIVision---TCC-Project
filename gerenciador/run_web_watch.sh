#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$PROJECT_ROOT/.flutter.pid"

cd "$PROJECT_ROOT"

flutter run \
  -d chrome \
  --web-hostname=localhost \
  --web-port=3000 \
  --web-browser-debug-port=9222 \
  --host-vmservice-port=8181 \
  --pid-file="$PID_FILE" \
  --web-browser-flag=--disable-cache \
  --web-browser-flag=--disable-application-cache \
  --dart-define=API_BASE_URL=http://localhost:3001 &

FLUTTER_PROC=$!

cleanup() {
  if kill -0 "$FLUTTER_PROC" 2>/dev/null; then
    kill "$FLUTTER_PROC" 2>/dev/null || true
  fi
  rm -f "$PID_FILE"
}
trap cleanup EXIT INT TERM

last_hash=""

echo "Watcher ativo: qualquer alteração em lib/web/pubspec vai disparar hot reload."

while kill -0 "$FLUTTER_PROC" 2>/dev/null; do
  current_hash=$( {
    find "$PROJECT_ROOT/lib" -type f -name "*.dart" 2>/dev/null
    find "$PROJECT_ROOT/web" -type f \( -name "*.html" -o -name "*.js" -o -name "*.css" \) 2>/dev/null
    [ -f "$PROJECT_ROOT/pubspec.yaml" ] && echo "$PROJECT_ROOT/pubspec.yaml"
  } | sort | xargs stat -f "%m %N" 2>/dev/null | shasum | awk '{print $1}' )

  if [[ -n "$last_hash" && "$current_hash" != "$last_hash" ]]; then
    if [[ -f "$PID_FILE" ]]; then
      target_pid=$(cat "$PID_FILE" 2>/dev/null || true)
      if [[ -n "$target_pid" ]]; then
        kill -USR1 "$target_pid" 2>/dev/null || true
        echo "[watch] Alteracao detectada -> hot reload enviado"
      fi
    fi
  fi

  last_hash="$current_hash"
  sleep 1

done

wait "$FLUTTER_PROC"
