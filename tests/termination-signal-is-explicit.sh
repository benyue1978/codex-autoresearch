#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_BIN_DIR="$TMP_DIR/bin"
FAKE_LOG="$TMP_DIR/fake-codex.log"
STATE_DIR="$TMP_DIR/state"
STDERR_LOG="$TMP_DIR/stderr.log"
PROMPT_FILE="$TMP_DIR/prompt.md"
PID_FILE="$TMP_DIR/script.pid"

mkdir -p "$FAKE_BIN_DIR" "$STATE_DIR"
printf 'Keep working.\n' > "$PROMPT_FILE"

cat > "$FAKE_BIN_DIR/codex" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

log_file=${FAKE_CODEX_LOG:?}
printf '%s\n' "$*" >> "$log_file"

output_file=
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  if [[ "${args[$i]}" == "-o" ]]; then
    output_file="${args[$((i + 1))]}"
    break
  fi
done

cat > "$output_file" <<'MSG'
still running
MSG

sleep 30
EOF

chmod +x "$FAKE_BIN_DIR/codex"

set +e
(
  PATH="$FAKE_BIN_DIR:$PATH" \
  FAKE_CODEX_LOG="$FAKE_LOG" \
  STATE_DIR="$STATE_DIR" \
  CODEX_BIN=codex \
  INTERVAL=0 \
  bash "$ROOT_DIR/codex-autoresearch.sh" "$PROMPT_FILE" 2>"$STDERR_LOG"
) &
script_pid=$!
printf '%s\n' "$script_pid" > "$PID_FILE"

sleep 1
kill -TERM "$script_pid"
wait "$script_pid"
exit_code=$?
set -e

if [[ "$exit_code" != "143" ]]; then
  echo "expected exit code 143 after SIGTERM, got $exit_code" >&2
  exit 1
fi

grep -q 'received SIGTERM; shutting down supervisor' "$STDERR_LOG"
