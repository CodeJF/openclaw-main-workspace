#!/usr/bin/env bash
set -euo pipefail

# 一键关闭：停止 openclaw node run + SSH 本地转发

STATE_DIR="$HOME/.openclaw-node-pairing"
SSH_PID_FILE="$STATE_DIR/ssh.pid"
NODE_PID_FILE="$STATE_DIR/node.pid"

kill_from_pidfile() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    local pid
    pid="$(cat "$file" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "结束 ${label} 进程: $pid"
      kill "$pid" || true
      sleep 1
    fi
    rm -f "$file"
  fi
}

kill_from_pidfile "$NODE_PID_FILE" "node"
kill_from_pidfile "$SSH_PID_FILE" "ssh"

# 兜底清理
pkill -f 'openclaw node run --host 127.0.0.1' || true
pkill -f 'ssh.*127.0.0.1:18789' || true

echo "✅ 已关闭本地 OpenClaw node + SSH 转发"
