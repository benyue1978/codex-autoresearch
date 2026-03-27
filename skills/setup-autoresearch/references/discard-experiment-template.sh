#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: scripts/discard-experiment.sh <kept_commit>
#
# Required inputs:
# - kept_commit: the previously kept baseline commit
#
# Expected behavior:
# - Reset git back to the previously kept commit
# - leave the worktree clean
#
# Exit codes:
# - 0: discard action succeeded
# - non-zero: discard action failed

kept_commit=${1:?missing kept_commit}

echo "TODO: discard candidate and reset to ${kept_commit}" >&2
exit 1
