---
name: setup-autoresearch
description: Use when entering a new repository and needing a repo-specific autoresearch `program.md`, especially when the setup, measure, editable surface, or keep/discard contract must be inferred from the repo and clarified with only minimal high-risk questions
---

# Setup Autoresearch

Use this skill to generate a repo-specific `program.md` for the current repository.

The reference model is the original [`karpathy/autoresearch`](https://github.com/karpathy/autoresearch): keep the control surface simple, keep the measurement harness fixed, and make the human-authored `program.md` the main operating prompt.

## Goal

Produce only one artifact:

- `program.md`

Generate `program.md` only as output for the target repository.
Do not create supporting docs for repo-specific rules unless the user explicitly asks for them.

The `setup-autoresearch` step itself remains interactive. It should inspect the repo,
ask the human only the necessary high-risk follow-up questions, and confirm the
generated operating assumptions before finalizing `program.md`.

This skill combines two patterns:

- Inversion: inspect first, then ask the human only the minimum high-risk questions
- Generator: produce one structured artifact, `program.md`, from the confirmed inputs

See `references/program-template.md` for a generic reference template modeled after
the original `karpathy/autoresearch` `program.md`, but generalized for arbitrary repos.

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

Keep the questioning short and focused. Ask only what is needed to safely generate `program.md`.

## Language Rules

- Do not use the term `score` in your own framing.
- Prefer `measure`, `result`, `evaluation signal`, or `authoritative result`.
- If the repository itself uses `score`, you may quote that repo term when identifying a file, field, or command.

## Generation

After the repo inspection and human confirmation steps are complete, generate exactly
one artifact: `program.md`.

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

## Autoresearch Flow

The generated `program.md` should make the loop concrete and operational:

1. begin autoresearch immediately
2. inspect the repo and identify the fixed setup, fixed measure, and smallest safe editable surface
3. run any required setup
4. establish a baseline result
5. make one small change
6. run the required verification checks
7. run the experiment and obtain the authoritative measure
8. compare the candidate against the current kept baseline
9. if the measure improved or stayed the same with simpler logic, commit the change to git
10. otherwise discard the change from git
11. continue autonomously until blocked by a real missing prerequisite, external dependency, or human decision that cannot be inferred safely

The keep/discard operation must be explicit. Refer to git directly. Do not leave the operator guessing whether "keep" means commit, stash, or merely note the result.

## Setup Confirmation

The interaction and confirmation happen during `setup-autoresearch`, not inside the generated `program.md`.

That setup step must:

- explain the inferred setup in a short summary
- confirm the inferred setup with the user before finalizing `program.md`
- offer the alternative of using `codex-autoresearch.sh`
- include a prompt like `read program.md and begin autoresearch`

The generated `program.md` should not stop to ask for confirmation before starting the loop. It should instruct the operator clearly to begin autoresearch immediately and continue autonomously.

## Output Discipline

- Write `program.md` only after repo inspection and any necessary follow-up questions.
- Keep it concise and operational.
- Prefer explicit commands and file paths over abstract guidance.
- Keep the editable surface as small as the repo allows.
