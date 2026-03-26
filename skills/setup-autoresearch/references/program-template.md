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

## Setup

1. Prepare the environment and any required data.
2. Verify the repository is in a usable state.
3. Record the baseline commands and files you will rely on during the loop.

## Baseline

1. Run the baseline workflow.
2. Obtain the baseline measure from the authoritative source.
3. Treat that result as the current kept baseline until a better or simpler equivalent candidate is proven.

## Experiment Loop

1. Make one small change.
2. Run the required verification checks.
3. Run the experiment.
4. Obtain the authoritative measure.
5. Compare the candidate against the current kept baseline.
6. if the measure improved or stayed the same with simpler logic, commit the change to git.
7. otherwise discard the change from git.
8. Record the result in the repo-specific log or ledger.
9. Repeat one experiment at a time.

## Boundaries

- Prefer editing only the smallest safe model or experiment surface.
- Do not modify fixed infrastructure unless blocked by a real bug.
- Do not change the authoritative measure.
- Keep the workflow reproducible and reversible.
- Equal measure with simpler behavior is a valid keep.

## Output Style

- Be concise and operational.
- Use explicit commands and file paths.
- Prefer `measure`, `result`, or `evaluation signal` over `score` unless the repository itself uses `score`.
