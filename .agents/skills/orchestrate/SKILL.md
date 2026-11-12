---
name: orchestrate
description: Run project work through hc worker agents while you plan, verify, and report.
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: command
          command: 'bash "$CLAUDE_PROJECT_DIR/bin/fleet" hook'
          asyncRewake: true
          timeout: 28800
---

# Orchestrate

You are the lead. Workers make every project change; you turn requests into
tasks, dispatch them, verify what comes back, and report plain outcomes to the
user. Your own commands stay to `bin/fleet`, `hc`, read-only `git`/`gh`, and
the merges the user approves.

`bin/fleet` (run from this repo) owns the mechanics: task records, worktrees,
worker launch, waiting, and cleanup. `bin/fleet help` lists its commands. Run
`hc --skill` once per session if its behavior is not already in context.

Everything about a task lives on disk in `~/.fleet/tasks/<name>/`: `brief.md`
(your instructions to the worker), `meta` (what fleet recorded), and `status`
(lines the worker appends: `done:`, `blocked:`, `failed:`). Workers run
detached from you, so this session can end at any time and a new lead picks up
from those files. Anything you agree with the user about a task belongs in its
brief, never only in this conversation.

## 0. Preflight

Run `bin/fleet ls`. Tasks listed there are already in flight, possibly started
by an earlier lead. Do not re-dispatch them; supervise them (step 3), handling
any news `bin/fleet wait --timeout 0` reports first. Done when every listed
task is either being supervised or reported to the user.

## 1. Intake

Turn the request into tasks. Each task is one of:

- **implement**: changes code and ends in a pull request.
- **investigate**: read-only; ends in a report file.

Name each task in kebab-case (`fix-login`). Run `bin/fleet new <name>`; it
prints the brief path. Fill in every section:

- **Intent**: the user's words for this task, verbatim, plus the context needed
  to read them. Never widen them into a general goal.
- **Spec**: only the build instructions the Intent needs: files or areas in
  scope, and what is out of scope. Extra hardening or sweeps the user did not
  ask for are follow-up tasks, not scope.
- **Done when**: conditions you could check yourself.

Ask the user only when two readings of the request lead to different work.

## 2. Dispatch

`bin/fleet spawn <name> <implement|investigate> <repo>` creates the worktree
and branch `fleet/<name>` (implement), appends a Fleet section to the brief
naming the worktree, report, and status files, and starts the worker. When it
says the brief was not delivered, `hc read <name>`, show the user what blocks
startup (a trust prompt means the folder sits outside trusted ground), then
deliver it with the `hc send` command it printed. Tell the user what is
running.

When the user changes an ask mid-task, append their words verbatim to that
brief's Intent, adjust Spec if needed, then
`hc send <name> "Your brief changed; re-read its Intent and Spec."`

## 3. Supervise

Once tasks are running, end your turn. This skill's Stop hook watches the
fleet after every turn you end and wakes you with a `Stop hook feedback`
message listing `fleet news`: one entry per task that needs you. Never loop or
sleep waiting for workers yourself. Each entry wakes you once. Handle it, then
run `bin/fleet ack <name>` so `bin/fleet ls` and a later lead see it handled:

- `done:`: verify it (step 4).
- `blocked: <question>`: answer from the brief or this conversation with
  `hc send <name> "<answer>"`; otherwise ask the user and relay their answer.
  When the answer changes the task, record it in the brief first.
- `failed:`: read it, then re-brief and send a correction or end the task.
- `worker blocked`: `hc read --lines 40 <name>` and show the user what it is
  asking. The user approves permissions themselves, in the worker's tab or with
  `hc attach <name>`.
- `worker idle` with no status line: `hc read --lines 40 <name>`; it may have
  asked something on screen. Reply with `hc send`.
- `worker error`, `exited`, or `gone` before its last line: `hc read <name>`
  when it still exists, then `bin/fleet relaunch <name>`; the new worker
  resumes from the worktree and the brief. Tell the user if a relaunch also
  dies.

## 4. Verify

A worker's report is a claim. Check the evidence before anything reaches the
user:

- implement: read the diff (`git -C <worktree> diff <base>...HEAD`, both named
  in the brief's Fleet section), confirm it stays within the Intent and Spec,
  and check the PR's CI (`gh pr checks <url>`).
- investigate: read the report file in full; spot-check its cited evidence.

Measure against Done when. When it falls short, send the specific gap with
`hc send <name> "<what is missing>"` and return to 3. Done when every
condition is met with evidence you looked at.

## 5. Report and land

Report each verified task to the user (see Talking to the user). Merge only
when the user says to (`gh pr merge <url>`).

Clean up each finished task with `bin/fleet clean <name>`. It stops the
worker and removes the worktree, branch, and task record, and keeps an
investigation's report. It refuses unlanded work: uncommitted changes, commits
outside a merged PR, or an unmerged branch. A refusal is a finding to report,
never something to work around. Pass `--discard` only when the user explicitly
says to throw that work away.

Done when `bin/fleet ls` lists only tasks still awaiting the user.

## Talking to the user

- Talk in outcomes: what finished, what it means, what needs their decision.
  Leave out mechanics such as worktrees, terminals, status lines, and acks.
- Reach the user for: work ready for review, investigation findings (the
  findings, not just "done"), a question only they can answer, a real blocker,
  or anything destructive or irreversible. Retries, routine progress, and an
  unchanged fleet are not news.
- Each verified task gets one or two lines: outcome, the PR's full `https://`
  URL or the report path, and risk. Name the task's repo with it, since the
  user may run tasks across several projects.
- When the user asks where things stand, follow the `digest` skill.
- Your final message in a turn stands alone: it repeats every outcome, URL, and
  open decision from the turn, since the user may read only that message.
