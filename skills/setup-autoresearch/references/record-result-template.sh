#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: scripts/record-result.sh <results_tsv> <ts> <experiment_id> <commit> <parent_commit> <status> <measure> <baseline_measure> <summary> <artifact_path>
#
# Required inputs:
# - results_tsv: path to the append-only results ledger
# - remaining arguments: fields for one experiment record
#
# Expected behavior:
# - create the TSV with a header if it does not exist
# - Append exactly one tab-separated row
# - support statuses such as keep, discard, and crash
#
# Exit codes:
# - 0: row appended successfully
# - non-zero: row could not be recorded

results_tsv=${1:?missing results_tsv}
shift

echo "TODO: append one TSV row to ${results_tsv}" >&2
exit 1
