#!/usr/bin/env bash
set -euo pipefail

# 只关闭本地 OpenClaw node 服务（不处理 gateway，不处理 SSH）
# 为了防止 launchd KeepAlive 自动拉起，会临时禁用 LaunchAgent plist。

LABEL="ai.openclaw.node"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
DISABLED_PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist.disabled"
STATE_DIR="$HOME/.openclaw-node-pairing"
NODE_PID_FILE="$STATE_DIR/node.pid"

mkdir -p "$STATE_DIR"

echo "== 停止 OpenClaw node 服务 =="

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || launchctl bootout "gui/$UID" "$PLIST" 2>/dev/null || true
sleep 1
pkill -f '/opt/homebrew/lib/node_modules/openclaw/dist/index.js node run' 2>/dev/null || true
pkill -f 'openclaw node run' 2>/dev/null || true
rm -f "$NODE_PID_FILE"

if [[ -f "$PLIST" ]]; then
  mv "$PLIST" "$DISABLED_PLIST"
  echo "ℹ️ 已临时禁用 LaunchAgent：$DISABLED_PLIST"
fi

echo "✅ 已停止本地 OpenClaw node，并禁用自动拉起"
