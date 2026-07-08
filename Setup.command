#!/bin/bash
# Setup.command — one-time installer wizard for the Brainstormer workspace (macOS)
#
# First run: either double-click and choose "Open" when macOS warns about an
# unidentified developer, or run `sh Setup.command` from Terminal. Either way
# works even before this file is executable — this script chmods itself and
# the launcher at the end so future double-clicks just work.

cd "$(dirname "$0")" || exit 1

BOLD=$(tput bold 2>/dev/null); DIM=$(tput dim 2>/dev/null); RESET=$(tput sgr0 2>/dev/null)
GREEN=$(tput setaf 2 2>/dev/null); YELLOW=$(tput setaf 3 2>/dev/null); RED=$(tput setaf 1 2>/dev/null)

say()   { printf "%s\n" "$1"; }
ok()    { printf "  %s✓ %s%s\n" "$GREEN" "$1" "$RESET"; }
warn()  { printf "  %s! %s%s\n" "$YELLOW" "$1" "$RESET"; }
err()   { printf "  %s✗ %s%s\n" "$RED" "$1" "$RESET"; }

ask_yn() {
  # ask_yn "question" "y|n"(default) -> returns 0 for yes, 1 for no
  local prompt="$1" default="${2:-y}" reply
  if [ "$default" = "y" ]; then
    read -r -p "$prompt [Y/n] " reply
    [ -z "$reply" ] && reply=y
  else
    read -r -p "$prompt [y/N] " reply
    [ -z "$reply" ] && reply=n
  fi
  case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

echo ""
echo "${BOLD}Brainstormer workspace — setup wizard (macOS)${RESET}"
echo "This checks for the tools this workspace uses and offers to install"
echo "anything missing. Nothing is installed without you saying yes."
echo ""

HAVE_BREW=0
command -v brew >/dev/null 2>&1 && HAVE_BREW=1

echo "${BOLD}── Homebrew ──${RESET}"
echo ""
echo "Homebrew — a package manager for macOS. Not required by anything in this"
echo "workspace directly, but it's the easiest way for this script to install"
echo "git, Python, and pandoc for you below, and to keep them updated later."
echo "Skip it and this script falls back to Apple's own installers instead."
if [ "$HAVE_BREW" = "1" ]; then
  ok "Homebrew is already installed ($(brew --version | head -n1))"
else
  warn "Homebrew was not found."
  if ask_yn "Install Homebrew now?" n; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if command -v brew >/dev/null 2>&1; then
      HAVE_BREW=1
      ok "Homebrew installed."
    else
      warn "Homebrew installed, but isn't on PATH in this session yet."
      warn "Follow the 'Next steps' it printed above (usually adding it to your"
      warn "shell profile), then open a new terminal and re-run this script so"
      warn "the git/Python/pandoc steps below can use it."
    fi
  else
    say "  Skipping — git will use Apple's installer, Python/pandoc will link to manual downloads."
  fi
fi
echo ""

echo "${BOLD}── Required ──${RESET}"
echo ""

# ---- git ----
echo "git — version control. Every project in this workspace is its own git"
echo "repo; saving progress and the auto-export snapshots both depend on it."
if command -v git >/dev/null 2>&1; then
  ok "git is already installed ($(git --version))"
else
  warn "git was not found."
  if ask_yn "Install git now?"; then
    if [ "$HAVE_BREW" = "1" ]; then
      brew install git && ok "git installed."
    else
      echo "  Launching Apple's Command Line Tools installer (includes git)..."
      xcode-select --install 2>/dev/null
      echo "  A separate window should have opened. Finish that install, then"
      echo "  re-run this Setup script to continue (or just run it again anytime)."
    fi
  else
    err "Skipping git. The workspace's save/export features won't work without it."
  fi
fi
echo ""

# ---- Claude Code ----
echo "Claude Code — the CLI this whole workspace runs on (claude --agent muse)."
if command -v claude >/dev/null 2>&1; then
  ok "Claude Code is already installed ($(claude --version 2>/dev/null))"
else
  warn "Claude Code was not found."
  if ask_yn "Install Claude Code now?"; then
    curl -fsSL https://claude.ai/install.sh | bash
    if command -v claude >/dev/null 2>&1; then
      ok "Claude Code installed."
    else
      warn "Installed, but 'claude' isn't on PATH yet in this session."
      warn "Open a new terminal window and it should be available."
    fi
  else
    err "Skipping Claude Code. Nothing else in this workspace will run without it."
  fi
fi
echo ""

echo "${BOLD}── Optional ──${RESET}"
echo ""

# ---- Python 3 ----
echo "Python 3 — only used for the auto-export snapshots (scripts/flatten_project.py),"
echo "which turn each project's kb/ into one combined exports/<project>.md file"
echo "after every save. Everything else in the workspace works fine without it."
if command -v python3 >/dev/null 2>&1; then
  ok "Python 3 is already installed ($(python3 --version 2>&1))"
else
  if ask_yn "Install Python 3?" n; then
    if [ "$HAVE_BREW" = "1" ]; then
      brew install python3 && ok "Python 3 installed."
    else
      warn "No Homebrew available. Download Python 3 from https://python.org/downloads"
      warn "and re-run this script afterward if you'd like it confirmed."
    fi
  else
    say "  Skipping — you just won't get exports/*.md snapshots after saves."
  fi
fi
echo ""

# ---- pandoc ----
echo "pandoc — only used by /setup when you point it at writing samples that"
echo "aren't plain text (.docx, .rtf, .odt), so it can convert them for the"
echo "style-reference kb. If you only ever use .txt/.md samples, skip this."
if command -v pandoc >/dev/null 2>&1; then
  ok "pandoc is already installed ($(pandoc --version 2>&1 | head -n1))"
else
  if ask_yn "Install pandoc?" n; then
    if [ "$HAVE_BREW" = "1" ]; then
      brew install pandoc && ok "pandoc installed."
    else
      warn "No Homebrew available. Download pandoc from https://pandoc.org/installing.html"
      warn "and re-run this script afterward if you'd like it confirmed."
    fi
  else
    say "  Skipping — /setup will just ask for plain-text exports of any samples instead."
  fi
fi
echo ""

# ---- make launcher double-clickable ----
echo "${BOLD}── Finishing up ──${RESET}"
echo ""
chmod +x "Setup.command" 2>/dev/null
if [ -f "brainstormer.command" ]; then
  chmod +x "brainstormer.command"
  ok "Made brainstormer.command double-clickable."
else
  warn "Didn't find brainstormer.command next to this script — skipping that step."
fi
echo ""
echo "${BOLD}All done.${RESET} Double-click brainstormer.command to start writing."
echo ""
read -r -p "Press Enter to close this window... " _
