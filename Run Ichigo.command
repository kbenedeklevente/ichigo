#!/usr/bin/env bash
set -euo pipefail
ICHIGO_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$ICHIGO_PROJECT_DIR/scripts/run_game.sh" "$@"
