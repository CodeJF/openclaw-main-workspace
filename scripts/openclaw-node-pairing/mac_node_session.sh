#!/usr/bin/env bash
set -euo pipefail

# 交互式 node 会话：只启动本地 OpenClaw node，按回车结束时停止 node

LABEL="ai.openclaw.node"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
STATE_DIR="$HOME/.openclaw-node-pairing"
NODE_PID_FILE="$STATE_DIR/node.pid"

mkdir -p "$STATE_DIR"

if [[ ! -f "$PLIST" ]]; then
  echo "❌ 未找到 LaunchAgent: $PLIST" >&2
  exit 1
fi

cleanup() {
  echo ""
  echo "== 停止 OpenClaw node 服务 =="
  launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || launchctl bootout "gui/$UID" "$PLIST" 2>/dev/null || true
  pkill -f '/opt/homebrew/lib/node_modules/openclaw/dist/index.js node run' 2>/dev/null || true
  pkill -f 'openclaw node run' 2>/dev/null || true
  rm -f "$NODE_PID_FILE"
  echo "✅ OpenClaw node 已停止"
}

trap cleanup EXIT INT TERM

echo "OpenClaw macOS Node 本地会话"
echo "只处理 node；不处理 gateway；不处理 SSH。"
echo ""

echo "== 启动 OpenClaw node 服务 =="
launchctl print "gui/$UID/$LABEL" >/dev/null 2>&1 && \
  launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
sleep 1
launchctl bootstrap "gui/$UID" "$PLIST" 2>/dev/null || true
launchctl kickstart -k "gui/$UID/$LABEL"
sleep 2

if ! launchctl print "gui/$UID/$LABEL" >/dev/null 2>&1; then
  echo "❌ OpenClaw node 服务启动失败"
  exit 1
fi

node_pid="$(pgrep -f '/opt/homebrew/lib/node_modules/openclaw/dist/index.js node run' | head -n1 || true)"
if [[ -n "$node_pid" ]]; then
  echo "$node_pid" > "$NODE_PID_FILE"
  echo "✅ OpenClaw node 已启动 (PID: $node_pid)"
else
  echo "✅ OpenClaw node 服务已启动"
fi

echo "如日志里出现 pairing required，说明 node 已启动，但当前还未完成配对授权。"
echo ""
echo "按回车结束本次 node 会话，并自动停止 node。"
read -r _
