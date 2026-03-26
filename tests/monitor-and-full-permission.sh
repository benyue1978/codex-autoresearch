#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_BIN_DIR="$TMP_DIR/bin"
FAKE_LOG="$TMP_DIR/fake-codex.log"
STATE_DIR="$TMP_DIR/state"
STDERR_LOG="$TMP_DIR/stderr.log"
CALLS_FILE="$TMP_DIR/calls.txt"
PROMPT_FILE="$TMP_DIR/prompt.md"
SESSION_ID="11111111-2222-3333-4444-555555555555"

mkdir -p "$FAKE_BIN_DIR" "$STATE_DIR"
printf 'Investigate and continue.\n' > "$PROMPT_FILE"

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
  cat > "$output_file" <<'MSG'
alpha
beta
gamma
delta
epsilon
MSG
else
  printf '%s\n%s\n' "$completion_token" "$confirm_text" > "$output_file"
fi

printf '{"session_id":"%s"}\n' "${TEST_SESSION_ID:?}"
EOF

chmod +x "$FAKE_BIN_DIR/codex"

PATH="$FAKE_BIN_DIR:$PATH" \
FAKE_CODEX_LOG="$FAKE_LOG" \
FAKE_CODEX_CALLS="$CALLS_FILE" \
TEST_SESSION_ID="$SESSION_ID" \
STATE_DIR="$STATE_DIR" \
CODEX_BIN=codex \
INTERVAL=0 \
bash "$ROOT_DIR/codex-autoresearch.sh" --full-permission "$PROMPT_FILE" 2>"$STDERR_LOG"

grep -q -- '--dangerously-bypass-approvals-and-sandbox' "$FAKE_LOG"
grep -q 'codex says (last 3 lines):' "$STDERR_LOG"
grep -q 'gamma' "$STDERR_LOG"
grep -q 'delta' "$STDERR_LOG"
grep -q 'epsilon' "$STDERR_LOG"
grep -qE '^exec --json ' "$FAKE_LOG"

if grep -q -- '--full-auto' "$FAKE_LOG"; then
  echo "did not expect --full-auto when --full-permission is set" >&2
  exit 1
fi
