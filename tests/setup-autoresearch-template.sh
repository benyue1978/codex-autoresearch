#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

SKILL_FILE="$ROOT_DIR/skills/setup-autoresearch/SKILL.md"
REFERENCE_FILE="$ROOT_DIR/skills/setup-autoresearch/references/program-template.md"
HARNESS_REFERENCE_FILE="$ROOT_DIR/skills/setup-autoresearch/references/harness-scripts.md"
START_TEMPLATE_FILE="$ROOT_DIR/skills/setup-autoresearch/references/start-experiment-template.sh"
READ_TEMPLATE_FILE="$ROOT_DIR/skills/setup-autoresearch/references/read-measure-template.sh"
RECORD_TEMPLATE_FILE="$ROOT_DIR/skills/setup-autoresearch/references/record-result-template.sh"
KEEP_TEMPLATE_FILE="$ROOT_DIR/skills/setup-autoresearch/references/keep-experiment-template.sh"
DISCARD_TEMPLATE_FILE="$ROOT_DIR/skills/setup-autoresearch/references/discard-experiment-template.sh"
TSV_SCHEMA_FILE="$ROOT_DIR/skills/setup-autoresearch/references/results-tsv-schema.md"

[[ -f "$SKILL_FILE" ]]
[[ -f "$REFERENCE_FILE" ]]
[[ -f "$HARNESS_REFERENCE_FILE" ]]
[[ -f "$START_TEMPLATE_FILE" ]]
[[ -f "$READ_TEMPLATE_FILE" ]]
[[ -f "$RECORD_TEMPLATE_FILE" ]]
[[ -f "$KEEP_TEMPLATE_FILE" ]]
[[ -f "$DISCARD_TEMPLATE_FILE" ]]
[[ -f "$TSV_SCHEMA_FILE" ]]

if [[ -e "$ROOT_DIR/program.md" ]]; then
  echo "checked-in program.md should be removed" >&2
  exit 1
fi

if [[ -e "$ROOT_DIR/skills/repo-autoresearch-churn/SKILL.md" ]]; then
  echo "repo-specific skill should be removed" >&2
  exit 1
fi

if [[ -e "$ROOT_DIR/docs/autoresearch-rule.md" ]]; then
  echo "repo-specific autoresearch doc should be removed" >&2
  exit 1
fi

if [[ -e "$ROOT_DIR/docs/eda-best-practices.md" ]]; then
  echo "repo-specific EDA doc should be removed" >&2
  exit 1
fi

grep -q '^name: setup-autoresearch$' "$SKILL_FILE"
grep -q 'inspect the current repo and infer as much as possible' "$SKILL_FILE"
grep -q 'ask follow-up questions only when a wrong assumption would be costly' "$SKILL_FILE"
grep -q 'Do not use the term `score`' "$SKILL_FILE"
grep -q 'confirm the inferred setup and any proposed scaffold files with the user before writing them' "$SKILL_FILE"
grep -q 'codex-autoresearch.sh' "$SKILL_FILE"
grep -q 'create an experiment commit before running the authoritative experiment' "$SKILL_FILE"
grep -q 'append the experiment result to the repo'\''s result ledger, preferably a TSV' "$SKILL_FILE"
grep -q 'keep the experiment commit' "$SKILL_FILE"
grep -q 'discard it by resetting git back to the previously kept commit or known baseline' "$SKILL_FILE"
grep -q 'record the experiment in the result ledger whether it is later kept, discarded, or crashes' "$SKILL_FILE"
grep -q 'Always generate `program.md` as output for the target repository' "$SKILL_FILE"
grep -q 'the minimum supporting scripts and TSV ledger needed to run the loop reliably' "$SKILL_FILE"
grep -q 'Only generate harness scripts or a TSV ledger when the repo lacks an equivalent mechanism' "$SKILL_FILE"
grep -q 'begin autoresearch immediately' "$SKILL_FILE"
grep -q 'continue autonomously' "$SKILL_FILE"
grep -q 'This skill combines two patterns:' "$SKILL_FILE"
grep -q 'Inversion: inspect first' "$SKILL_FILE"
grep -q 'Generator: produce one structured setup package' "$SKILL_FILE"
grep -q 'See `references/program-template.md` for a generic reference template' "$SKILL_FILE"
grep -q 'See `references/harness-scripts.md` for a generic reference pattern' "$SKILL_FILE"
grep -q 'See `references/results-tsv-schema.md` for the ledger contract' "$SKILL_FILE"
grep -q 'See the script templates in `references/` for concrete scaffold contracts' "$SKILL_FILE"

grep -q '^# program.md Template$' "$REFERENCE_FILE"
grep -q 'begin autoresearch immediately' "$REFERENCE_FILE"
grep -q 'continue autonomously until blocked' "$REFERENCE_FILE"
grep -q 'If the repo already provides harness scripts for experiments, measurement, result logging, and keep/discard actions, use them as the default control surface' "$REFERENCE_FILE"
grep -q 'Create an experiment commit before running the authoritative experiment' "$REFERENCE_FILE"
grep -q 'including the candidate commit id and a status such as `keep`, `discard`, or `crash`' "$REFERENCE_FILE"
grep -q 'discard it by resetting git back to the previously kept commit or known baseline' "$REFERENCE_FILE"
! grep -q 'which setup files were generated' "$REFERENCE_FILE"
! grep -q 'setup-autoresearch' "$REFERENCE_FILE"

grep -q '^# Harness Script Reference$' "$HARNESS_REFERENCE_FILE"
grep -q 'scripts/start-experiment.sh' "$HARNESS_REFERENCE_FILE"
grep -q 'scripts/read-measure.sh' "$HARNESS_REFERENCE_FILE"
grep -q 'scripts/record-result.sh' "$HARNESS_REFERENCE_FILE"
grep -q 'scripts/keep-experiment.sh' "$HARNESS_REFERENCE_FILE"
grep -q 'scripts/discard-experiment.sh' "$HARNESS_REFERENCE_FILE"
grep -q 'the ledger records all attempted experiments, not only kept ones' "$HARNESS_REFERENCE_FILE"
grep -q 'required inputs, stdout contract, and exit codes' "$HARNESS_REFERENCE_FILE"

grep -q '^#!/usr/bin/env bash$' "$START_TEMPLATE_FILE"
grep -q 'Usage: scripts/start-experiment.sh <experiment_id> <candidate_commit>' "$START_TEMPLATE_FILE"
grep -q 'Print the artifact path to stdout' "$START_TEMPLATE_FILE"

grep -q '^#!/usr/bin/env bash$' "$READ_TEMPLATE_FILE"
grep -q 'Usage: scripts/read-measure.sh <artifact_path>' "$READ_TEMPLATE_FILE"
grep -q 'Print exactly one TSV-safe line to stdout' "$READ_TEMPLATE_FILE"

grep -q '^#!/usr/bin/env bash$' "$RECORD_TEMPLATE_FILE"
grep -q 'Usage: scripts/record-result.sh <results_tsv> <ts> <experiment_id> <commit> <parent_commit> <status> <measure> <baseline_measure> <summary> <artifact_path>' "$RECORD_TEMPLATE_FILE"
grep -q 'Append exactly one tab-separated row' "$RECORD_TEMPLATE_FILE"

grep -q '^#!/usr/bin/env bash$' "$KEEP_TEMPLATE_FILE"
grep -q 'Usage: scripts/keep-experiment.sh <candidate_commit>' "$KEEP_TEMPLATE_FILE"
grep -q 'Leave git at the kept commit' "$KEEP_TEMPLATE_FILE"

grep -q '^#!/usr/bin/env bash$' "$DISCARD_TEMPLATE_FILE"
grep -q 'Usage: scripts/discard-experiment.sh <kept_commit>' "$DISCARD_TEMPLATE_FILE"
grep -q 'Reset git back to the previously kept commit' "$DISCARD_TEMPLATE_FILE"

grep -q '^# Results TSV Schema$' "$TSV_SCHEMA_FILE"
grep -q '`ts`' "$TSV_SCHEMA_FILE"
grep -q '`experiment_id`' "$TSV_SCHEMA_FILE"
grep -q '`commit`' "$TSV_SCHEMA_FILE"
grep -q '`parent_commit`' "$TSV_SCHEMA_FILE"
grep -q '`status`' "$TSV_SCHEMA_FILE"
grep -q '`measure`' "$TSV_SCHEMA_FILE"
grep -q '`baseline_measure`' "$TSV_SCHEMA_FILE"
grep -q '`summary`' "$TSV_SCHEMA_FILE"
grep -q '`artifact_path`' "$TSV_SCHEMA_FILE"
