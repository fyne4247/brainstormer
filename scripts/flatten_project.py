#!/usr/bin/env python3
"""
Flatten a subproject into a single Markdown file in the workspace root.

Given a project subfolder (e.g. "Breaking the Beasts"), concatenates every
`.md` file inside it into one file named after the project
(e.g. `breakingthebeasts.md`) in the parent/workspace root.

Heading hierarchy in the combined file:

    # <Project Name>            <- once, at the very top
    ## <subdirectory>           <- one per directory that holds .md files
    ### <filename.md>           <- one per file
    #### ...                    <- each file's OWN headings, demoted by 3

So a heading that is `#` inside a source file becomes `####` in the output;
`##` becomes `#####`; and so on, capped at `######`. Headings inside fenced
code blocks (``` or ~~~) are left untouched.

Usage:
    python3 scripts/flatten_project.py "Breaking the Beasts"
    python3 scripts/flatten_project.py "Breaking the Beasts" --output custom.md

Run from anywhere; paths resolve relative to the workspace root (the parent
of this script's directory).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent

HEADING_RE = re.compile(r"^(#{1,6})(\s.*)$")
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")

# Directories inside a project we never fold in.
SKIP_DIRS = {".git", ".claude", "node_modules", "__pycache__"}


def slugify(name: str) -> str:
    """'Breaking the Beasts' -> 'breakingthebeasts'."""
    return re.sub(r"[^a-z0-9]", "", name.lower())


def demote_body(text: str, levels: int = 3) -> str:
    """Push every ATX heading down by `levels`, capped at 6. Skip code fences."""
    out: list[str] = []
    in_fence = False
    fence_marker = ""
    for line in text.splitlines():
        fence = FENCE_RE.match(line)
        if fence:
            marker = fence.group(1)[0]  # ` or ~
            if not in_fence:
                in_fence, fence_marker = True, marker
            elif marker == fence_marker:
                in_fence, fence_marker = False, ""
            out.append(line)
            continue
        if not in_fence:
            m = HEADING_RE.match(line)
            if m:
                new_level = min(len(m.group(1)) + levels, 6)
                out.append("#" * new_level + m.group(2))
                continue
        out.append(line)
    return "\n".join(out)


def collect_md_files(project_dir: Path) -> list[Path]:
    files = [
        p
        for p in project_dir.rglob("*.md")
        if not any(part in SKIP_DIRS for part in p.relative_to(project_dir).parts)
        and p.name != "CLAUDE.md"
    ]
    # Sort: root-level files first, then by directory path, then filename.
    def key(p: Path):
        rel = p.relative_to(project_dir)
        depth = len(rel.parts) - 1  # 0 == project root
        return (depth != 0, str(rel.parent), rel.name.lower())

    return sorted(files, key=key)


def build(project_dir: Path, project_name: str) -> str:
    lines: list[str] = []
    lines.append(f"# {project_name}")
    lines.append("")

    current_group = object()  # sentinel so the first file always emits a header
    for path in collect_md_files(project_dir):
        rel = path.relative_to(project_dir)
        group = str(rel.parent) if str(rel.parent) != "." else "(project root)"
        if group != current_group:
            lines.append(f"## {group}")
            lines.append("")
            current_group = group
        lines.append(f"### {rel.name}")
        lines.append("")
        body = path.read_text(encoding="utf-8").strip("\n")
        lines.append(demote_body(body))
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description="Flatten a subproject into one .md file.")
    ap.add_argument("project", help="Project subfolder name, e.g. 'Breaking the Beasts'")
    ap.add_argument("--output", help="Override output filename (default: <slug>.md)")
    args = ap.parse_args()

    project_dir = (WORKSPACE_ROOT / args.project).resolve()
    if not project_dir.is_dir():
        print(f"error: project folder not found: {project_dir}", file=sys.stderr)
        return 1
    if WORKSPACE_ROOT not in project_dir.parents:
        print("error: project must live directly under the workspace root", file=sys.stderr)
        return 1

    exports_dir = WORKSPACE_ROOT / "exports"
    exports_dir.mkdir(exist_ok=True)
    out_name = args.output or f"{slugify(project_dir.name)}.md"
    out_path = exports_dir / out_name

    content = build(project_dir, project_dir.name)
    out_path.write_text(content, encoding="utf-8")

    n_files = len(collect_md_files(project_dir))
    print(f"wrote {out_path.relative_to(WORKSPACE_ROOT)}  ({n_files} files, {len(content):,} chars)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
