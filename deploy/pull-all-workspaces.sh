#!/usr/bin/env bash
set -euo pipefail

WORKSPACES=(
  /root/.openclaw/workspace
  /root/.openclaw/workspace-interviewer
  /root/.openclaw/workspace-resume-intake
)

for repo in "${WORKSPACES[@]}"; do
  if [[ -d "$repo/.git" ]]; then
    branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)
    echo "[pull] $repo ($branch)"
    git -C "$repo" fetch --all --prune
    git -C "$repo" checkout "$branch"
    git -C "$repo" pull --ff-only origin "$branch"
  else
    echo "[skip] not a git repo: $repo"
  fi
done

sudo systemctl restart openclaw
sudo systemctl --no-pager --full status openclaw -n 20 || true
