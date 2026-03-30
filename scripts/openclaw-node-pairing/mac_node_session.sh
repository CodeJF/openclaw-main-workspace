#!/usr/bin/env bash
set -euo pipefail

# 前台交互式会话：显示步骤进度，Ctrl+C 退出时自动清理 SSH 转发和 node 进程

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

info() { printf "%s\n" "$*"; }
step() { printf "◌ %s\n" "$*"; }
ok() { printf "✔ %s\n" "$*"; }
warn() { printf "! %s\n" "$*"; }

cleanup() {
  info ""
  step "清理本地进程..."

  if [[ -f "$NODE_PID_FILE" ]]; then
    pid="$(cat "$NODE_PID_FILE" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" || true
      ok "已停止 node 进程 ($pid)"
    fi
    rm -f "$NODE_PID_FILE"
  fi

  if [[ -f "$SSH_PID_FILE" ]]; then
    pid="$(cat "$SSH_PID_FILE" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" || true
      ok "已停止 SSH 转发 ($pid)"
    fi
    rm -f "$SSH_PID_FILE"
  fi

  pkill -f 'openclaw node run --host 127.0.0.1' || true
  pkill -f "ssh.*${LOCAL_FORWARD_PORT}:127.0.0.1:${REMOTE_GATEWAY_PORT}" || true
}

trap cleanup EXIT INT TERM

info "OpenClaw macOS Node 会话"
info "本地端口: 127.0.0.1:${LOCAL_FORWARD_PORT} -> 云端: 127.0.0.1:${REMOTE_GATEWAY_PORT}@${CLOUD_HOST}"
info "显示名: ${LOCAL_NODE_DISPLAY_NAME}"
info ""

step "检查云端 OpenClaw 服务..."
if ssh -i "$SSH_KEY" "$CLOUD_USER@$CLOUD_HOST" 'systemctl is-active openclaw.service >/dev/null 2>&1'; then
  ok "云端 OpenClaw 服务正常"
else
  warn "Gateway service not loaded."
fi

step "清理旧的本地端口占用..."
lsof -tiTCP:"$LOCAL_FORWARD_PORT" -sTCP:LISTEN 2>/dev/null | xargs -r kill || true
sleep 1
ok "本地端口已清理"

step "建立 SSH 隧道..."
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
  warn "SSH 隧道启动失败，日志: $SSH_LOG_FILE"
  exit 1
fi
echo "$ssh_pid" > "$SSH_PID_FILE"
ok "SSH 隧道已建立 ($ssh_pid)"

step "启动 OpenClaw node..."
nohup env OPENCLAW_GATEWAY_TOKEN="$GATEWAY_TOKEN" \
  openclaw node run \
    --host 127.0.0.1 \
    --port "$LOCAL_FORWARD_PORT" \
    --node-id "$NODE_ID" \
    --display-name "$LOCAL_NODE_DISPLAY_NAME" \
  >"$NODE_LOG_FILE" 2>&1 &

node_pid=$!
echo "$node_pid" > "$NODE_PID_FILE"
sleep 3

if ! kill -0 "$node_pid" 2>/dev/null; then
  warn "OpenClaw node 启动失败，日志: $NODE_LOG_FILE"
  exit 1
fi
ok "OpenClaw node 已启动 ($node_pid)"

info ""
info "日志文件："
info "- node: $NODE_LOG_FILE"
info "- ssh : $SSH_LOG_FILE"
info ""
info "现在保持此窗口打开。按 Ctrl+C 将自动停止 node 和 SSH 隧道。"
info ""

# 前台跟随日志，营造会话感
exec tail -f "$NODE_LOG_FILE"
