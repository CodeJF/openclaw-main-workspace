#!/usr/bin/env bash
set -euo pipefail

# 只关闭本地 OpenClaw node 服务（不处理 gateway，不处理 SSH）

LABEL="ai.openclaw.node"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
STATE_DIR="$HOME/.openclaw-node-pairing"
NODE_PID_FILE="$STATE_DIR/node.pid"

mkdir -p "$STATE_DIR"

echo "== 停止 OpenClaw node 服务 =="

if launchctl list | grep -q "$LABEL"; then
  launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || launchctl bootout "gui/$UID" "$PLIST" 2>/dev/null || true
  sleep 1
fi

pkill -f '/opt/homebrew/lib/node_modules/openclaw/dist/index.js node run' 2>/dev/null || true
pkill -f 'openclaw node run' 2>/dev/null || true
rm -f "$NODE_PID_FILE"

if launchctl list | grep -q "$LABEL"; then
  echo "⚠️  Node 服务仍在列表中，建议再执行一次检查：launchctl list | grep openclaw"
else
  echo "✅ 已停止本地 OpenClaw node"
fi
