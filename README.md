# fleet

One agent you talk to, running a fleet of agents across your projects. You
give the **orchestrator** a request; it hands it to the **project lead** for that
project, which splits the work into tasks, writes each a brief, hands it to a
**worker**, checks the evidence that comes back, and passes up plain
outcomes. Workers make every change.

Workers take one of two roles:

- **implement**: works in its own git worktree and opens a pull request.
- **investigate**: read-only; answers one question in a report file.

fleet currently runs its agents in [hc](https://herdr.dev) (Herdr Core)
terminals, with Claude Code as the agent harness.

## Layout

- `.agents/skills/orchestrate/`: the protocol for the orchestrator and project leads. `/orchestrate` makes a
  session the orchestrator; fleet starts each project lead with
  `/orchestrate <project>`. `.claude/skills/orchestrate` is a symlink to it so
  Claude Code finds it too. It is project-local, so every session runs in this
  repo. On Windows, clone with Developer Mode on and `core.symlinks=true` so
  the symlink checks out as a link.
- `.agents/skills/digest/`: `/digest`, a catch-up on every task by project
  (`bin/fleet digest`). Linked into `.claude/skills/` the same way.
- `herdr-core/templates/`: the worker roles as hc templates.
- `bin/fleet`: fleet's mechanics (project registry, task records,
  worktrees, agent launch, waiting, cleanup). Bash; on Windows it runs in Git
  Bash. Needs `hc`, `jq`, `git`, and `gh` on `PATH` (or `FLEET_HC` pointing at
  `hc`).

## How it holds together

A project is a body of work, not a repo. Projects are registered by name in
`~/.fleet/projects`, each with a one-line description the orchestrator routes
requests by and one or more repos the work spans. A repo can belong to several
projects. Each task runs in one of its project's repos, named when it is
spawned if the project has several, and fleet records which.

Each task is a folder in `~/.fleet/tasks/<name>/`: the brief its project lead wrote,
fleet's record of the task, and an append-only status file the worker writes
`done:`, `blocked:`, or `failed:` lines to. A project lead is a task too,
`lead-<project>`, whose status file is what the orchestrator hears. Every
agent runs in an hc terminal detached from whoever started it, so closing any
session stops nothing: work continues, its reports wait in the status files, and
its replacement picks them up with `bin/fleet ls` and `bin/fleet wait`.

Nothing a worker delivers depends on a project lead remembering to report it.
Once the project lead has handled a task's latest line (verified a PR, read a
report, given up on a failure) and acked it, fleet appends that outcome to the
project lead's status file itself. The project lead adds its own judgement,
such as questions only the user can answer, with `bin/fleet report`.

`bin/fleet digest` says where every task stands, grouped by project: what
needs you, what is underway, what is finished, and what recently landed
(`bin/fleet clean` logs each delivered task to `~/.fleet/landed` before
removing it). `bin/fleet clean` refuses to remove work that has not landed.

No session waits in a loop. `/orchestrate` registers a Stop hook
(`bin/fleet hook`, with Claude Code's `asyncRewake`) that watches the fleet
after every turn a session ends and wakes the idle session when it has news: the top
lead for its project leads' reports and outcomes, a project lead for its
workers. Each session keeps its watch, and which role it has, in
`~/.fleet/sessions/<session id>/`.

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

Start a session in this repo, run `/orchestrate`, and make requests. Name the
project or let the orchestrator work it out; it registers new work as a project
with your name and description for it, across whichever repos it spans, starts that project's lead, and
reports outcomes from every project in this one conversation. Each project
lead runs in its own hc terminal, where you can watch it or type to it.

Starting the orchestrator in a Herdr app terminal puts every agent in its space;
anywhere else they appear in a `fleet` space. If the orchestrator's session ends,
start a new one and run `/orchestrate` again: the project leads kept running,
and it picks up their news.
