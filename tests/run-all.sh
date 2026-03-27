#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

bash tests/setup-autoresearch-template.sh
bash tests/full-auto-flag.sh
bash tests/last-flag-resume.sh
bash tests/prompt-and-resume-are-mutually-exclusive.sh
bash tests/resume-flags-are-mutually-exclusive.sh
bash tests/prompt-mode-ignores-stale-session-id.sh
bash tests/stale-state-does-not-force-resume.sh
bash tests/rate-limit-reset-backoff.sh
bash tests/rate-limit-fallback-backoff.sh
bash tests/monitor-and-full-permission.sh
bash tests/resume-with-session-id.sh
bash tests/termination-signal-is-explicit.sh
bash tests/readme.sh
