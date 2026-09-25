#!/usr/bin/env bash
# Install strip-coauthor as a git hook.
#
# Usage:
#   bash install.sh             # install into the current repo (.git/hooks)
#   bash install.sh --global    # install as the global pre-push hook
#                               # (chains any existing repo-local pre-push)
#
# The global install sets core.hooksPath to a new directory and copies the
# hook there.  If core.hooksPath already points somewhere, the script adds
# strip-coauthor as the first step in that directory's pre-push and leaves
# everything else alone.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SRC="$SCRIPT_DIR/pre-push"

GLOBAL=0
if [[ "${1:-}" == "--global" ]]; then
  GLOBAL=1
fi

if [[ "$GLOBAL" -eq 1 ]]; then
  EXISTING="$(git config --global core.hooksPath || true)"
  if [[ -n "$EXISTING" ]]; then
    TARGET_DIR="$EXISTING"
    echo "Using existing core.hooksPath: $TARGET_DIR"
  else
    TARGET_DIR="$HOME/.config/git/hooks"
    mkdir -p "$TARGET_DIR"
    git config --global core.hooksPath "$TARGET_DIR"
    echo "Set core.hooksPath → $TARGET_DIR"
  fi
  cp "$HOOK_SRC" "$TARGET_DIR/pre-push"
  chmod +x "$TARGET_DIR/pre-push"
  echo "Installed: $TARGET_DIR/pre-push"
else
  GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || {
    echo "Not inside a git repository." >&2; exit 1
  }
  TARGET_DIR="$GITDIR/hooks"
  mkdir -p "$TARGET_DIR"
  cp "$HOOK_SRC" "$TARGET_DIR/pre-push"
  chmod +x "$TARGET_DIR/pre-push"
  echo "Installed: $TARGET_DIR/pre-push"
fi
