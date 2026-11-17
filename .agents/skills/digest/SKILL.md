---
name: digest
description: Report where every fleet task stands, by project. Use when the user runs /digest or asks for a catch-up, status, "where do things stand", or "where did I leave off".
---

# Digest

Run `bin/fleet digest` (from this repo) and relay its four sections as four
markdown tables, one per section, in this order. Every section is always
present; one with no rows is the heading followed by "none".

**Needs you**: only what the user must act on themselves.

| Project | Item | You need to | Link |
|---|---|---|---|

**Underway**: still moving, or the project lead's to resolve.

| Project | Item | State |
|---|---|---|

**Finished**: done, not yet cleaned up.

| Project | Item | Link |
|---|---|---|

**Recently landed**: cleaned up, newest first.

| Project | Item | Link |
|---|---|---|

## Cells

Each row of the command's output is `<project>/<task>: <what>`; landed rows
start with their date. One table row per output row, each cell a few plain
words:

- **Project**: the `<project>` part.
- **Item**: the `<task>` name. In Recently landed, append the landed date:
  `drop-branch-prefix (2026-11-16)`.
- **You need to**: the verb for what the user does: `review PR` (PR to
  review), `answer question` (asks), `decide next step` (failed), `approve
  prompt` (worker is waiting on a prompt). When an ask is a specific choice,
  name it in a few words, e.g. `pick findings`.
- **State**: a short phrase: `working`, `starting`, `with lead`, `stalled`,
  `PR missing`, `PR closed`.
- **Link**: the row's full `https://` URL or absolute report path, and nothing
  else; `-` when the row has neither. Never shorten a URL or path.

Leave out of the tables, and out of the chat, everything else in a row:
summaries, answers, CI notes, merge-order caveats, scope changes. The link
holds the detail. Leave out mechanics too: status lines, terminals, acks.
Nothing goes after the four tables.

This is read-only. Do not answer, relaunch, merge, or clean anything while
digesting; act on a row only when the user asks.
