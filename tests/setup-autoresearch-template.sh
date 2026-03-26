#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

SKILL_FILE="$ROOT_DIR/skills/setup-autoresearch/SKILL.md"
REFERENCE_FILE="$ROOT_DIR/skills/setup-autoresearch/references/program-template.md"

[[ -f "$SKILL_FILE" ]]
[[ -f "$REFERENCE_FILE" ]]

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
grep -q 'confirm the inferred setup with the user before finalizing `program.md`' "$SKILL_FILE"
grep -q 'codex-autoresearch.sh' "$SKILL_FILE"
grep -q 'if the measure improved or stayed the same with simpler logic, commit the change to git' "$SKILL_FILE"
grep -q 'otherwise discard the change from git' "$SKILL_FILE"
grep -q 'Generate `program.md` only as output for the target repository' "$SKILL_FILE"
grep -q 'begin autoresearch immediately' "$SKILL_FILE"
grep -q 'continue autonomously' "$SKILL_FILE"
grep -q 'This skill combines two patterns:' "$SKILL_FILE"
grep -q 'Inversion: inspect first' "$SKILL_FILE"
grep -q 'Generator: produce one structured artifact' "$SKILL_FILE"
grep -q 'See `references/program-template.md` for a generic reference template' "$SKILL_FILE"

grep -q '^# program.md Template$' "$REFERENCE_FILE"
grep -q 'begin autoresearch immediately' "$REFERENCE_FILE"
grep -q 'continue autonomously until blocked' "$REFERENCE_FILE"
grep -q 'if the measure improved or stayed the same with simpler logic, commit the change to git' "$REFERENCE_FILE"
grep -q 'otherwise discard the change from git' "$REFERENCE_FILE"
