---
name: setup-autoresearch
description: Use when entering a new repository and needing repo-specific autoresearch setup, especially when the setup, measure, editable surface, keep/discard contract, or minimal harness must be inferred from the repo and clarified with only minimal high-risk questions
---

# Setup Autoresearch

Use this skill to set up repo-specific autoresearch for the current repository.

The reference model is the original [`karpathy/autoresearch`](https://github.com/karpathy/autoresearch): keep the control surface simple, keep the measurement harness fixed, and make the human-authored `program.md` the main operating prompt.

## Goal

Produce:

- `program.md`
- and, when the repository lacks a usable autoresearch harness, the minimum supporting scripts and TSV ledger needed to run the loop reliably

Always generate `program.md` as output for the target repository.
Create supporting scripts or a TSV ledger only when they are missing and the repo does not already provide an equivalent harness.
Do not create extra repo-specific docs unless the user explicitly asks for them.

The `setup-autoresearch` step itself remains interactive. It should inspect the repo,
ask the human only the necessary high-risk follow-up questions, and confirm the
generated operating assumptions and any proposed scaffold files before writing them.

This skill combines two patterns:

- Inversion: inspect first, then ask the human only the minimum high-risk questions
- Generator: produce one structured setup package from the confirmed inputs, always centered on `program.md`

See `references/program-template.md` for a generic reference template modeled after
the original `karpathy/autoresearch` `program.md`, but generalized for arbitrary repos.
See `references/harness-scripts.md` for a generic reference pattern for runtime harness roles.
See `references/results-tsv-schema.md` for the ledger contract.
See the script templates in `references/` for concrete scaffold contracts.

## Input Gathering

Inspect the current repo and infer as much as possible before asking the user anything.
In other words: inspect the current repo and infer as much as possible.

Read the files that most likely reveal the workflow:

- `README*`
- `pyproject.toml`, `package.json`, `Makefile`, `justfile`, `requirements*.txt`, `environment.yml`
- CLI entrypoints and task runners
- test files and CI configs
- existing training, evaluation, benchmark, or submission scripts
- the current `program.md` if it exists

From the repo, infer:

- setup commands
- baseline run command
- authoritative measure source
- allowed edit surface
- fixed infrastructure that should remain stable
- required verification commands
- experiment logging location, if one is obvious
- whether the repo already has harness scripts for experiment start, measurement, git keep/discard, or result logging
- whether a result ledger already exists, preferably TSV
- which missing pieces must be scaffolded so the loop can run reproducibly

## Follow-Up Questions

Ask follow-up questions only when a wrong assumption would be costly.
Put plainly: ask follow-up questions only when a wrong assumption would be costly.

Good reasons to ask:

- multiple plausible authoritative measures exist
- the repo has several possible run commands and no clear baseline
- the editable surface is risky or broad
- the keep/discard rule is ambiguous
- external services or credentials are required and the repo does not define the contract

Bad reasons to ask:

- information is already inferable from the repo
- low-impact preferences that do not change the loop design
- curiosity

Keep the questioning short and focused. Ask only what is needed to safely generate `program.md` and any missing harness pieces.

## Language Rules

- Do not use the term `score` in your own framing.
- Prefer `measure`, `result`, `evaluation signal`, or `authoritative result`.
- If the repository itself uses `score`, you may quote that repo term when identifying a file, field, or command.

## Generation

After the repo inspection and human confirmation steps are complete, generate:

- `program.md`
- and only the missing harness pieces needed for the repo to execute the autoresearch loop reliably

## What `program.md` Must Contain

The generated `program.md` should explain the overall autoresearch flow and be specific to the current repository.

It must cover:

1. what to inspect first
2. how to set up the environment and data, if needed
3. how to establish the baseline
4. what the authoritative measure is and where it comes from
5. what files are preferred for editing
6. what files should stay fixed unless blocked by a real bug
7. the one-experiment-at-a-time keep/discard loop
8. required tests or verification gates
9. any repo-specific logging or result ledger
10. the simplicity bias
11. preferred harness scripts, if the repo already has them or should add them
12. the result ledger path, preferably TSV

## Autoresearch Flow

The generated `program.md` should make the loop concrete and operational:

1. begin autoresearch immediately
2. inspect the repo and identify the fixed setup, fixed measure, and smallest safe editable surface
3. run any required setup
4. establish a baseline result
5. make one small change
6. create an experiment commit before running the authoritative experiment
7. run the required verification checks
8. run the experiment and obtain the authoritative measure
9. append the experiment result to the repo's result ledger, preferably a TSV, including at least experiment id, commit id, measure, and status
10. compare the candidate against the current kept baseline
11. if the measure improved or stayed the same with simpler logic, keep the experiment commit
12. otherwise discard it by resetting git back to the previously kept commit or known baseline
13. continue autonomously until blocked by a real missing prerequisite, external dependency, or human decision that cannot be inferred safely

The keep/discard operation must be explicit and upstream-style:

- create a git commit for the candidate before the authoritative experiment runs
- record the experiment in the result ledger whether it is later kept, discarded, or crashes
- keep means preserving that experiment commit as the new baseline
- discard means resetting git back to the previously kept state, not leaving a dirty worktree

Do not leave the operator guessing whether "keep" means commit, stash, or merely note the result.

## Harness Preference

When the repository already has suitable harness scripts, the generated `program.md` should direct the agent to use them instead of open-coded ad hoc shell sequences.

When the repository does not yet have a good harness, `setup-autoresearch` should propose and then generate the thinnest possible scaffold for:

- starting one experiment from the current committed candidate
- obtaining the authoritative measure from the canonical artifact
- appending one row to the result ledger, preferably TSV
- keeping the current experiment commit as the new baseline
- discarding the current experiment commit by resetting to the prior kept state

Prefer reusing existing repo commands and artifacts. The scaffold should wrap the repo's established workflow, not invent a new training or evaluation pipeline.

## Setup Confirmation

The interaction and confirmation happen during `setup-autoresearch`, not inside the generated `program.md`.

That setup step must:

- explain the inferred setup in a short summary
- explain whether the repo already has a usable harness or needs scaffold files
- confirm the inferred setup and any proposed scaffold files with the user before writing them
- offer the alternative of using `codex-autoresearch.sh`
- include a prompt like `read program.md and begin autoresearch`

The generated `program.md` should not stop to ask for confirmation before starting the loop. It should instruct the operator clearly to begin autoresearch immediately and continue autonomously.

## Output Discipline

- Write `program.md` only after repo inspection and any necessary follow-up questions.
- Only generate harness scripts or a TSV ledger when the repo lacks an equivalent mechanism.
- Keep it concise and operational.
- Prefer explicit commands and file paths over abstract guidance.
- Keep the editable surface as small as the repo allows.
