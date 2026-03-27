# codex-autoresearch

This repo contains two end-user tools for running repo-specific autoresearch with Codex:

- `skills/setup-autoresearch/SKILL.md`: a skill that inspects a target repo, asks only high-risk follow-up questions, generates a repo-specific `program.md`, and scaffolds a minimal autoresearch harness when the repo lacks one
- `codex-autoresearch.sh`: a shell supervisor that keeps Codex working on the same autoresearch task unattended

The design follows the original [karpathy/autoresearch](https://github.com/karpathy/autoresearch) idea: the human defines the research operating rules in `program.md`, and the agent iterates within those rules.

The shell supervisor in this repo was also inspired by [congwa/codex-autoresearch](https://github.com/congwa/codex-autoresearch), which provided the original shell-script direction for wrapping long-running Codex sessions.

## What To Use When

Use `setup-autoresearch` when you are in a target repository and need to create the first `program.md`, and possibly the minimal harness scripts and TSV ledger that autoresearch needs.

Use `codex-autoresearch.sh` either to start a new autoresearch session from a prompt, or to keep resuming an existing session with minimal supervision.

## Using The Skill

The skill is meant to be available to Codex in the target repository. Once available, ask Codex to use `setup-autoresearch`.

Example request:

```text
Use the setup-autoresearch skill to inspect this repository and generate program.md.
```

What the skill is expected to do:

1. inspect the current repo and infer as much as possible
2. identify the setup, baseline command, authoritative measure, editable surface, and verification gates
3. ask follow-up questions only when a wrong assumption would be costly
4. decide whether the repo already has a usable autoresearch harness or needs a minimal scaffold
5. after confirmation, generate `program.md` and only the missing harness pieces, such as thin scripts and a TSV ledger
6. stop and ask whether you want to start immediately or use the shell runner

The generated `program.md` should make the keep/discard rule explicit:

- create a candidate git commit before the authoritative experiment runs
- record every attempted experiment in the result ledger, including `keep`, `discard`, and `crash`
- if the measure improves, keep the experiment commit as the new baseline
- if the measure stays the same with simpler logic, keep the experiment commit as the new baseline
- otherwise discard it by resetting git back to the previously kept baseline

When the skill finishes, one valid next prompt is:

```text
read program.md and begin autoresearch
```

## Using The Shell

`codex-autoresearch.sh` is a long-running supervisor around `codex exec`.

It does four important things:

1. starts with `codex exec` when given a prompt source, then continues with `codex exec resume`
2. stores the latest Codex message and session metadata in a state directory
3. prints the last few lines from Codex after each unfinished attempt so you can monitor progress live
4. stops only when Codex returns the expected completion token and confirmation line

If the supervisor is terminated externally with signals like `SIGTERM`, `SIGINT`, or `SIGHUP`, it now logs the signal explicitly before exiting instead of leaving you with only a generic `Terminated`.

If Codex exits because a usage limit is exhausted, the supervisor now detects that from recent Codex stderr, backs off instead of blindly retrying, and sleeps until the parsed reset time when one is available. If no reset time can be extracted, it falls back to a longer retry delay.

### Start A New Session

To start a new autoresearch session, pass a prompt source. For example:

```bash
WORKDIR=/path/to/target-repo bash /path/to/codex-autoresearch.sh ./prompt.md
```

If you prefer stdin:

```bash
printf 'read program.md and begin autoresearch\n' | WORKDIR=/path/to/target-repo bash /path/to/codex-autoresearch.sh -
```

Typical prompt content:

```text
read program.md and begin autoresearch
```

### Resume An Existing Session

If you already know the Codex session id:

```bash
WORKDIR=/path/to/target-repo bash /path/to/codex-autoresearch.sh --session-id 11111111-2222-3333-4444-555555555555
```

### Resume The Last Session Explicitly

If you want the wrapper to target the last Codex session in the working directory, say so explicitly:

```bash
WORKDIR=/path/to/target-repo bash /path/to/codex-autoresearch.sh --last
```

Resume target selection is explicit. For resume mode, provide either `--session-id` or `--last`.

### Full Auto Mode

If you want native Codex `--full-auto` behavior, use:

```bash
WORKDIR=/path/to/target-repo bash /path/to/codex-autoresearch.sh --full-auto ./prompt.md
```

### Full Permission Mode

If you want Codex to run without human approval prompts, use:

```bash
WORKDIR=/path/to/target-repo bash /path/to/codex-autoresearch.sh --full-permission ./prompt.md
```

This passes `--dangerously-bypass-approvals-and-sandbox` to Codex. Use it only when you are comfortable giving Codex unrestricted execution for that run.

`--full-auto` and `--full-permission` are mutually exclusive.

## Useful Environment Variables

- `WORKDIR`: target repository where Codex should run
- `STATE_DIR`: directory for saved session state, logs, prompts, and last-message snapshots
- `INTERVAL`: sleep time between unfinished attempts, default `3`
- `MODEL`: optional Codex model override
- `PROFILE`: optional Codex profile
- `MONITOR_LINES`: how many trailing lines from the latest Codex message to print after each unfinished attempt, default `3`
- `EXECUTION_MODE`: optional fallback mode when no CLI flag is provided, one of `normal`, `full-auto`, or `full-permission`
- `USE_FULL_AUTO`: whether to pass `--full-auto` by default, `1` unless overridden
- `DANGEROUSLY_BYPASS`: legacy fallback for full-permission mode
- `SKIP_GIT_REPO_CHECK`: whether to pass `--skip-git-repo-check`

## State Files

The shell writes state under `STATE_DIR` or a temporary directory if none is provided.

Useful files include:

- `events.jsonl`: raw Codex JSON output
- `runner.log`: stderr from Codex invocations
- `last-message.txt`: latest assistant message
- `attempt-####.last.txt`: per-attempt snapshots of the last message
- `session-id.txt`: captured Codex session id
- `initial-prompt.txt` and `resume-prompt.txt`: exact prompts sent by the supervisor

## Typical Workflow

1. open the target repository in Codex
2. use `setup-autoresearch` to generate `program.md`
3. review the inferred setup and confirmation question
4. start the autoresearch task with `codex-autoresearch.sh ./prompt.md`
5. if needed later, resume it with `codex-autoresearch.sh --session-id <uuid>` or `codex-autoresearch.sh --last`
6. monitor the live 3-line Codex preview while the run continues
7. if Codex reports a usage limit, the supervisor should back off using the reset time from `events.jsonl` when available, or a longer fallback delay otherwise

## Tests

This repo currently includes shell tests for the setup skill contract and the supervisor behavior:

```bash
bash tests/run-all.sh
```

The runner currently executes:

```bash
bash tests/setup-autoresearch-template.sh
bash tests/full-auto-flag.sh
bash tests/last-flag-resume.sh
bash tests/prompt-and-resume-are-mutually-exclusive.sh
bash tests/resume-flags-are-mutually-exclusive.sh
bash tests/prompt-mode-ignores-stale-session-id.sh
bash tests/stale-state-does-not-force-resume.sh
bash tests/rate-limit-reset-backoff.sh
bash tests/rate-limit-fallback-backoff.sh
bash tests/monitor-and-full-permission.sh
bash tests/resume-with-session-id.sh
bash tests/termination-signal-is-explicit.sh
bash tests/readme.sh
```
