---
name: digest
description: Report where every fleet task stands, by project. Use when the user runs /digest or asks for a catch-up, status, "where do things stand", or "where did I leave off".
---

# Digest

Run `bin/fleet digest` (from this repo) and relay its three sections to the
user in this order: **Needs you**, **Underway**, **Finished**.

- Keep each row's project (`<repo>/<task>`) and every full `https://` URL and
  report path.
- Say each row in plain words; leave out mechanics such as status lines,
  terminals, and acks.
- Render a section with nothing in it as "none" rather than dropping it.

This is read-only. Do not answer, relaunch, merge, or clean anything while
digesting; act on a row only when the user asks.
