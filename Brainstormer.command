#!/bin/bash

# Launcher for the Brainstormer creative-writing workspace.
# Double-click this file in Finder to start a muse session.
# (First time only: see the README for how to make it double-clickable.)

set -e

# Always run from the folder this script lives in, no matter where it's
# double-clicked from or symlinked to.
cd "$(cd "$(dirname "$0")" && pwd)"

echo "Brainstormer workspace: $(pwd)"
echo ""

# --- Auto-export check -----------------------------------------------------
# Saving a project can auto-refresh its snapshot in exports/, but that only
# works if git has been told (per-project, per-machine) to run the export
# script after each save. That instruction lives in local git config, which
# is NOT part of the repo files — so a fresh `git clone` never has it set,
# even though the export script itself did come along. Check for it here and
# offer to set it up in one step rather than making you track this down.
HOOKS_DIR="$(pwd)/scripts/git-hooks"
SKIP_FILE=".brainstormer-hooks-declined"
touch "$SKIP_FILE"

NOT_WIRED=()
for dir in */; do
  name="${dir%/}"
  [ -d "$name/.git" ] || continue
  grep -qxF "$name" "$SKIP_FILE" && continue
  current="$(git -C "$name" config --get core.hooksPath || true)"
  [ "$current" = "$HOOKS_DIR" ] || NOT_WIRED+=("$name")
done

if [ "${#NOT_WIRED[@]}" -gt 0 ]; then
  echo "Auto-export isn't set up yet for: ${NOT_WIRED[*]}"
  echo "(Nothing is broken — saving still works fine. This just means the"
  echo " exports/ snapshot for those projects won't auto-refresh until this"
  echo " is wired up. It's a one-time local setting, no downloads.)"
  read -r -p "Set it up now? [Y/n, or 'never' to stop asking] " FIX_HOOKS
  case "$FIX_HOOKS" in
    [Nn]*) : ;;
    never|Never|NEVER)
      printf '%s\n' "${NOT_WIRED[@]}" >>"$SKIP_FILE"
      echo "Won't ask again for: ${NOT_WIRED[*]} (delete $SKIP_FILE to reset)"
      ;;
    *) sh scripts/install-flatten-hook.sh ;;
  esac
  echo ""
fi

# --- Model ---------------------------------------------------------------
echo "Model? (opus / sonnet / fable / haiku, or press Enter for default)"
read -r -p "> " MODEL

# --- Effort ----------------------------------------------------------------
echo ""
echo "Effort? (low / medium / high / xhigh / max, or press Enter for default)"
read -r -p "> " EFFORT

# --- Project ---------------------------------------------------------------
# List subfolders that look like writing projects (have their own CLAUDE.md),
# skipping the shared workspace machinery.
PROJECTS=()
for dir in */; do
  name="${dir%/}"
  case "$name" in
    .claude|scripts|docs|exports) continue ;;
  esac
  [ -f "$name/CLAUDE.md" ] && PROJECTS+=("$name")
done

PROJECT=""
if [ "${#PROJECTS[@]}" -gt 0 ]; then
  echo ""
  echo "Which project?"
  echo "  0) let muse ask / not sure yet"
  i=1
  for p in "${PROJECTS[@]}"; do
    echo "  $i) $p"
    i=$((i + 1))
  done
  read -r -p "> " CHOICE
  if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#PROJECTS[@]}" ]; then
    PROJECT="${PROJECTS[$((CHOICE - 1))]}"
  fi
fi

# --- Build the command -----------------------------------------------------
ARGS=(--agent muse)
[ -n "$MODEL" ] && ARGS+=(--model "$MODEL")
[ -n "$EFFORT" ] && ARGS+=(--effort "$EFFORT")

echo ""
if [ -n "$PROJECT" ]; then
  echo "Starting muse on project: $PROJECT"
  claude "${ARGS[@]}" "I'd like to work on the \"$PROJECT\" project. Please read $PROJECT/CLAUDE.md and its kb/ before we start."
else
  echo "Starting muse..."
  claude "${ARGS[@]}"
fi

# Keep the terminal window open after the session ends.
echo ""
echo "Session ended. Press Enter to close this window..."
read -r
