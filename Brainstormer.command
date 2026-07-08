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
echo "Model family?"
echo "  1) Opus"
echo "  2) Sonnet"
echo "  3) Haiku"
echo "  4) Fable"
echo "  0) Skip (use Claude Code's default)"
read -r -p "> " FAMILY_CHOICE

MODEL=""
case "$FAMILY_CHOICE" in
  1)
    echo ""
    echo "Which Opus version?"
    echo "  1) Opus 4.8 (current, recommended)"
    echo "  2) Opus 4.7"
    echo "  3) Opus 4.6"
    echo "  4) Opus 4.5"
    echo "  5) Opus 3 (retired -- still launches, shows a warning)"
    read -r -p "> " VERSION_CHOICE
    case "$VERSION_CHOICE" in
      1) MODEL="claude-opus-4-8" ;;
      2) MODEL="claude-opus-4-7" ;;
      3) MODEL="claude-opus-4-6" ;;
      4) MODEL="claude-opus-4-5" ;;
      5) MODEL="claude-opus-3" ;;
    esac
    ;;
  2)
    echo ""
    echo "Which Sonnet version?"
    echo "  1) Sonnet 5 (current, recommended)"
    echo "  2) Sonnet 4.6"
    echo "  3) Sonnet 4.5"
    echo "  4) Sonnet 4.0 (retired -- still launches, shows a warning)"
    read -r -p "> " VERSION_CHOICE
    case "$VERSION_CHOICE" in
      1) MODEL="claude-sonnet-5" ;;
      2) MODEL="claude-sonnet-4-6" ;;
      3) MODEL="claude-sonnet-4-5" ;;
      4) MODEL="claude-sonnet-4-0" ;;
    esac
    ;;
  3)
    MODEL="claude-haiku-4-5"
    ;;
  4)
    MODEL="claude-fable-5"
    ;;
esac

if [ -n "$MODEL" ]; then
  echo "Using model: $MODEL"
fi

# --- Effort ----------------------------------------------------------------
# Effort (adjustable reasoning depth) only exists on Fable 5, Sonnet 5,
# Opus 4.8, Opus 4.7, Opus 4.6, and Sonnet 4.6. Older/legacy models
# (Opus 4.5, Opus 3, Sonnet 4.5, Sonnet 4.0, Haiku) don't support it at
# all, so skip asking rather than offer a setting that won't apply.
# Leaving the model unset (skip) also supports effort -- Claude Code's
# own default lands on one of the supported models.
EFFORT_SUPPORTED=1
case "$MODEL" in
  claude-opus-4-8|claude-opus-4-7|claude-opus-4-6|claude-sonnet-5|claude-sonnet-4-6|claude-fable-5|"") ;;
  *) EFFORT_SUPPORTED=0 ;;
esac

EFFORT=""
if [ "$EFFORT_SUPPORTED" -eq 1 ]; then
  echo ""
  echo "Effort? (how much the model thinks before responding)"
  echo "  1) low"
  echo "  2) medium"
  echo "  3) high"
  echo "  4) xhigh"
  echo "  5) max"
  echo "  0) Skip (use default)"
  read -r -p "> " EFFORT_CHOICE

  case "$EFFORT_CHOICE" in
    1) EFFORT="low" ;;
    2) EFFORT="medium" ;;
    3) EFFORT="high" ;;
    4) EFFORT="xhigh" ;;
    5) EFFORT="max" ;;
  esac
else
  echo ""
  echo "(Effort isn't adjustable on $MODEL -- skipping that question.)"
fi

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
  claude "${ARGS[@]}" "I'd like to work on the \"$PROJECT\" project. Please read $PROJECT/CLAUDE.md and exports/$PROJECT.ai.md before we start."
else
  echo "Starting muse..."
  claude "${ARGS[@]}"
fi

# --- Ask to save any unsaved progress --------------------------------------
# The claude session has already ended by this point, so there's no model
# available to write a natural-language commit message -- this is a safety
# net (a plain timestamped commit), not a substitute for a real /save.
echo ""
for dir in */; do
  name="${dir%/}"
  [ -d "$name/.git" ] || continue
  [ -n "$(git -C "$name" status --porcelain 2>/dev/null)" ] || continue
  read -r -p "Save progress on \"$name\"? [Y/n] " SAVE_ANSWER
  case "$SAVE_ANSWER" in
    [Nn]*) : ;;
    *)
      git -C "$name" add -A
      git -C "$name" commit -m "Progress saved -- $(date '+%Y-%m-%d %H:%M')" >/dev/null
      echo "Saved \"$name\"."
      ;;
  esac
done

# Keep the terminal window open after the session ends.
echo ""
echo "Session ended. Press Enter to close this window..."
read -r
