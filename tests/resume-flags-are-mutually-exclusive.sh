#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

set +e
bash "$ROOT_DIR/codex-autoresearch.sh" --session-id 11111111-2222-3333-4444-555555555555 --last >"$TMP_DIR/stdout.log" 2>"$TMP_DIR/stderr.log"
exit_code=$?
set -e

if [[ "$exit_code" == "0" ]]; then
  echo "expected failure when both --session-id and --last are provided" >&2
  exit 1
fi

grep -q 'Use either --session-id or --last, not both.' "$TMP_DIR/stderr.log"
