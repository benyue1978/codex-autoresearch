# program.md Template

Use this as a generic reference template when generating a repo-specific `program.md`.

Replace the placeholders with concrete repo-specific commands, files, measures, and constraints inferred from the target repository.

## Role

begin autoresearch immediately and continue autonomously until blocked by a real missing prerequisite, external dependency, or human decision that cannot be inferred safely.

## First Read

Inspect the repository before making any changes. Identify:

- the setup commands
- the baseline command
- the authoritative measure and where it comes from
- the smallest safe editable surface
- the fixed infrastructure that should remain stable
- the required verification steps
- any experiment log or result ledger
- any existing harness scripts that should be reused

## Setup

1. Prepare the environment and any required data.
2. Verify the repository is in a usable state.
3. Record the baseline commands and files you will rely on during the loop.
4. If the repo already provides harness scripts for experiments, measurement, result logging, and keep/discard actions, use them as the default control surface.

## Baseline

1. Run the baseline workflow.
2. Obtain the baseline measure from the authoritative source.
3. Treat that result as the current kept baseline until a better or simpler equivalent candidate is proven.
4. Identify the result ledger location, preferably a TSV, and the preferred harness scripts for experiment execution, measurement, and keep/discard operations.
5. If the repo already had equivalent harness scripts, prefer them over newly invented shell sequences.

## Experiment Loop

1. Make one small change.
2. Create an experiment commit before running the authoritative experiment.
3. Run the required verification checks.
4. Run the experiment, preferably through a repo-local harness script.
5. Obtain the authoritative measure from the canonical artifact, preferably through a repo-local harness script.
6. Record the result in the repo-specific ledger, preferably a TSV, including the candidate commit id and a status such as `keep`, `discard`, or `crash`.
7. Compare the candidate against the current kept baseline.
8. If the measure improved or stayed the same with simpler logic, keep the experiment commit as the new baseline.
9. Otherwise discard it by resetting git back to the previously kept commit or known baseline.
10. Repeat one experiment at a time.

## Harness Contract

- If the repo provides harness scripts, use them as the default control surface.
- If no equivalent scripts exist, use the scaffolded scripts that match these roles:
  - `scripts/start-experiment.sh`
  - `scripts/read-measure.sh`
  - `scripts/record-result.sh`
  - `scripts/keep-experiment.sh`
  - `scripts/discard-experiment.sh`
- Expect each script to have explicit required inputs, stdout contract, and exit codes.
- Expect the results ledger to contain at least the columns defined in the TSV schema.

## Boundaries

- Prefer editing only the smallest safe model or experiment surface.
- Do not modify fixed infrastructure unless blocked by a real bug.
- Do not change the authoritative measure.
- Keep the workflow reproducible and reversible.
- Equal measure with simpler behavior is a valid keep.
- Prefer harness scripts over ad hoc shell fragments when the repo provides them.
- The result ledger should record discarded and crashed experiments too, not only kept ones.

## Output Style

- Be concise and operational.
- Use explicit commands and file paths.
- Prefer `measure`, `result`, or `evaluation signal` over `score` unless the repository itself uses `score`.
