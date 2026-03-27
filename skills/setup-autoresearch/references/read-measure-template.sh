#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: scripts/read-measure.sh <artifact_path>
#
# Required inputs:
# - artifact_path: canonical artifact emitted by the authoritative experiment
#
# Expected behavior:
# - read the authoritative measure from the canonical artifact
# - Print exactly one TSV-safe line to stdout
# - the printed line should contain the measure value only, or a minimal machine-readable record
#
# Exit codes:
# - 0: measure was read successfully
# - non-zero: measure could not be read reliably

artifact_path=${1:?missing artifact_path}

echo "TODO: read authoritative measure from ${artifact_path}" >&2
exit 1
