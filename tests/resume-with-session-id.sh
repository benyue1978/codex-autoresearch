#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_BIN_DIR="$TMP_DIR/bin"
FAKE_LOG="$TMP_DIR/fake-codex.log"
STATE_DIR="$TMP_DIR/state"
SESSION_ID="11111111-2222-3333-4444-555555555555"

mkdir -p "$FAKE_BIN_DIR" "$STATE_DIR"

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

prompt_payload=${args[$((${#args[@]} - 1))]}
nonce=$(printf '%s' "$prompt_payload" | grep -oE 'nonce `[0-9a-f-]{14}`' | grep -oE '[0-9a-f-]{14}')
confirm_text=$(printf '%s' "$prompt_payload" | awk -F'`' '/line 2 = `/ { print $4 }')

IFS='-' read -r a b c <<< "$nonce"
printf '%s\n%s\n' "$c-$b-$a" "$confirm_text" > "$output_file"

printf '{"session_id":"%s"}\n' "${TEST_SESSION_ID:?}"
EOF

chmod +x "$FAKE_BIN_DIR/codex"

PATH="$FAKE_BIN_DIR:$PATH" \
FAKE_CODEX_LOG="$FAKE_LOG" \
TEST_SESSION_ID="$SESSION_ID" \
STATE_DIR="$STATE_DIR" \
CODEX_BIN=codex \
bash "$ROOT_DIR/codex-autoresearch.sh" --session-id "$SESSION_ID"

grep -q 'exec resume' "$FAKE_LOG"
grep -q "$SESSION_ID" "$FAKE_LOG"

if grep -qE '^exec --json' "$FAKE_LOG"; then
  echo "expected resume mode only, but initial exec was invoked" >&2
  exit 1
fi
