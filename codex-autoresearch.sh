#!/usr/bin/env bash
set -Eeuo pipefail

# Long-running Codex supervisor script.
# - Designed for unattended execution where Codex should keep advancing the same task.
# - Uses `codex exec` when starting from a prompt source and `codex exec resume`
#   when explicitly resuming an existing session, so progress stays anchored to a
#   real Codex conversation instead of inferred from terminal output.
# - Completion is detected through a per-run completion token rather than natural-language
#   summaries, which reduces false positives when the model says something that merely
#   sounds like "done".
# - Resume targets are explicit: either a concrete session id or an explicit `--last`.
#   Fresh prompt-based starts do not reuse stale stored session ids.

CODEX_BIN=${CODEX_BIN:-codex}
WORKDIR=${WORKDIR:-$(pwd)}
STATE_DIR=${STATE_DIR:-}
INTERVAL=${INTERVAL:-3}
CONFIRM_TEXT=${CONFIRM_TEXT:-"CONFIRMED: all tasks completed"}
RESUME_TEXT_BASE=${RESUME_TEXT_BASE:-"You must respond to this message. Continue any unfinished user-requested work immediately from the current state. Do not restart. Do not summarize. Do not ask for confirmation. If all requested work is already complete, follow the completion protocol below."}
MODEL=${MODEL:-}
PROFILE=${PROFILE:-}
USE_FULL_AUTO=${USE_FULL_AUTO:-1}
DANGEROUSLY_BYPASS=${DANGEROUSLY_BYPASS:-0}
SKIP_GIT_REPO_CHECK=${SKIP_GIT_REPO_CHECK:-0}
START_WITH_RESUME_IF_POSSIBLE=${START_WITH_RESUME_IF_POSSIBLE:-1}
MONITOR_LINES=${MONITOR_LINES:-3}
EXECUTION_MODE=${EXECUTION_MODE:-}

CODEX_SESSION_ID=${CODEX_SESSION_ID:-}
COMPLETION_TOKEN=
EVENT_LOG_FILE=
RUN_LOG_FILE=
LAST_MESSAGE_FILE=
SESSION_ID_FILE=
META_FILE=
RESUME_PROMPT_FILE=
CURRENT_CHILD_PID=
RESUME_WITH_LAST=0
PROMPT_SOURCE=

# Expose a stable CLI so the script can be called from cron, tmux, or another supervisor.
usage() {
  printf 'Usage: %s <prompt_file | ->\n' "${0##*/}" >&2
  printf 'Usage: %s --session-id <uuid>\n' "${0##*/}" >&2
  printf 'Usage: %s --last\n' "${0##*/}" >&2
  printf 'Usage: %s --full-auto <prompt_file | ->\n' "${0##*/}" >&2
  printf 'Usage: %s --full-permission <prompt_file | ->\n' "${0##*/}" >&2
  printf 'Example: %s ./prompt.md\n' "${0##*/}" >&2
  printf 'Example: %s --last\n' "${0##*/}" >&2
  printf 'Example: %s --full-auto ./prompt.md\n' "${0##*/}" >&2
  printf 'Example: %s --full-permission --session-id 11111111-2222-3333-4444-555555555555\n' "${0##*/}" >&2
  printf 'Example: %s --session-id 11111111-2222-3333-4444-555555555555\n' "${0##*/}" >&2
  printf 'Env: WORKDIR=. INTERVAL=3 STATE_DIR=/tmp/codex-run MODEL=gpt-5 USE_FULL_AUTO=1 MONITOR_LINES=3\n' >&2
  printf 'Note: start mode uses a prompt source; resume mode requires either `--session-id` or `--last`.\n' >&2
  exit 1
}

# The CLI supports two explicit modes:
# - start a new task from a prompt source
# - resume an existing task from a known session id or `--last`
parse_args() {
  local saw_full_auto=0
  local saw_full_permission=0
  local use_last=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --session-id)
        [[ $# -ge 2 ]] || die "Missing value for --session-id"
        CODEX_SESSION_ID=$2
        shift 2
        ;;
      --last)
        use_last=1
        RESUME_WITH_LAST=1
        shift
        ;;
      --full-auto)
        saw_full_auto=1
        shift
        ;;
      --full-permission)
        saw_full_permission=1
        shift
        ;;
      -h|--help)
        usage
        ;;
      --*)
        die "Unknown option: $1"
        ;;
      *)
        [[ -z "$PROMPT_SOURCE" ]] || die "Only one prompt source is supported."
        PROMPT_SOURCE=$1
        shift
        ;;
    esac
  done

  if [[ -n "$PROMPT_SOURCE" && ( -n "$CODEX_SESSION_ID" || "$use_last" == "1" ) ]]; then
    die "Use either a prompt source or a resume target, not both."
  fi

  if [[ -z "$PROMPT_SOURCE" && -z "$CODEX_SESSION_ID" && "$use_last" != "1" ]]; then
    die "resume target must be explicit: use --session-id <uuid> or --last"
  fi

  if [[ -n "$CODEX_SESSION_ID" && "$use_last" == "1" ]]; then
    die "Use either --session-id or --last, not both."
  fi

  if (( saw_full_auto == 1 && saw_full_permission == 1 )); then
    die "Use at most one of --full-auto or --full-permission."
  fi

  if (( saw_full_permission == 1 )); then
    EXECUTION_MODE=full-permission
  elif (( saw_full_auto == 1 )); then
    EXECUTION_MODE=full-auto
  elif [[ -n "$EXECUTION_MODE" ]]; then
    case "$EXECUTION_MODE" in
      normal|full-auto|full-permission) ;;
      *)
        die "EXECUTION_MODE must be one of: normal, full-auto, full-permission"
        ;;
    esac
  elif [[ "$DANGEROUSLY_BYPASS" == "1" ]]; then
    EXECUTION_MODE=full-permission
  elif [[ "$USE_FULL_AUTO" == "1" ]]; then
    EXECUTION_MODE=full-auto
  else
    EXECUTION_MODE=normal
  fi
}

# Runner logs are written to stderr so they stay visible to an operator and do not
# contaminate the structured files produced by Codex itself.
log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >&2
}

# Fatal failures go through one path so the operator can immediately see why the
# supervisor stopped instead of silently failing mid-loop.
die() {
  log "ERROR: $*"
  exit 1
}

handle_sigterm() {
  log "received SIGTERM; shutting down supervisor"
  if [[ -n "$CURRENT_CHILD_PID" ]]; then
    kill -TERM "$CURRENT_CHILD_PID" 2>/dev/null || true
    wait "$CURRENT_CHILD_PID" 2>/dev/null || true
  fi
  exit 143
}

handle_sigint() {
  log "received SIGINT; shutting down supervisor"
  if [[ -n "$CURRENT_CHILD_PID" ]]; then
    kill -TERM "$CURRENT_CHILD_PID" 2>/dev/null || true
    wait "$CURRENT_CHILD_PID" 2>/dev/null || true
  fi
  exit 130
}

handle_sighup() {
  log "received SIGHUP; shutting down supervisor"
  if [[ -n "$CURRENT_CHILD_PID" ]]; then
    kill -TERM "$CURRENT_CHILD_PID" 2>/dev/null || true
    wait "$CURRENT_CHILD_PID" 2>/dev/null || true
  fi
  exit 129
}

# Keep command-existence checks centralized instead of scattering startup validation
# through the main control flow.
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# The state directory stores JSON events, the latest assistant message, and metadata
# for the completion protocol. This makes long runs easier to inspect and resume.
prepare_state_dir() {
  if [[ -n "$STATE_DIR" ]]; then
    mkdir -p "$STATE_DIR"
  else
    STATE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/codex-run.XXXXXX")
  fi

  EVENT_LOG_FILE="$STATE_DIR/events.jsonl"
  RUN_LOG_FILE="$STATE_DIR/runner.log"
  LAST_MESSAGE_FILE="$STATE_DIR/last-message.txt"
  SESSION_ID_FILE="$STATE_DIR/session-id.txt"
  META_FILE="$STATE_DIR/meta.env"
  RESUME_PROMPT_FILE="$STATE_DIR/resume-prompt.txt"
}

# If the supervisor itself restarts, prefer resuming a previously created Codex
# session so the same task is not accidentally split across multiple new sessions.
load_previous_session_state() {
  local saved_session_id

  [[ "$START_WITH_RESUME_IF_POSSIBLE" == "1" ]] || return 0
  [[ -z "$PROMPT_SOURCE" ]] || return 0
  [[ "$RESUME_WITH_LAST" != "1" ]] || return 0

  if [[ -n "$CODEX_SESSION_ID" ]]; then
    return 0
  fi

  if [[ -f "$SESSION_ID_FILE" ]]; then
    saved_session_id=$(sed -n '1p' "$SESSION_ID_FILE" | tr -d '\r')
    if [[ -n "$saved_session_id" ]]; then
      CODEX_SESSION_ID="$saved_session_id"
    fi
  fi

}

# Generate a fresh completion token for this supervisor run. The token is random so
# completion detection does not accidentally match stale output or ordinary prose.
generate_completion_token() {
  local raw_token

  raw_token=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')
  COMPLETION_TOKEN="COMPLETE-${raw_token}"
}

# Both initial and resume prompts must reuse the same completion protocol so every
# attempt has the same contract for what "finished" means.
completion_protocol_text() {
  printf 'When using the completion protocol, reply with EXACTLY two lines and nothing else: line 1 = token `%s`; line 2 = `%s`.' "$COMPLETION_TOKEN" "$CONFIRM_TEXT"
}

# The first prompt preserves the user's actual task while appending the completion
# protocol required by this supervisor.
build_initial_prompt() {
  local base_prompt=$1

  printf '%s\n\n%s\n' "$base_prompt" "$(completion_protocol_text)"
}

# Resume prompts are intentionally narrow: either keep working from the current state
# or use the completion protocol. They do not replay the entire original task.
build_resume_prompt() {
  printf '%s %s\n' "$RESUME_TEXT_BASE" "$(completion_protocol_text)"
}

# Completion is determined from the latest assistant message only. That is more
# precise than scanning the whole event log and accidentally matching an earlier turn.
completion_detected() {
  local line1 line2 line3

  [[ -f "$LAST_MESSAGE_FILE" ]] || return 1
  line1=$(sed -n '1p' "$LAST_MESSAGE_FILE" | tr -d '\r')
  line2=$(sed -n '2p' "$LAST_MESSAGE_FILE" | tr -d '\r')
  line3=$(sed -n '3p' "$LAST_MESSAGE_FILE" | tr -d '\r')

  [[ "$line1" == "$COMPLETION_TOKEN" && "$line2" == "$CONFIRM_TEXT" && -z "$line3" ]]
}

# Save a per-attempt snapshot of the latest assistant message so operators can inspect
# what Codex said at each stage of a long unattended run.
snapshot_last_message() {
  local attempt=$1
  local snapshot_file

  [[ -f "$LAST_MESSAGE_FILE" ]] || return 0
  snapshot_file=$(printf '%s/attempt-%04d.last.txt' "$STATE_DIR" "$attempt")
  cp "$LAST_MESSAGE_FILE" "$snapshot_file"
}

# Print the last few lines of the latest assistant message after each unfinished
# attempt so an operator can monitor progress in real time.
print_last_message_preview() {
  local line_count=${MONITOR_LINES:-3}

  [[ -f "$LAST_MESSAGE_FILE" ]] || return 0
  [[ "$line_count" =~ ^[0-9]+$ ]] || line_count=3
  (( line_count > 0 )) || return 0

  log "codex says (last ${line_count} lines):"
  tail -n "$line_count" "$LAST_MESSAGE_FILE" | while IFS= read -r line; do
    printf '[%s]   %s\n' "$(date '+%F %T')" "$line" >&2
  done
}

# If Codex emits a session id in its JSON events, persist it so future resumes can
# target the exact same session instead of relying on `--last`.
maybe_record_session_id() {
  local discovered_session_id

  [[ -n "$CODEX_SESSION_ID" ]] && return 0
  [[ -f "$EVENT_LOG_FILE" ]] || return 0

  discovered_session_id=$(
    grep -Eo '"(session_id|conversation_id|thread_id)"[[:space:]]*:[[:space:]]*"[0-9a-fA-F-]{36}"' "$EVENT_LOG_FILE" \
      | tail -n 1 \
      | grep -Eo '[0-9a-fA-F-]{36}' \
      || true
  )

  if [[ -n "$discovered_session_id" ]]; then
    CODEX_SESSION_ID="$discovered_session_id"
    printf '%s\n' "$CODEX_SESSION_ID" > "$SESSION_ID_FILE"
    log "bound session id: $CODEX_SESSION_ID"
  fi
}

# Persist the key runtime metadata so a restarted supervisor or a human operator can
# quickly see which workdir and completion token this run belongs to.
write_state_metadata() {
  {
    printf 'WORKDIR=%q\n' "$WORKDIR"
    printf 'STATE_DIR=%q\n' "$STATE_DIR"
    printf 'COMPLETION_TOKEN=%q\n' "$COMPLETION_TOKEN"
    printf 'CONFIRM_TEXT=%q\n' "$CONFIRM_TEXT"
  } > "$META_FILE"
}

append_common_exec_args() {
  local -n cmd_ref=$1

  case "$EXECUTION_MODE" in
    full-permission)
      cmd_ref+=("--dangerously-bypass-approvals-and-sandbox")
      ;;
    full-auto)
      cmd_ref+=("--full-auto")
      ;;
  esac

  if [[ "$SKIP_GIT_REPO_CHECK" == "1" ]]; then
    cmd_ref+=("--skip-git-repo-check")
  fi

  if [[ -n "$MODEL" ]]; then
    cmd_ref+=("-m" "$MODEL")
  fi

  if [[ -n "$PROFILE" ]]; then
    cmd_ref+=("--profile" "$PROFILE")
  fi
}

run_logged_command() {
  local workdir=$1
  shift
  local exit_code

  if [[ -n "$workdir" ]]; then
    (
      cd "$workdir"
      "$@"
    ) >>"$EVENT_LOG_FILE" 2>>"$RUN_LOG_FILE" &
  else
    "$@" >>"$EVENT_LOG_FILE" 2>>"$RUN_LOG_FILE" &
  fi

  CURRENT_CHILD_PID=$!
  wait "$CURRENT_CHILD_PID"
  exit_code=$?
  CURRENT_CHILD_PID=
  return "$exit_code"
}

# Initial tasks normally come from a prompt file or stdin. That keeps the handoff
# from external tooling deterministic and makes the original prompt easy to audit.
read_initial_prompt() {
  local prompt_source=$1
  local prompt_text

  if [[ "$prompt_source" == "-" ]]; then
    [[ -t 0 ]] && die "Prompt source is '-', but stdin is empty."
    prompt_text=$(cat)
  else
    [[ -f "$prompt_source" ]] || die "Prompt file does not exist: $prompt_source"
    prompt_text=$(cat "$prompt_source")
  fi

  [[ -n "$prompt_text" ]] || die "Initial prompt is empty."
  printf '%s' "$prompt_text"
}

# The first run creates a new Codex session, so this is where workdir selection,
# execution mode, and structured output paths are attached to the command.
run_initial_exec() {
  local prompt_payload=$1
  local exit_code
  local cmd=("$CODEX_BIN" "exec" "--json" "-o" "$LAST_MESSAGE_FILE")

  append_common_exec_args cmd
  cmd+=("-C" "$WORKDIR" "$prompt_payload")

  log "starting initial codex exec"
  if run_logged_command "" "${cmd[@]}"; then
    return 0
  else
    exit_code=$?
  fi

  log "initial codex exec exited with code=$exit_code"
  return "$exit_code"
}

# Resume sends only a compact "continue" message so Codex keeps working within the
# same session context instead of starting a fresh task from scratch.
run_resume_exec() {
  local prompt_payload=$1
  local exit_code
  local cmd=("$CODEX_BIN" "exec" "resume" "--json" "-o" "$LAST_MESSAGE_FILE")

  append_common_exec_args cmd
  if [[ -n "$CODEX_SESSION_ID" ]]; then
    cmd+=("$CODEX_SESSION_ID")
  else
    cmd+=("--last")
  fi
  cmd+=("$prompt_payload")

  if [[ -n "$CODEX_SESSION_ID" ]]; then
    log "resuming codex session id=$CODEX_SESSION_ID"
  else
    log "resuming codex with --last in workdir=$WORKDIR"
  fi

  if run_logged_command "$WORKDIR" "${cmd[@]}"; then
    return 0
  else
    exit_code=$?
  fi

  log "codex resume exited with code=$exit_code"
  return "$exit_code"
}

# The main loop has one job: unless completion is proven, keep pulling Codex back
# into the same task so it can continue making progress.
main() {
  local initial_prompt
  local initial_prompt_payload
  local resume_prompt_payload
  local attempt=0
  local exit_code=0

  parse_args "$@"
  trap handle_sigterm TERM
  trap handle_sigint INT
  trap handle_sighup HUP
  command_exists "$CODEX_BIN" || die "Codex binary not found: $CODEX_BIN"
  [[ -d "$WORKDIR" ]] || die "WORKDIR does not exist: $WORKDIR"
  WORKDIR=$(cd "$WORKDIR" && pwd)

  prepare_state_dir
  load_previous_session_state
  if [[ -n "$PROMPT_SOURCE" ]]; then
    CODEX_SESSION_ID=
    rm -f "$SESSION_ID_FILE"
  elif [[ "$RESUME_WITH_LAST" == "1" ]]; then
    CODEX_SESSION_ID=
  fi
  generate_completion_token
  write_state_metadata

  if [[ -n "$CODEX_SESSION_ID" ]]; then
    printf '%s\n' "$CODEX_SESSION_ID" > "$SESSION_ID_FILE"
  fi

  resume_prompt_payload=$(build_resume_prompt)
  printf '%s\n' "$resume_prompt_payload" > "$RESUME_PROMPT_FILE"

  if [[ -n "$PROMPT_SOURCE" ]]; then
    initial_prompt=$(read_initial_prompt "$PROMPT_SOURCE")
    initial_prompt_payload=$(build_initial_prompt "$initial_prompt")
  fi

  log "state directory: $STATE_DIR"
  log "workdir: $WORKDIR"
  log "completion token: $COMPLETION_TOKEN"
  if [[ "$EXECUTION_MODE" == "full-permission" ]]; then
    log "execution mode: full permission without approval prompts"
  elif [[ "$EXECUTION_MODE" == "full-auto" ]]; then
    log "execution mode: full auto"
  else
    log "execution mode: interactive approvals may be required"
  fi

  while true; do
    attempt=$((attempt + 1))

    if (( attempt == 1 )) && [[ -n "$PROMPT_SOURCE" ]]; then
      if run_initial_exec "$initial_prompt_payload"; then
        exit_code=0
      else
        exit_code=$?
      fi
    else
      if run_resume_exec "$resume_prompt_payload"; then
        exit_code=0
      else
        exit_code=$?
      fi
    fi

    snapshot_last_message "$attempt"
    maybe_record_session_id

    if completion_detected; then
      log "completion protocol detected; stopping supervisor"
      exit 0
    fi

    print_last_message_preview
    log "attempt=$attempt finished with code=$exit_code without completion protocol; sleeping ${INTERVAL}s"
    sleep "$INTERVAL"
  done
}

main "$@"
