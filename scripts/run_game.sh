#!/usr/bin/env bash
set -euo pipefail

ICHIGO_PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ICHIGO_ENGINE="${ICHIGO_GODOT:-}"
if [[ -z "$ICHIGO_ENGINE" ]]; then
  for candidate in "/Applications/Godot.app/Contents/MacOS/Godot" "$ICHIGO_PROJECT_DIR/work/runtime/Godot.app/Contents/MacOS/Godot"; do
    if [[ -x "$candidate" ]]; then
      ICHIGO_ENGINE="$candidate"
      break
    fi
  done
fi
if [[ -z "$ICHIGO_ENGINE" ]]; then
  ICHIGO_ENGINE="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$ICHIGO_ENGINE" || ! -x "$ICHIGO_ENGINE" ]]; then
  printf '%s\n' 'Godot 4.7.2 is required. Install it from https://godotengine.org/download/macos/ or set ICHIGO_GODOT to its executable.' >&2
  exit 1
fi

exec "$ICHIGO_ENGINE" --path "$ICHIGO_PROJECT_DIR" "$@"
