# fleet

One lead agent that runs a fleet of worker agents in [hc](https://herdr.dev)
(Herdr Core) terminals. The lead plans, dispatches, verifies, and reports; the
workers make the changes.

- `.agents/skills/orchestrate/`: the lead's protocol, invoked with
  `/orchestrate`. `.claude/skills/orchestrate` is a symlink to it so Claude
  Code finds it too. It is project-local, so it is available only to a lead
  started in this repo. On Windows, clone with Developer Mode on and
  `core.symlinks=true` so the symlink checks out as a link.
- `herdr-core/templates/`: hc worker roles. `implement` works in a git
  worktree and opens a PR; `investigate` is read-only and writes a report
  file.

## Install

```powershell
./install.ps1        # Windows
```

```bash
bash ./install.sh    # macOS / Linux
```

This links `herdr-core/templates/` as hc's templates folder
(`%APPDATA%\herdr-core\templates` on Windows,
`~/.config/herdr-core/templates` elsewhere). Confirm with `hc templates`.

## Use

Worktrees and reports live under `~/.fleet`. Trust that folder once in your
harness (start it there and accept the prompt) so workers launch without a
trust prompt.

Start the lead in this repo, inside an hc terminal so workers can report to
it: open a terminal in the Herdr app, or `hc run claude`. Then run
`/orchestrate` and make a request.
