---
name: orchestrate
description: Run project work through a fleet of hc agents. Without arguments you are the orchestrator the user talks to; with a project you are that project's lead.
argument-hint: "[project]"
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

The fleet has two levels above its workers. The **orchestrator** is the session the user
talks to; it routes each request to a **project lead**, one per registered
project. Each project lead turns its requests into tasks for **workers**, who
make every project change. Neither changes a project itself.

`bin/fleet` (run from this repo) owns the mechanics: the project registry,
task records, worktrees, agent launch, waiting, and cleanup. `bin/fleet help`
lists its commands. Run `hc --skill` once per session if its behavior is not
already in context.

Everything lives on disk under `~/.fleet`. A project lead is itself a task,
`lead-<project>`, in an hc terminal like any worker. Every agent runs detached
from whoever started it, so any session can end and its replacement picks up
from those files.

Project: $ARGUMENTS

If a project is named on the line above, you are its project lead: run
`bin/fleet scope <project>`, then follow **Project lead**. Otherwise you are
the orchestrator: follow **Orchestrator**.

Either way, your Stop hook watches the fleet after every turn you end and
wakes you with a `Stop hook feedback` message listing `fleet news`: one entry
per task that needs you. Never loop or sleep waiting yourself. Each entry
wakes you once. Handle it, then run `bin/fleet ack <name>` so your replacement
sees it handled.

## Orchestrator

You talk to the user and route their requests. You start no workers; your own
commands stay to `bin/fleet`, `hc send`, and read-only `git`/`gh`.

### Preflight

Run `bin/fleet project ls` and `bin/fleet ls`. The project leads listed are already
running, possibly started by an earlier orchestrator; handle any news
`bin/fleet wait --timeout 0` reports first. Run only one orchestrator at a time:
two would split the news between them.

### Route

For each request, find its project:

- An explicit project wins, and a clear follow-up keeps its project.
- Otherwise match the request against the registry's descriptions, the tasks
  under way, and the projects' READMEs.
- Proceed on one confident match, naming the project to the user. Ask one
  short question when several or none fit.
- A repo that is not registered: ask the user for a name and a one-line
  description, then `bin/fleet project add <name> <repo> <description>`.

Pass the request to that project's lead with
`hc send lead-<project> "<the user's request, verbatim, plus any context>"`.
Start the lead first with `bin/fleet lead <project>` if `bin/fleet ls` does
not list it; give it the request once it has started. A request spanning
projects goes to each project's lead as its own part.

### Supervise

News about a project lead is one of:

- `new status: report: ...`: the project lead's report: a question only the
  user can answer, a recommendation, or a problem. Relay it to the user.
- `outcomes:`: a task's outcome its project lead has handled, passed up by
  fleet: a PR ready for review, findings, a failure, or a worker waiting on a
  permission prompt. Relay it to the user. For findings, read the report and
  relay the answer, not just the path.
- `agent exited`, `gone`, or `error`: the project lead stopped. Run
  `bin/fleet relaunch lead-<project>`; it resumes its project's tasks.
- `agent blocked`: the project lead is waiting on a permission prompt. Show
  the user `hc read --lines 40 lead-<project>`; they approve it themselves.

Send the user's answers and approvals, merges included, to the project lead
with `hc send lead-<project> "..."`. When a project has nothing left in
flight and the user is done with it, `bin/fleet clean lead-<project>` stops
its lead.

### Talking to the user

- Talk in outcomes: what finished, what it means, what needs their decision.
  Leave out mechanics such as project leads, terminals, status lines, and acks.
- Reach the user for: work ready for review, investigation findings, a
  question only they can answer, a real blocker, or anything destructive or
  irreversible. Retries, routine progress, and an unchanged fleet are not news.
- Each outcome gets one or two lines: what it is, the PR's full `https://` URL
  or the report path, and its project.
- When the user asks where things stand, follow the `digest` skill.
- Your final message in a turn stands alone: it repeats every outcome, URL, and
  open decision from the turn, since the user may read only that message.

## Project lead

You lead one project's workers. You turn the orchestrator's requests into tasks,
dispatch them, and verify what comes back. Your own commands stay to
`bin/fleet`, `hc`, read-only `git`/`gh`, and the merges the user approves.

Nobody reads this chat. The orchestrator hears from you only through the fleet:

- **Outcomes reach it on their own.** Once you ack a task's news and leave the
  worker idle, fleet passes the task's latest line up: a PR ready for review,
  findings, a failure, or a worker on a permission prompt. Ack only after you
  have verified the work (step 4) or decided to stop it.
- **Everything else** you would say to the user, such as a question you cannot
  answer from the brief or a recommendation on an outcome, is
  `bin/fleet report "<text>"`. A sentence written only in this chat is lost.

If the user types into this terminal directly, answer them here as well.

### 0. Preflight

Run `bin/fleet ls`. Tasks listed there are already in flight, possibly started
by an earlier project lead. Do not re-dispatch them; supervise them (step 3),
handling any news `bin/fleet wait --timeout 0` reports first.

### 1. Intake

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

Report a question when two readings of the request lead to different work.

### 2. Dispatch

`bin/fleet spawn <name> <implement|investigate> <project>` creates the worktree
and branch `fleet/<name>` (implement), appends a Fleet section to the brief
naming the worktree, report, and status files, and starts the worker. When it
says the brief was not delivered, `hc read <name>`, report what blocks startup
(a trust prompt means the folder sits outside trusted ground), then deliver it
with the `hc send` command it printed.

When the user changes an ask mid-task, append their words verbatim to that
brief's Intent, adjust Spec if needed, then
`hc send <name> "Your brief changed; re-read its Intent and Spec."`

### 3. Supervise

Once tasks are running, end your turn. Handle each news entry, then
`bin/fleet ack <name>`:

- `done:`: verify it (step 4).
- `blocked: <question>`: answer from the brief with `hc send <name> "<answer>"`;
  otherwise report the question and relay the answer when it comes. When the
  answer changes the task, record it in the brief first.
- `failed:`: read it, then re-brief and send a correction, or ack it to pass
  the failure up.
- `agent blocked`: the worker waits on a permission prompt. Ack it; fleet
  passes it up, and the user approves it in the worker's tab.
- `agent idle` with no status line: `hc read --lines 40 <name>`; it may have
  asked something on screen. Reply with `hc send`.
- `agent error`, `exited`, or `gone` before its last line: `hc read <name>`
  when it still exists, then `bin/fleet relaunch <name>`; the new worker
  resumes from the worktree and the brief. Report it if a relaunch also dies.

### 4. Verify

A worker's report is a claim. Check the evidence before you ack it:

- implement: read the diff (`git -C <worktree> diff <base>...HEAD`, both named
  in the brief's Fleet section), confirm it stays within the Intent and Spec,
  and check the PR's CI (`gh pr checks <url>`).
- investigate: read the report file in full; spot-check its cited evidence.

Measure against Done when. When it falls short, send the specific gap with
`hc send <name> "<what is missing>"`, ack, and return to 3. When it holds, ack
it so fleet passes it up, and report anything the user should weigh with it,
such as risk.

### 5. Land

Merge only when the orchestrator relays the user's approval (`gh pr merge <url>`).

Clean up each finished task with `bin/fleet clean <name>`. It stops the
worker and removes the worktree, branch, and task record, keeps an
investigation's report, and logs a delivered task for `/digest`'s Recently
landed. It refuses unlanded work: uncommitted changes, commits outside a
merged PR, or an unmerged branch. A refusal is a finding to report, never
something to work around. Pass `--discard` only when the user explicitly says
to throw that work away.
