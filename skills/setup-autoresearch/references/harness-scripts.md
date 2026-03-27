# Harness Script Reference

Use this reference when generating a repo-specific `program.md` for repositories that
either already have an experiment harness or should be guided toward one.

The goal is not to force these exact filenames. The goal is to make the generated
`program.md` explicit about when git actions happen, how the authoritative measure is
collected, and how the result ledger is updated.

This reference should be used together with the script templates and TSV schema. The
runtime contract needs required inputs, stdout contract, and exit codes, not only role names.

## Recommended Script Roles

Prefer telling the agent to use repo-local scripts if they already exist. If they do
not exist yet, the generated `program.md` can still refer to equivalent commands under
these roles.

- `scripts/start-experiment.sh`
  - assumes the candidate change is already committed
  - records the candidate commit id
  - runs the authoritative experiment command
  - writes artifacts to a stable location

- `scripts/read-measure.sh`
  - reads the authoritative measure from the canonical artifact
  - prints only the measure or a small machine-readable record

- `scripts/record-result.sh`
  - appends one row to a TSV ledger such as `autoresearch/results.tsv`
  - should support statuses such as `keep`, `discard`, and `crash`
  - should record at least timestamp, experiment id, commit id, status, and measure

- `scripts/keep-experiment.sh`
  - marks the already-created experiment commit as the new kept baseline
  - may update a baseline pointer, branch, or note if the repo uses one

- `scripts/discard-experiment.sh`
  - resets git back to the previously kept commit or known baseline
  - must leave the worktree clean

Each runtime script should define:

- required positional inputs
- what it prints to stdout
- what it prints to stderr
- which exit code means success versus failure

## Recommended Timing

The generated `program.md` should be explicit about this order:

1. start from a clean kept baseline
2. make one small change
3. create a candidate git commit
4. run verification
5. run the authoritative experiment
6. read the authoritative measure
7. append one TSV row for this experiment
8. decide `keep` or `discard`
9. if `discard`, reset git back to the previous kept baseline

This follows the original `karpathy/autoresearch` pattern more closely than keeping
changes uncommitted until after the result is known.

## Result Ledger Guidance

Prefer a TSV ledger because it is simple to append and easy to inspect.

Useful columns include:

- `ts`
- `experiment_id`
- `commit`
- `parent_commit`
- `status`
- `measure`
- `baseline_measure`
- `summary`
- `artifact_path`

The important design point is that the ledger records all attempted experiments, not only kept ones. This means discarded or crashed runs still leave an audit trail even
though their commits do not remain on the main kept line.
