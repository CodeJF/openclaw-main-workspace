#!/usr/bin/env bash
set -euo pipefail

# Server-side helper for Alibaba Cloud OpenClaw.
# Canonical workflow: local macOS edits/pushes, server only pulls.

WORKSPACES=(
  /root/.openclaw/workspace
  /root/.openclaw/workspace-interviewer
  /root/.openclaw/workspace-resume-intake
)

for repo in "${WORKSPACES[@]}"; do
  if [[ -d "$repo/.git" ]]; then
    branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)
    if [[ "$branch" == "HEAD" || -z "$branch" ]]; then
      branch=main
    fi
    echo "[pull] $repo ($branch)"
    git -C "$repo" fetch --all --prune
    git -C "$repo" checkout "$branch"
    git -C "$repo" pull --ff-only origin "$branch"
  else
    echo "[skip] not a git repo: $repo"
  fi
done

systemctl restart openclaw
systemctl --no-pager --full status openclaw -n 20 || true
