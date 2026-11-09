# fleet

A lead agent that runs a fleet of worker agents. You give the lead a request;
it splits the work into tickets, hands each to a worker, checks the evidence
that comes back, and reports plain outcomes. Workers make every change.

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
- `herdr-core/templates/`: the worker roles as hc templates.

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

Worktrees and reports live under `~/.fleet`. Trust that folder once in your
harness (start it there and accept the prompt) so workers launch without a
trust prompt.

Start the lead in this repo, inside an hc terminal so workers can report to
it: open a terminal in the Herdr Core app, or `hc run claude`. Then run
`/orchestrate` and make a request.
