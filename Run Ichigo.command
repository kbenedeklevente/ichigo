#!/usr/bin/env bash
set -euo pipefail
ICHIGO_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ $# -eq 0 ]]; then
  exec "$ICHIGO_PROJECT_DIR/scripts/run_game.sh" -- --weather-study
fi
exec "$ICHIGO_PROJECT_DIR/scripts/run_game.sh" "$@"
