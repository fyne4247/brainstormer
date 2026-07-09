#!/usr/bin/env python3
"""
Export a subproject's kb/, work/, and story/ Markdown files into an existing
novelWriter project directory (nwProject.nwx + content/*.nwd).

One-way, non-destructive, opt-in:

  * Only items this script created (tracked in a git-ignored handle cache)
    are ever touched. Anything the author built by hand in the novelWriter
    app — folders, documents, the item tree outside our managed subtree —
    is left completely alone.
  * `meta/` (sessions.jsonl, index.json, options.json) is never written.
    novelWriter owns that state; it rebuilds/refreshes it on its own.
  * A source file that disappears moves its novelWriter item to Trash
    (reparented, matching novelWriter's own delete model) rather than being
    hard-deleted. The exporter never unlinks a .nwd file.
  * Every run takes its own timestamped zip safety backup of the target
    project directory before writing anything.

The target novelWriter project path is machine-specific (e.g. a Dropbox
folder) and is stored in a git-ignored `.novelwriter-export.json` inside the
project folder — prompted for interactively on first run.

Usage:
    python3 scripts/export_novelwriter.py "Breaking the Beasts"

Run from anywhere; the project name resolves relative to the workspace root
(the parent of this script's directory), same convention as flatten_project.py.
"""
from __future__ import annotations

import hashlib
import json
import random
import shutil
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent

CONFIG_NAME = ".novelwriter-export.json"
HANDLE_CACHE_NAME = ".novelwriter-handles.json"

FMT_TIMESTAMP = "%Y-%m-%d %H:%M:%S"
FMT_FSTAMP = "%Y-%m-%d %H.%M.%S"  # matches novelWriter's own backup naming

# Longest-prefix-wins routing of source files into the novelWriter tree.
# (source path prefix, novelWriter class, synced-folder label, layout)
FOLDER_RULES = [
    ("story", "NOVEL", "Manuscript (synced)", "DOCUMENT"),
    ("work/drafts", "NOVEL", "Drafts (synced)", "DOCUMENT"),
    ("work/outline", "PLOT", "Outline (synced)", "NOTE"),
    ("work/brainstorm", "PLOT", "Brainstorm (synced)", "NOTE"),
    ("work/critique-reports", "PLOT", "Critique reports (synced)", "NOTE"),
    ("kb/characters", "CHARACTER", "Characters (synced)", "NOTE"),
    ("kb/world", "WORLD", "World (synced)", "NOTE"),
    ("kb/timeline", "TIMELINE", "Timeline (synced)", "NOTE"),
    ("kb/canon", "PLOT", "Canon (synced)", "NOTE"),
    ("kb/objects", "PLOT", "Objects (synced)", "NOTE"),
    ("kb/styles", "PLOT", "Styles (synced)", "NOTE"),
    ("kb/issues", "PLOT", "Issues (synced)", "NOTE"),
    ("kb/samples", "ARCHIVE", "Samples (synced)", "NOTE"),
    ("kb", "PLOT", "KB (synced)", "NOTE"),  # fallback for root-level kb/*.md
]

CLASS_ROOT_DEFAULT_NAME = {
    "NOVEL": "Novel",
    "PLOT": "Plot",
    "CHARACTER": "Characters",
    "WORLD": "Locations",
    "TIMELINE": "Timeline",
    "ARCHIVE": "Archive",
}

SKIP_NAMES = {"CLAUDE.md", "README.md", CONFIG_NAME, HANDLE_CACHE_NAME}
SKIP_DIRS = {".git", ".claude", "node_modules", "__pycache__"}


# ---------------------------------------------------------------- handles --

def make_handle(existing: set[str]) -> str:
    while True:
        handle = f"{random.getrandbits(52):013x}"
        if handle not in existing:
            existing.add(handle)
            return handle


# ----------------------------------------------------------------- config --

def config_path(project_dir: Path) -> Path:
    return project_dir / CONFIG_NAME


def load_target(project_dir: Path) -> Path:
    cfg_path = config_path(project_dir)
    if cfg_path.exists():
        data = json.loads(cfg_path.read_text(encoding="utf-8"))
        target = Path(data["target"]).expanduser()
        if not target.is_dir():
            print(f"error: configured target does not exist: {target}", file=sys.stderr)
            print(f"(fix or delete {cfg_path} and re-run)", file=sys.stderr)
            sys.exit(1)
        return target

    print(f"No novelWriter export target configured for '{project_dir.name}'.")
    raw = input("Path to the novelWriter project folder (contains nwProject.nwx): ").strip()
    target = Path(raw).expanduser().resolve()
    if not (target / "nwProject.nwx").exists():
        print(f"error: no nwProject.nwx found in {target}", file=sys.stderr)
        sys.exit(1)
    cfg_path.write_text(json.dumps({"target": str(target)}, indent=2) + "\n", encoding="utf-8")
    print(f"Saved target to {cfg_path} (git-ignored, machine-specific).")
    return target


def load_handle_cache(project_dir: Path) -> dict:
    path = project_dir / HANDLE_CACHE_NAME
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


def save_handle_cache(project_dir: Path, cache: dict) -> None:
    path = project_dir / HANDLE_CACHE_NAME
    path.write_text(json.dumps(cache, indent=2, sort_keys=True) + "\n", encoding="utf-8")


# ----------------------------------------------------------------- backup --

def backup_target(target: Path) -> Path:
    tree = ET.parse(target / "nwProject.nwx")
    title = tree.getroot().findtext("./project/name") or target.name
    safe_title = "".join(c for c in title if c not in '<>:"/\\|?*').strip() or target.name

    backup_root = Path.home() / "Backups"
    dest_dir = backup_root / safe_title
    dest_dir.mkdir(parents=True, exist_ok=True)
    stamp = time.strftime(FMT_FSTAMP)
    archive_base = dest_dir / f"{safe_title} pre-export {stamp}"
    archive_path = shutil.make_archive(str(archive_base), "zip", root_dir=target)
    return Path(archive_path)


# --------------------------------------------------------------- nwx tree --

def load_tree(target: Path) -> tuple[ET.ElementTree, ET.Element]:
    tree = ET.parse(target / "nwProject.nwx")
    root = tree.getroot()
    content = root.find("content")
    if content is None:
        raise RuntimeError("nwProject.nwx has no <content> element")
    return tree, content


def all_handles(content: ET.Element) -> set[str]:
    return {item.get("handle") for item in content.findall("item")}


def find_item(content: ET.Element, handle: str) -> ET.Element | None:
    for item in content.findall("item"):
        if item.get("handle") == handle:
            return item
    return None


def find_root_by_class(content: ET.Element, class_name: str) -> ET.Element | None:
    for item in content.findall("item"):
        if item.get("type") == "ROOT" and item.get("class") == class_name:
            return item
    return None


def find_trash_root(content: ET.Element) -> ET.Element | None:
    return find_root_by_class(content, "TRASH")


def default_status_import(root_elem: ET.Element) -> tuple[str, str]:
    status = root_elem.find("./settings/status/entry")
    importance = root_elem.find("./settings/importance/entry")
    return (
        status.get("key") if status is not None else "",
        importance.get("key") if importance is not None else "",
    )


def next_order(content: ET.Element, parent_handle: str) -> int:
    orders = [
        int(item.get("order", "0"))
        for item in content.findall("item")
        if item.get("parent") == parent_handle
    ]
    return max(orders, default=-1) + 1


def make_item(
    content: ET.Element,
    handles: set[str],
    *,
    item_type: str,
    class_name: str,
    parent: str | None,
    root: str,
    name: str,
    status_key: str,
    import_key: str,
    layout: str | None = None,
) -> ET.Element:
    handle = make_handle(handles)
    attrs = {
        "handle": handle,
        "parent": parent or "None",
        "root": root,
        "order": str(next_order(content, parent or "None")),
        "type": item_type,
        "class": class_name,
    }
    if layout:
        attrs["layout"] = layout
    item = ET.SubElement(content, "item", attrs)
    meta = ET.SubElement(item, "meta", {"expanded": "no"})
    if item_type == "FILE":
        meta.set("heading", "H0")
        meta.set("charCount", "0")
        meta.set("wordCount", "0")
        meta.set("paraCount", "0")
        meta.set("cursorPos", "0")
    name_elem = ET.SubElement(item, "name", {"status": status_key, "import": import_key})
    if item_type == "FILE":
        name_elem.set("active", "yes")
    name_elem.text = name
    return item


def get_or_create_root(
    content: ET.Element, handles: set[str], class_name: str, status_key: str, import_key: str
) -> ET.Element:
    existing = find_root_by_class(content, class_name)
    if existing is not None:
        return existing
    item = make_item(
        content,
        handles,
        item_type="ROOT",
        class_name=class_name,
        parent=None,
        root="",  # fixed up below once handle is known
        name=CLASS_ROOT_DEFAULT_NAME.get(class_name, class_name.title()),
        status_key=status_key,
        import_key=import_key,
    )
    item.set("root", item.get("handle"))
    return item


def get_or_create_folder(
    content: ET.Element,
    handles: set[str],
    parent_item: ET.Element,
    label: str,
    class_name: str,
    status_key: str,
    import_key: str,
) -> ET.Element:
    parent_handle = parent_item.get("handle")
    root_handle = parent_item.get("root")
    for item in content.findall("item"):
        if (
            item.get("type") == "FOLDER"
            and item.get("parent") == parent_handle
            and item.findtext("name") == label
        ):
            return item
    return make_item(
        content,
        handles,
        item_type="FOLDER",
        class_name=class_name,
        parent=parent_handle,
        root=root_handle,
        name=label,
        status_key=status_key,
        import_key=import_key,
    )


def prune_empty_synced_folders(content: ET.Element) -> int:
    """Remove empty FOLDER items anywhere under a "(synced)" label folder.

    That whole subtree is exclusively managed by this script (hand-authored
    content never lives there), so a folder with no children left over from
    an earlier run's routing (e.g. before a FOLDER_RULES fix) is dead weight,
    not data.
    """
    scope: set[str] = set()
    frontier = [
        item.get("handle")
        for item in content.findall("item")
        if item.get("type") == "FOLDER" and (item.findtext("name") or "").endswith("(synced)")
    ]
    scope.update(frontier)
    while frontier:
        handle = frontier.pop()
        for item in content.findall("item"):
            if item.get("parent") == handle and item.get("handle") not in scope:
                scope.add(item.get("handle"))
                frontier.append(item.get("handle"))

    removed = 0
    changed = True
    while changed:
        changed = False
        for item in list(content.findall("item")):
            handle = item.get("handle")
            if item.get("type") != "FOLDER" or handle not in scope:
                continue
            has_children = any(child.get("parent") == handle for child in content.findall("item"))
            if not has_children:
                content.remove(item)
                scope.discard(handle)
                removed += 1
                changed = True
    return removed


# --------------------------------------------------------------- routing --

def classify(rel_posix: str) -> tuple[str, str, str, int]:
    best = None
    for prefix, class_name, label, layout in FOLDER_RULES:
        if rel_posix == prefix or rel_posix.startswith(prefix + "/"):
            if best is None or len(prefix) > len(best[0]):
                best = (prefix, class_name, label, layout)
    if best is None:
        return "PLOT", "Misc (synced)", "NOTE", 1
    prefix_parts = len(best[0].split("/"))
    return best[1], best[2], best[3], prefix_parts


def collect_source_files(project_dir: Path) -> list[Path]:
    files = []
    for base in ("kb", "work", "story"):
        base_dir = project_dir / base
        if not base_dir.is_dir():
            continue
        for p in base_dir.rglob("*.md"):
            if p.name in SKIP_NAMES:
                continue
            if any(part in SKIP_DIRS for part in p.relative_to(project_dir).parts):
                continue
            files.append(p)
    return sorted(files)


# ------------------------------------------------------------------- nwd --

def write_nwd(target: Path, handle: str, parent_handle: str, class_name: str, layout: str,
              title: str, body: str, created: str) -> str:
    body = body.strip("\n") + "\n"
    digest = hashlib.sha1(body.encode("utf-8")).hexdigest()
    now = time.strftime(FMT_TIMESTAMP)
    header = (
        f"%%~name: {title}\n"
        f"%%~path: {parent_handle}/{handle}\n"
        f"%%~kind: {class_name}/{layout}\n"
        f"%%~hash: {digest}\n"
        f"%%~date: {created}/{now}\n"
    )
    (target / "content" / f"{handle}.nwd").write_text(header + body, encoding="utf-8")
    return now


def word_counts(body: str) -> tuple[int, int, int]:
    chars = len(body)
    words = len(body.split())
    paras = len([p for p in body.split("\n\n") if p.strip()])
    return chars, words, paras


# ------------------------------------------------------------------- main --

def main() -> int:
    if len(sys.argv) != 2:
        print("usage: export_novelwriter.py \"<Project Folder Name>\"", file=sys.stderr)
        return 1

    project_dir = (WORKSPACE_ROOT / sys.argv[1]).resolve()
    if not project_dir.is_dir():
        print(f"error: project folder not found: {project_dir}", file=sys.stderr)
        return 1

    target = load_target(project_dir)

    print(f"Backing up {target} before writing...")
    archive = backup_target(target)
    print(f"  backed up to {archive}")

    tree, content = load_tree(target)
    xml_root = tree.getroot()
    status_key, import_key = default_status_import(xml_root)
    handles = all_handles(content)

    cache = load_handle_cache(project_dir)
    source_files = collect_source_files(project_dir)
    seen_rel: set[str] = set()

    added = updated = unchanged = moved = 0

    for path in source_files:
        rel = path.relative_to(project_dir).as_posix()
        seen_rel.add(rel)
        class_name, label, layout, prefix_parts = classify(rel)

        root_item = get_or_create_root(content, handles, class_name, status_key, import_key)

        # Mirror any subdirectories beyond the synced-folder label as nested folders.
        # Drop however many path components the matched FOLDER_RULES prefix already covers.
        rel_dir_parts = Path(rel).parent.parts
        inner_parts = list(rel_dir_parts[prefix_parts:])
        parent_item = get_or_create_folder(
            content, handles, root_item, label, class_name, status_key, import_key
        )
        for part in inner_parts:
            parent_item = get_or_create_folder(
                content, handles, parent_item, part, class_name, status_key, import_key
            )

        body = path.read_text(encoding="utf-8")
        title = path.stem

        entry = cache.get(rel)
        if entry and find_item(content, entry["handle"]) is not None:
            handle = entry["handle"]
            item = find_item(content, handle)
            created = entry.get("created", time.strftime(FMT_TIMESTAMP))
            prev_hash = entry.get("hash")
            new_hash = hashlib.sha1((body.strip("\n") + "\n").encode("utf-8")).hexdigest()

            reparented = item.get("parent") != parent_item.get("handle")
            if reparented:
                item.set("parent", parent_item.get("handle"))
                item.set("root", parent_item.get("root"))
                item.set("order", str(next_order(content, parent_item.get("handle"))))

            if prev_hash == new_hash and not reparented:
                unchanged += 1
                continue

            write_nwd(target, handle, parent_item.get("handle"), class_name, layout, title, body, created)
            if prev_hash != new_hash:
                chars, words, paras = word_counts(body)
                meta = item.find("meta")
                meta.set("charCount", str(chars))
                meta.set("wordCount", str(words))
                meta.set("paraCount", str(paras))
                item.find("name").text = title
                updated += 1
            else:
                moved += 1
        else:
            item = make_item(
                content,
                handles,
                item_type="FILE",
                class_name=class_name,
                parent=parent_item.get("handle"),
                root=parent_item.get("root"),
                name=title,
                status_key=status_key,
                import_key=import_key,
                layout=layout,
            )
            handle = item.get("handle")
            created = time.strftime(FMT_TIMESTAMP)
            write_nwd(target, handle, parent_item.get("handle"), class_name, layout, title, body, created)
            chars, words, paras = word_counts(body)
            meta = item.find("meta")
            meta.set("charCount", str(chars))
            meta.set("wordCount", str(words))
            meta.set("paraCount", str(paras))
            added += 1

        new_hash = hashlib.sha1((body.strip("\n") + "\n").encode("utf-8")).hexdigest()
        cache[rel] = {"handle": handle, "created": created, "hash": new_hash}

    # Anything cached but no longer on disk moves to Trash instead of being deleted.
    trashed = 0
    stale_rels = [rel for rel in cache if rel not in seen_rel]
    if stale_rels:
        trash_root = find_trash_root(content)
        if trash_root is None:
            trash_root = make_item(
                content, handles, item_type="ROOT", class_name="TRASH", parent=None,
                root="", name="Trash", status_key=status_key, import_key=import_key,
            )
            trash_root.set("root", trash_root.get("handle"))
        for rel in stale_rels:
            handle = cache[rel]["handle"]
            item = find_item(content, handle)
            if item is not None and item.get("parent") != trash_root.get("handle"):
                item.set("parent", trash_root.get("handle"))
                item.set("root", trash_root.get("handle"))
                item.set("order", str(next_order(content, trash_root.get("handle"))))
                trashed += 1
            del cache[rel]

    pruned = prune_empty_synced_folders(content)
    content.set("items", str(len(content.findall("item"))))

    ET.indent(tree, space="  ")
    tree.write(target / "nwProject.nwx", encoding="utf-8", xml_declaration=True)
    save_handle_cache(project_dir, cache)

    print(
        f"done: {added} added, {updated} updated, {moved} moved to a corrected folder, "
        f"{unchanged} unchanged, {trashed} moved to trash, {pruned} empty folders pruned"
    )
    print("meta/ (sessions, index, options) left untouched.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
