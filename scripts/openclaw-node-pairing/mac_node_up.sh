#!/usr/bin/env bash
set -euo pipefail

# 只拉起本地 OpenClaw node 服务（不处理 gateway，不处理 SSH）

LABEL="ai.openclaw.node"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
STATE_DIR="$HOME/.openclaw-node-pairing"
NODE_PID_FILE="$STATE_DIR/node.pid"
NODE_LOG_FILE="$STATE_DIR/node.log"

mkdir -p "$STATE_DIR"

if [[ ! -f "$PLIST" ]]; then
  echo "❌ 未找到 LaunchAgent: $PLIST" >&2
  echo "先确认 node 服务已安装；可用 openclaw status 查看 Node service 状态。" >&2
  exit 1
fi

echo "== 启动 OpenClaw node 服务 =="

launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
sleep 1
launchctl bootstrap "gui/$UID" "$PLIST"
launchctl kickstart -k "gui/$UID/$LABEL"
sleep 2

node_pid="$(pgrep -f '/opt/homebrew/lib/node_modules/openclaw/dist/index.js node run' | head -n1 || true)"
if [[ -n "$node_pid" ]]; then
  echo "$node_pid" > "$NODE_PID_FILE"
fi

if ! launchctl list | grep -q "$LABEL"; then
  echo "❌ OpenClaw node 服务启动失败" >&2
  exit 1
fi

echo "✅ OpenClaw node 已启动"
if [[ -n "$node_pid" ]]; then
  echo "PID: $node_pid"
fi

echo "日志可查看：tail -f /tmp/openclaw/openclaw-$(date +%F).log"
[[ -f "$NODE_LOG_FILE" ]] && echo "历史日志文件：$NODE_LOG_FILE"
