---
description: One-time setup for a new writing project (interview, kb structure, CLAUDE.md)
argument-hint: <project name>
---

Use the project-setup skill to set up a new creative writing project.

Confirm the project's subfolder (create it if it doesn't exist yet), then
interview me about the project, propose a `kb/` structure, collect any
writing samples I have into `kb/samples/`, and write that project's
`CLAUDE.md`.

This sets up structure and may analyze existing samples for style — it does
not write new prose.

After setup, finish enrolling the project automatically rather than telling
me to do it by hand:
1. If the new project folder isn't already a git repo, run `git init` inside it.
2. From the workspace root, run `sh scripts/install-flatten-hook.sh` to wire
   up the auto-flattening hook (idempotent — safe to run even if some
   projects are already enrolled).
3. Report what you did in one or two lines ("Initialized a repo for
   Breaking the Beasts and enrolled it in auto-flattening.").

$ARGUMENTS
