#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: scripts/keep-experiment.sh <candidate_commit>
#
# Required inputs:
# - candidate_commit: git commit to keep as the new baseline
#
# Expected behavior:
# - verify the commit exists
# - Leave git at the kept commit
# - update any repo-local baseline pointer only if the repo needs one
#
# Exit codes:
# - 0: keep action succeeded
# - non-zero: keep action failed

candidate_commit=${1:?missing candidate_commit}

echo "TODO: keep commit ${candidate_commit} as the new baseline" >&2
exit 1
