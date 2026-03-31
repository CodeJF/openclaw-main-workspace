#!/usr/bin/env bash
set -euo pipefail

# 只拉起本地 OpenClaw node 服务（不处理 gateway，不处理 SSH）
# 如果 stop 时禁用了 LaunchAgent，这里会自动恢复 plist 后再启动。

LABEL="ai.openclaw.node"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
DISABLED_PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist.disabled"
STATE_DIR="$HOME/.openclaw-node-pairing"
NODE_PID_FILE="$STATE_DIR/node.pid"

mkdir -p "$STATE_DIR"

if [[ ! -f "$PLIST" && -f "$DISABLED_PLIST" ]]; then
  mv "$DISABLED_PLIST" "$PLIST"
  echo "ℹ️ 已恢复 LaunchAgent：$PLIST"
fi

if [[ ! -f "$PLIST" ]]; then
  echo "❌ 未找到 LaunchAgent: $PLIST" >&2
  echo "先确认 node 服务已安装；可用 openclaw status 查看 Node service 状态。" >&2
  exit 1
fi

echo "== 启动 OpenClaw node 服务 =="

launchctl print "gui/$UID/$LABEL" >/dev/null 2>&1 && \
  launchctl bootout "gui/$UID/$LABEL" 2>/dev/null || true
sleep 1
launchctl bootstrap "gui/$UID" "$PLIST" 2>/dev/null || true
launchctl kickstart -k "gui/$UID/$LABEL" 2>/dev/null || true
sleep 2

node_pid="$(pgrep -f '/opt/homebrew/lib/node_modules/openclaw/dist/index.js node run' | head -n1 || true)"
if [[ -n "$node_pid" ]]; then
  echo "$node_pid" > "$NODE_PID_FILE"
fi

echo "✅ 已向 launchd 发起 OpenClaw node 启动请求"
[[ -n "$node_pid" ]] && echo "当前检测到 PID: $node_pid"
echo "状态检查：launchctl print gui/$UID/$LABEL"
echo "进程检查：pgrep -fal 'openclaw/dist/index.js node run'"
echo "如果日志里出现 pairing required，说明 node 已启动，但当前还未完成配对授权。"
