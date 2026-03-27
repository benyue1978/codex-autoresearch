#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_BIN_DIR="$TMP_DIR/bin"
FAKE_LOG="$TMP_DIR/fake-codex.log"
SLEEP_LOG="$TMP_DIR/sleep.log"
STATE_DIR="$TMP_DIR/state"
PROMPT_FILE="$TMP_DIR/prompt.md"
CALLS_FILE="$TMP_DIR/calls.txt"
STDERR_LOG="$TMP_DIR/stderr.log"
SESSION_ID="11111111-2222-3333-4444-555555555555"

mkdir -p "$FAKE_BIN_DIR" "$STATE_DIR"
printf 'read program.md and begin autoresearch\n' > "$PROMPT_FILE"

cat > "$FAKE_BIN_DIR/codex" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

log_file=${FAKE_CODEX_LOG:?}
calls_file=${FAKE_CODEX_CALLS:?}
printf '%s\n' "$*" >> "$log_file"

call_count=0
if [[ -f "$calls_file" ]]; then
  call_count=$(cat "$calls_file")
fi
call_count=$((call_count + 1))
printf '%s' "$call_count" > "$calls_file"

output_file=
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  if [[ "${args[$i]}" == "-o" ]]; then
    output_file="${args[$((i + 1))]}"
    break
  fi
done

prompt_payload=${args[$((${#args[@]} - 1))]}
completion_token=$(printf '%s' "$prompt_payload" | awk -F'`' '/token `/ { print $2 }')
confirm_text=$(printf '%s' "$prompt_payload" | awk -F'`' '/line 2 = `/ { print $4 }')

if [[ "$call_count" == "1" ]]; then
  : > "$output_file"
  printf '%s\n' '{"type":"error","message":"You'\''ve hit your usage limit. Visit https://chatgpt.com/codex/settings/usage for more details."}'
  exit 1
fi

printf '%s\n%s\n' "$completion_token" "$confirm_text" > "$output_file"
printf '{"session_id":"%s"}\n' "${TEST_SESSION_ID:?}"
EOF

cat > "$FAKE_BIN_DIR/sleep" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s\n' "$*" >> "${FAKE_SLEEP_LOG:?}"
EOF

chmod +x "$FAKE_BIN_DIR/codex" "$FAKE_BIN_DIR/sleep"

PATH="$FAKE_BIN_DIR:$PATH" \
FAKE_CODEX_LOG="$FAKE_LOG" \
FAKE_CODEX_CALLS="$CALLS_FILE" \
FAKE_SLEEP_LOG="$SLEEP_LOG" \
TEST_SESSION_ID="$SESSION_ID" \
STATE_DIR="$STATE_DIR" \
CODEX_BIN=codex \
RATE_LIMIT_RETRY_DELAY=42 \
bash "$ROOT_DIR/codex-autoresearch.sh" "$PROMPT_FILE" 2>"$STDERR_LOG"

grep -q '^42$' "$SLEEP_LOG"
grep -q 'detected Codex usage limit without reset time; sleeping 42s before retry' "$STDERR_LOG"
