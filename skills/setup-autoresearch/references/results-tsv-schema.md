# Results TSV Schema

Use this schema when generating or validating the autoresearch results ledger.

The ledger should be append-only and should record all attempted experiments, including
`keep`, `discard`, and `crash`.

Required columns:

- `ts`
- `experiment_id`
- `commit`
- `parent_commit`
- `status`
- `measure`
- `baseline_measure`
- `summary`
- `artifact_path`

Column guidance:

- `ts`: timestamp for when the result row was recorded
- `experiment_id`: stable id for the candidate attempt
- `commit`: candidate git commit that was measured
- `parent_commit`: previously kept baseline commit before the candidate was evaluated
- `status`: one of `keep`, `discard`, or `crash`
- `measure`: authoritative result for the candidate
- `baseline_measure`: authoritative result for the kept baseline used for comparison
- `summary`: short TSV-safe description of the change or outcome
- `artifact_path`: canonical artifact path used to read the authoritative measure
