#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
README_FILE="$ROOT_DIR/README.md"

[[ -f "$README_FILE" ]]

grep -q '^# codex-autoresearch$' "$README_FILE"
grep -q 'setup-autoresearch' "$README_FILE"
grep -q 'program.md' "$README_FILE"
grep -q 'codex-autoresearch.sh' "$README_FILE"
grep -q -- '--full-permission' "$README_FILE"
grep -q -- '--session-id' "$README_FILE"
grep -q 'MONITOR_LINES' "$README_FILE"
grep -q 'read program.md and begin autoresearch' "$README_FILE"
