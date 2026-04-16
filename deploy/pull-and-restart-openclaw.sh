#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?repo dir required}"
BRANCH="${2:-$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)}"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "Not a git repo: $REPO_DIR" >&2
  exit 2
fi

cd "$REPO_DIR"
git fetch --all --prune
git checkout "$BRANCH"
git pull --ff-only origin "$BRANCH"
sudo systemctl restart openclaw
sudo systemctl --no-pager --full status openclaw -n 20 || true
