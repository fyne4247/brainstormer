# Writing Workspace

A personal creative-writing workspace powered by Claude Code. It holds
multiple independent writing projects — one per subfolder — each with its
own knowledge base and its own `CLAUDE.md` conventions, backed by a shared
set of agents and skills for brainstorming, critique, continuity, structure,
and knowledge-base upkeep.

## The core rule: Claude never writes prose

This workspace is set up as an **editorial partner, not a ghostwriter**. The
author writes every word of the manuscript. Claude and its agents brainstorm,
critique the author's own pages, check canon and continuity, outline
structure, build style references from existing prose, and maintain the
knowledge base — but they don't draft, rewrite, or insert manuscript prose.
See `CLAUDE.md` for the full rule.

## Getting started

Start a session from the workspace root with the editor agent:

```bash
claude --agent muse
```

`muse` is the editorial lead — it never drafts prose, and it dispatches
focused subagents (`critic`, `editor`, `reader-sim`, `continuity-checker`,
`brainstormer`, `outliner`, `style-creator`, `character-sim`, `chronicler`)
for deeper passes.

To start a new project, create a subfolder and run `/setup` from a muse
session. It interviews you, proposes a `kb/` structure, collects writing
samples, and writes that project's `CLAUDE.md`.

### One-click launcher

`Brainstormer.command` is a double-clickable shortcut that starts a muse
session without opening a terminal manually. It always runs from the
workspace root (wherever the file itself lives), walks you through a few
quick menus before launching, and offers to save your work once the
session ends.

- **Model** — pick a family first (`Opus` / `Sonnet` / `Haiku` / `Fable`),
  then a specific version from a numbered list, e.g.:
  - Opus: 4.8 (recommended), 4.7, 4.6, 4.5, or 3
  - Sonnet: 5 (recommended), 4.6, 4.5, or 4.0
  - Haiku and Fable each have one current version, so there's no
    sub-menu — just confirm the family.

  Retired versions (currently Opus 3 and Sonnet 4.0) are labeled as such —
  they still launch, but Claude Code itself will show a warning banner.
  Enter or `0` at either menu skips and uses Claude Code's own default.
- **Effort** — pick `low` / `medium` / `high` / `xhigh` / `max` from a
  numbered list, or skip for the default.
- **Project** — pick from any subfolder that has its own `CLAUDE.md`, or
  skip and let muse ask once it's running.

These all run before Claude ever starts, as ordinary shell prompts
(`read -p`), and feed straight into real CLI flags (`--model`, `--effort`).
The project choice can't become a CLI flag the same way (Claude Code
doesn't have a "which project" flag), so instead it's handed to muse as
the first message of the session: read that project's `CLAUDE.md` and its
`exports/<project>.ai.md` snapshot (see "Flattened snapshots" below) —
the cheap, pre-flattened context file, not every individual `kb/` file —
before acting.

**When the session ends** — however it ends (`/exit`, closing the window,
a crash) — the launcher checks every project subfolder for uncommitted
changes and, for each one that has any, asks whether to save them. A yes
commits with a plain timestamped message. This is a safety net for work
you'd otherwise lose if you forget to save before exiting, not a
replacement for the real thing: a proper `/save` (or "save my progress")
*inside* a session still writes a natural-language commit message, and
should be your default way of saving.

**First time only — make it double-clickable:**

1. Open Terminal and `cd` into the folder you cloned this repo into.
2. Run:
   ```bash
   chmod +x Brainstormer.command
   ```
3. From then on, double-click `Brainstormer.command` in Finder to launch.
   (macOS may warn the first time that it's from an unidentified developer —
   right-click → **Open** once to approve it, then double-click normally
   after that.)

### One-time setup after cloning

Besides installing Claude Code itself, there's nothing this workspace
strictly requires — but two things are worth knowing about:

- **`chmod +x Brainstormer.command`** (above), so the launcher is
  clickable.
- **Auto-export needs a one-time local setting.** Saving a project can
  auto-refresh its snapshot in `exports/`, but the instruction that makes
  that happen (`core.hooksPath` — see "What's a git hook?" below) lives in
  each project's local `.git/config`, which is **not** part of the files
  `git clone` copies. So a workspace cloned fresh from GitHub has the
  export script but nothing telling git to run it. **`Brainstormer.command`
  checks for this every time it launches** and offers to fix it in one step
  if anything's missing — you don't need to do this manually. It's also
  always available as `sh scripts/install-flatten-hook.sh`. New projects
  created with `/setup` wire themselves automatically.
  Answering `n` just skips it for that one launch (it'll ask again next
  time); answering `never` remembers that per-project so it stops asking,
  recorded in a local, gitignored `.brainstormer-hooks-declined` file —
  delete that file to reset.
- **Python 3** is needed for the auto-export snapshots
  (`scripts/flatten_project.py`) to run. It's optional — everything else in
  the workspace works without it — but if it's missing, install it (e.g.
  `brew install python3`) to get `exports/*.md` snapshots after each save.

<details>
<summary>What's a git hook? (click to expand)</summary>

A git hook is a script git runs automatically at some moment — here,
"right after a commit." `scripts/git-hooks/post-commit` is that script: it
re-runs `flatten_project.py` after you save, so `exports/` stays current.

That script file is a normal tracked file, so cloning the repo gets it no
problem. What *doesn't* come along is the separate setting that tells git
"use that script." That setting (`core.hooksPath`) lives in `.git/config`,
which git deliberately never versions — it's local machine metadata, reset
fresh on every clone. So after a clone, the hook script exists but is
inert until something sets `core.hooksPath` again on the new machine. That's
the only thing `scripts/install-flatten-hook.sh` does, and it's what the
launcher now checks and offers to run for you.

Nothing about `kb/`, agents, skills, or muse itself depends on this — it
only affects whether the `exports/*.md` snapshots stay auto-refreshed.

</details>

## Layout

```
brainstormer/
├── CLAUDE.md              # workspace-wide conventions
├── .claude/
│   ├── agents/             # muse, critic, editor, reader-sim, brainstormer, ...
│   └── skills/              # craft methodology shared across agents
├── scripts/                # flatten_project.py, git hooks
├── exports/                 # generated per-project snapshots (git-ignored)
├── <project-name>/
│   ├── CLAUDE.md            # this project's conventions
│   ├── story/                # the manuscript (author-owned prose)
│   ├── work/                  # outline/, drafts/, critique-reports/, brainstorm/
│   └── kb/                     # this project's knowledge base
│       ├── styles/  characters/  world/  timeline/  canon/  issues/  samples/
│       └── vocab.md
└── <another-project>/ ...
```

Knowledge bases never cross projects — each project's `kb/` is
self-contained.

## Agents

| Agent | Role |
|---|---|
| **muse** | Author-facing editorial lead: coordinates the other agents, never drafts prose |
| **brainstormer** | Wide-open idea exploration for a scoped question |
| **critic** | Adversarial critique of a draft, one focus area at a time |
| **editor** | Holistic book-editor pass: structure, voice, line quality, copy consistency |
| **reader-sim** | Experiential first-time-reader response to a draft |
| **character-sim** | In-character conversation for voice discovery and relationship testing |
| **continuity-checker** | Cross-references content against established canon |
| **outliner** | Sequences a confirmed direction into arc/chapter/beat outlines |
| **style-creator** | Analyzes prose samples to produce style reference files |
| **chronicler** | Extracts factual state changes from written chapters into the kb |

## Saving progress

Each project subfolder is its own git repo. Use `/save` from a project
session, or just ask "save my progress" — Claude checks status, stages
what changed, and writes a plain-language commit message.

## Flattened snapshots

Every subproject can be exported to a single combined Markdown file under
`exports/` at the workspace root — a one-file snapshot of that project's
whole knowledge base, generated by `scripts/flatten_project.py`. A
`post-commit` git hook regenerates it automatically after every save; new
projects are enrolled once via `sh scripts/install-flatten-hook.sh`. The
export is derived and git-ignored — the per-file `kb/` remains canonical.

## License

Apache License 2.0. See [LICENSE](LICENSE).
