#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: scripts/start-experiment.sh <experiment_id> <candidate_commit>
#
# Required inputs:
# - experiment_id: stable identifier for this candidate attempt
# - candidate_commit: the git commit that should be measured
#
# Expected behavior:
# - verify the worktree is clean
# - verify HEAD is at <candidate_commit>
# - run the authoritative experiment command for the repo
# - write artifacts to a stable location
# - Print the artifact path to stdout
#
# Exit codes:
# - 0: experiment started and completed successfully
# - non-zero: experiment failed or the environment was not valid

experiment_id=${1:?missing experiment_id}
candidate_commit=${2:?missing candidate_commit}

echo "TODO: run the authoritative experiment for ${experiment_id} at commit ${candidate_commit}" >&2
echo "TODO: print artifact path to stdout" >&2
exit 1
