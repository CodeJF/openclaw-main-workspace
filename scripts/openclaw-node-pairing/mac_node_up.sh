#!/usr/bin/env bash
set -euo pipefail

# 一键拉起：SSH 本地转发 + openclaw node run
# 关闭时请用配套脚本 mac_node_down.sh

CLOUD_HOST="${CLOUD_HOST:-47.119.177.99}"
CLOUD_USER="${CLOUD_USER:-root}"
SSH_KEY="${SSH_KEY:-/Users/jianfengxu/Downloads/has_jianfeng_key.pem}"
LOCAL_FORWARD_PORT="${LOCAL_FORWARD_PORT:-18790}"
REMOTE_GATEWAY_PORT="${REMOTE_GATEWAY_PORT:-18789}"
LOCAL_NODE_DISPLAY_NAME="${LOCAL_NODE_DISPLAY_NAME:-Master-Mac}"
GATEWAY_TOKEN="${GATEWAY_TOKEN:-187b27425dd1fa98fc20ab762d7c00da6a38d1b7b7de90b4}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IDENTITY_FILE="${IDENTITY_FILE:-$SCRIPT_DIR/mac_node_identity.env}"
NODE_ID="${NODE_ID:-}"
STATE_DIR="$HOME/.openclaw-node-pairing"

if [[ -f "$IDENTITY_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$IDENTITY_FILE"
fi

NODE_ID="${NODE_ID:-master-mac-node}"
LOCAL_NODE_DISPLAY_NAME="${DISPLAY_NAME:-$LOCAL_NODE_DISPLAY_NAME}"
SSH_PID_FILE="$STATE_DIR/ssh.pid"
NODE_PID_FILE="$STATE_DIR/node.pid"
NODE_LOG_FILE="$STATE_DIR/node.log"
SSH_LOG_FILE="$STATE_DIR/ssh.log"

mkdir -p "$STATE_DIR"

cleanup_existing() {
  if [[ -f "$SSH_PID_FILE" ]]; then
    old_pid="$(cat "$SSH_PID_FILE" 2>/dev/null || true)"
    if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
      echo "ℹ️ 结束旧 SSH 转发进程: $old_pid"
      kill "$old_pid" || true
      sleep 1
    fi
    rm -f "$SSH_PID_FILE"
  fi

  if [[ -f "$NODE_PID_FILE" ]]; then
    old_pid="$(cat "$NODE_PID_FILE" 2>/dev/null || true)"
    if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
      echo "ℹ️ 结束旧 node 进程: $old_pid"
      kill "$old_pid" || true
      sleep 1
    fi
    rm -f "$NODE_PID_FILE"
  fi

  lsof -tiTCP:"$LOCAL_FORWARD_PORT" -sTCP:LISTEN 2>/dev/null | xargs -r kill || true
}

cleanup_existing

echo "== 启动 SSH 本地转发 =="
ssh -f -N \
  -i "$SSH_KEY" \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -L "${LOCAL_FORWARD_PORT}:127.0.0.1:${REMOTE_GATEWAY_PORT}" \
  "${CLOUD_USER}@${CLOUD_HOST}" \
  >"$SSH_LOG_FILE" 2>&1

ssh_pid="$(pgrep -f "ssh.*${LOCAL_FORWARD_PORT}:127.0.0.1:${REMOTE_GATEWAY_PORT}.*${CLOUD_USER}@${CLOUD_HOST}" | head -n1 || true)"
if [[ -z "$ssh_pid" ]]; then
  echo "❌ SSH 本地转发启动失败，查看日志: $SSH_LOG_FILE" >&2
  exit 1
fi
echo "$ssh_pid" > "$SSH_PID_FILE"
echo "✅ SSH 转发已启动，PID=$ssh_pid"

echo
echo "== 启动 OpenClaw node =="
nohup env OPENCLAW_GATEWAY_TOKEN="$GATEWAY_TOKEN" \
  openclaw node run \
    --host 127.0.0.1 \
    --port "$LOCAL_FORWARD_PORT" \
    --node-id "$NODE_ID" \
    --display-name "$LOCAL_NODE_DISPLAY_NAME" \
  >"$NODE_LOG_FILE" 2>&1 &

node_pid=$!
echo "$node_pid" > "$NODE_PID_FILE"
sleep 2

if ! kill -0 "$node_pid" 2>/dev/null; then
  echo "❌ node 进程启动失败，查看日志: $NODE_LOG_FILE" >&2
  exit 1
fi

echo "✅ OpenClaw node 已启动，PID=$node_pid"
echo
echo "状态文件目录: $STATE_DIR"
echo "- SSH PID:  $SSH_PID_FILE"
echo "- Node PID: $NODE_PID_FILE"
echo "- SSH 日志: $SSH_LOG_FILE"
echo "- Node 日志: $NODE_LOG_FILE"
echo
echo "查看 node 日志：tail -f $NODE_LOG_FILE"
echo "关闭整套连接：bash /Users/jianfengxu/.openclaw/workspace/scripts/openclaw-node-pairing/mac_node_down.sh"
