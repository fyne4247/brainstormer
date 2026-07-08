---
description: Save your progress (creates a versioned snapshot of the active project)
argument-hint: <optional description>
---

Save the current state of my work in the active project. This creates a
versioned snapshot — no git jargon, just "saving."

Steps:
1. Confirm which project is active (each project subfolder is its own git repo).
2. `cd` into that project's directory.
3. `git status` to see what changed.
4. `git add -A` to stage everything.
5. If I gave a description below, use it as the commit message. Otherwise,
   look at what changed and write a short, natural description of it
   ("Added Ellora's character profile", "Reworked the act 2 outline").
6. `git commit` with that message.

The post-commit hook auto-regenerates the flattened export in `exports/` at
the workspace root — no separate step needed.

Report back with "Saved!" and a one-line summary of what was saved — never
say "committed to git."

$ARGUMENTS
