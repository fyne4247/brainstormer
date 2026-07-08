#!/bin/sh
# Install the auto-flatten post-commit hook into every subproject git repo.
#
# Points each subproject's core.hooksPath at the shared hooks directory, so a
# commit in any project auto-regenerates that project's flattened snapshot at the
# workspace root (see scripts/git-hooks/post-commit).
#
# Run once from anywhere; re-run after adding a new project. Idempotent.
#
#     sh scripts/install-flatten-hook.sh

set -e
workspace="$(cd "$(dirname "$0")/.." && pwd)"
hooks="$workspace/scripts/git-hooks"

chmod +x "$hooks/post-commit"

found=0
for dir in "$workspace"/*/; do
  # A standalone repo has a .git directory; skip non-repo folders.
  if [ -d "$dir.git" ]; then
    git -C "$dir" config core.hooksPath "$hooks"
    echo "hooked: $(basename "$dir")"
    found=1
  fi
done

[ "$found" -eq 1 ] || echo "no subproject git repos found under $workspace"
