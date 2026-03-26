#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

PROMPT_FILE="$TMP_DIR/prompt.md"
printf 'read program.md and begin autoresearch\n' > "$PROMPT_FILE"

set +e
bash "$ROOT_DIR/codex-autoresearch.sh" --session-id 11111111-2222-3333-4444-555555555555 "$PROMPT_FILE" >"$TMP_DIR/stdout.log" 2>"$TMP_DIR/stderr.log"
exit_code=$?
set -e

if [[ "$exit_code" == "0" ]]; then
  echo "expected failure when prompt source and resume target are both provided" >&2
  exit 1
fi

grep -q 'Use either a prompt source or a resume target, not both.' "$TMP_DIR/stderr.log"
