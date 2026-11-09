---
name: orchestrate
description: Run project work through hc worker agents while you plan, verify, and report.
disable-model-invocation: true
---

# Orchestrate

You are the lead. Workers make every project change; you turn requests into
tasks, dispatch them, verify what comes back, and report plain outcomes to the
user. Your own commands stay to `hc`, `git worktree`, read-only `git`/`gh`, and
the landing commands the user approves.

Run `hc --skill` once per session if its behavior is not already in context;
it is the source of truth for every `hc` command below.

## 0. Preflight

`$HC_TERMINAL_ID` must be set: workers report to it. If it is empty, stop and
tell the user to start this session inside an hc terminal (the Herdr app, or
`hc run <harness>`). Then `hc ls --json`: workers you started earlier in this
session are live children; pick them back up rather than re-dispatching.

All fleet files live under `~/.fleet`: worktrees in
`~/.fleet/worktrees/<repo-name>/<name>`, reports in `~/.fleet/reports/<name>.md`.
Workers inherit folder trust from it, so the user trusts `~/.fleet` once in
their harness.

## 1. Intake

Turn the request into tasks. Each task is one of:

- **implement**: changes code and ends in a pull request.
- **investigate**: read-only; ends in a report file.

For each task write a **ticket**:

```
Goal: <one outcome>
Scope: <files/areas in scope; anything explicitly out of scope>
Done when: <checkable conditions: tests that pass, questions answered>
Report file: <investigate only: ~/.fleet/reports/<name>.md>
Report to: <your $HC_TERMINAL_ID>
```

Done when every task has a ticket whose `Done when` you could check yourself.
Ask the user only when two readings of the request lead to different work.

## 2. Dispatch

Name each task in kebab-case (`fix-login`); the name is the hc terminal name
and the branch suffix.

- implement: `git -C <repo> worktree add ~/.fleet/worktrees/<repo-name>/<name> -b fleet/<name>`,
  then `hc run --bg --json --name <name> --cwd <worktree> implement "<ticket>"`
- investigate: `mkdir -p ~/.fleet/reports`, then
  `hc run --bg --json --name <name> --cwd <repo> investigate "<ticket>"`

Check `first_message.sent` in each result. When it is false, `hc read <name>`,
show the user what blocks startup (a trust prompt means the folder sits
outside trusted ground), then `hc send <name> "<ticket>"` once it is cleared.
Done when every ticket is confirmed delivered. Tell the user what is running.

## 3. Supervise

Wait with `hc wait --children any --timeout 100` (keeps each call under the
shell tool's limit). Act on the reason, then wait again:

- `timeout`: a check-in. Wait again.
- `message`: a worker report or a user message is your next input. Handle it.
- `blocked`: `hc read --lines 40 <name>`, show the user what the worker is
  asking, and relay their decision. The user approves permissions themselves,
  in the worker's tab or with `hc attach <name>`.
- `error` or exited: `hc read <name>`, then re-send with a correction or end
  the task.

Answer user messages between waits; the fleet keeps running while you talk.

## 4. Verify

A worker's report is a claim. Check the evidence before anything reaches the
user:

- implement: read the diff (`git -C <worktree> diff main...HEAD`), confirm it
  stays in scope, and check the PR's CI (`gh pr checks <url>`).
- investigate: read the report file in full; spot-check its cited evidence.

Measure against the ticket's `Done when`. When it falls short, send it back
with the specific gap: `hc send <name> "<what is missing>"`, then return to 3.
Done when every condition is met with evidence you looked at.

## 5. Report and land

Report each verified task to the user in one or two lines: outcome, link or
report path, risk. Merge only when the user says to (`gh pr merge <url>`).

Clean up each finished task:

- `hc kill <name>; hc rm <name>`
- implement, after merge or abandonment: `git -C <repo> worktree remove <worktree>`
  and `git -C <repo> branch -D fleet/<name>`
- investigate: leave the report in `~/.fleet/reports/` for the user.

Done when `hc ls` shows none of your workers and no `fleet/*` worktrees remain
for landed tasks.
