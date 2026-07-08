#!/bin/bash
# Setup.sh — one-time installer wizard for the Brainstormer workspace (Linux)
#
# First run: `sh Setup.sh` (or chmod +x Setup.sh && ./Setup.sh). It chmods
# itself and brainstormer.sh at the end so future runs are a plain double-run.

cd "$(dirname "$0")" || exit 1

BOLD=$(tput bold 2>/dev/null); RESET=$(tput sgr0 2>/dev/null)
GREEN=$(tput setaf 2 2>/dev/null); YELLOW=$(tput setaf 3 2>/dev/null); RED=$(tput setaf 1 2>/dev/null)

ok()    { printf "  %s✓ %s%s\n" "$GREEN" "$1" "$RESET"; }
warn()  { printf "  %s! %s%s\n" "$YELLOW" "$1" "$RESET"; }
err()   { printf "  %s✗ %s%s\n" "$RED" "$1" "$RESET"; }

ask_yn() {
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

# Figure out the package manager once, up front.
PM=""
if command -v apt-get >/dev/null 2>&1; then PM="apt"
elif command -v dnf >/dev/null 2>&1; then PM="dnf"
elif command -v pacman >/dev/null 2>&1; then PM="pacman"
elif command -v apk >/dev/null 2>&1; then PM="apk"
fi

SUDO=""
if [ "$(id -u)" != "0" ]; then
  if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi
fi

install_pkg() {
  # install_pkg <package-name>
  case "$PM" in
    apt)    $SUDO apt-get update -y && $SUDO apt-get install -y "$1" ;;
    dnf)    $SUDO dnf install -y "$1" ;;
    pacman) $SUDO pacman -Sy --noconfirm "$1" ;;
    apk)    $SUDO apk add "$1" ;;
    *)      return 1 ;;
  esac
}

echo ""
echo "${BOLD}Brainstormer workspace — setup wizard (Linux)${RESET}"
echo "This checks for the tools this workspace uses and offers to install"
echo "anything missing. Nothing is installed without you saying yes."
if [ -z "$PM" ]; then
  warn "Couldn't detect apt, dnf, pacman, or apk on this system."
  warn "Install commands below may not work automatically — manual links given as a fallback."
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
    if install_pkg git; then
      ok "git installed."
    else
      err "Couldn't install automatically. See https://git-scm.com/download/linux"
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
      warn "Open a new terminal (or run: source ~/.bashrc) and it should be available."
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
    if install_pkg python3; then
      ok "Python 3 installed."
    else
      warn "Couldn't install automatically. See https://python.org/downloads"
    fi
  else
    echo "  Skipping — you just won't get exports/*.md snapshots after saves."
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
    if install_pkg pandoc; then
      ok "pandoc installed."
    else
      warn "Couldn't install automatically. See https://pandoc.org/installing.html"
    fi
  else
    echo "  Skipping — /setup will just ask for plain-text exports of any samples instead."
  fi
fi
echo ""

# ---- make launcher runnable ----
echo "${BOLD}── Finishing up ──${RESET}"
echo ""
chmod +x "Setup.sh" 2>/dev/null
if [ -f "brainstormer.sh" ]; then
  chmod +x "brainstormer.sh"
  ok "Made brainstormer.sh executable."
else
  warn "Didn't find brainstormer.sh next to this script — skipping that step."
fi
echo ""
echo "${BOLD}All done.${RESET} Run ./brainstormer.sh to start writing."
echo ""
