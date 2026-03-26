---
name: setup-autoresearch
description: Use when preparing autoresearch for a new repository, especially to inspect the repo, infer the operating constraints, ask only high-risk follow-up questions, and generate `program.md`
---

# Setup Autoresearch

Use this skill to generate a repo-specific `program.md` for the current repository.

The reference model is the original [`karpathy/autoresearch`](https://github.com/karpathy/autoresearch): keep the control surface simple, keep the measurement harness fixed, and make the human-authored `program.md` the main operating prompt.

## Goal

Produce only one artifact:

- `program.md`

Generate `program.md` only as output for the target repository.
Do not create supporting docs for repo-specific rules unless the user explicitly asks for them.

## Repo-First Workflow

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

1. inspect the repo and identify the fixed setup, fixed measure, and smallest safe editable surface
2. run any required setup
3. establish a baseline result
4. make one small change
5. run the required verification checks
6. run the experiment and obtain the authoritative measure
7. compare the candidate against the current kept baseline
8. if the measure improved or stayed the same with simpler logic, commit the change to git
9. otherwise discard the change from git
10. repeat with one experiment at a time

The keep/discard operation must be explicit. Refer to git directly. Do not leave the operator guessing whether "keep" means commit, stash, or merely note the result.

## Confirmation Gate

The generated `program.md` must instruct the operator to stop before starting autoresearch and ask the user whether to start autoresearch immediately or not.

That confirmation step must:

- explain the inferred setup in a short summary
- ask the user whether to start autoresearch immediately
- offer the alternative of using `codex-autoresearch.sh`
- include a prompt like `read program.md and begin autoresearch`
- happen before any setup, experiment, keep, or discard action begins

## Output Discipline

- Write `program.md` only after repo inspection and any necessary follow-up questions.
- Keep it concise and operational.
- Prefer explicit commands and file paths over abstract guidance.
- Keep the editable surface as small as the repo allows.
