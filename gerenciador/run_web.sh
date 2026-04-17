#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_ROOT"
flutter run \
  -d chrome \
  --web-hostname=localhost \
  --web-port=3000 \
  --web-browser-debug-port=9222 \
  --host-vmservice-port=8181 \
  --pid-file=.flutter.pid \
  --web-browser-flag=--disable-cache \
  --web-browser-flag=--disable-application-cache \
  --dart-define=API_BASE_URL=http://localhost:3001
