# fleet

A lead agent that runs a fleet of worker agents. You give the lead a request;
it splits the work into tasks, writes each a brief, hands it to a worker,
checks the evidence that comes back, and reports plain outcomes. Workers make
every change.

Workers take one of two roles:

- **implement**: works in its own git worktree and opens a pull request.
- **investigate**: read-only; answers one question in a report file.

fleet currently runs workers in [hc](https://herdr.dev) (Herdr Core)
terminals, with Claude Code as the agent harness.

## Layout

- `.agents/skills/orchestrate/`: the lead's protocol, invoked with
  `/orchestrate`. `.claude/skills/orchestrate` is a symlink to it so Claude
  Code finds it too. It is project-local, so it is available only to a lead
  started in this repo. On Windows, clone with Developer Mode on and
  `core.symlinks=true` so the symlink checks out as a link.
- `.agents/skills/digest/`: `/digest`, a catch-up on every task by project
  (`bin/fleet digest`). Linked into `.claude/skills/` the same way.
- `herdr-core/templates/`: the worker roles as hc templates.
- `bin/fleet`: the lead's mechanics (task records, worktrees, worker launch,
  waiting, cleanup). Bash; on Windows it runs in Git Bash. Needs `hc`, `jq`,
  `git`, and `gh` on `PATH` (or `FLEET_HC` pointing at `hc`).

## How it holds together

Each task is a folder in `~/.fleet/tasks/<name>/`: the brief the lead wrote,
fleet's record of the task, and an append-only status file the worker writes
`done:`, `blocked:`, or `failed:` lines to. Workers run in hc terminals
detached from the lead, so closing the lead stops nothing: work continues, its
reports wait in the status files, and the next lead picks them up with
`bin/fleet ls` and `bin/fleet wait`. `bin/fleet digest` says where every task
stands, grouped by project: what needs you, what is underway, and what is
finished. `bin/fleet clean` refuses to remove work that has not landed.

The lead never waits in a loop. `/orchestrate` registers a Stop hook
(`bin/fleet hook`, with Claude Code's `asyncRewake`) that watches the status
files and worker terminals after every turn the lead ends, and wakes the idle
lead when a task needs it.

## Install

```powershell
./install.ps1        # Windows
```

```bash
./install.sh         # macOS / Linux
```

This links `herdr-core/templates/` as hc's templates folder
(`%APPDATA%\herdr-core\templates` on Windows,
`~/.config/herdr-core/templates` elsewhere). Confirm with `hc templates`.

## Use

Tasks, worktrees, and reports live under `~/.fleet`. Trust that folder once
in your harness (start it there and accept the prompt) so implement workers
launch without a trust prompt; investigate workers run in the repo itself, so
trust each repo you investigate too.

Start the lead in this repo and run `/orchestrate`, then make a request.
Starting it in a Herdr app terminal puts workers in the same space as the lead;
anywhere else they appear in a `fleet` space. If the lead's session ends,
start a new one and run `/orchestrate` again: it resumes every task in
flight.
