#!/usr/bin/env bash
# Loads the .env file (if present) and starts the Node server.
# Referenced by the systemd unit as the ExecStart target.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f ".env" ]; then
  # export all vars defined in .env
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

exec node src/server.js
