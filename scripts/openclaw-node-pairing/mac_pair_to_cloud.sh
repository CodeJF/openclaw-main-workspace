#!/usr/bin/env bash
set -euo pipefail

# mac_pair_to_cloud.sh
# 用途：在本地 macOS 上建立到云端 OpenClaw Gateway 的 SSH 本地转发，
# 然后让本地 OpenClaw node 通过本机 127.0.0.1:18790 去连接云端 Gateway。
#
# 正确拓扑：
#   本地 127.0.0.1:18790 --SSH本地转发--> 云端 127.0.0.1:18789 (OpenClaw Gateway)
#   本地 openclaw node run --host 127.0.0.1 --port 18790

CLOUD_HOST="${CLOUD_HOST:-47.119.177.99}"
CLOUD_USER="${CLOUD_USER:-root}"
SSH_KEY="${SSH_KEY:-/Users/jianfengxu/Downloads/has_jianfeng_key.pem}"
LOCAL_FORWARD_PORT="${LOCAL_FORWARD_PORT:-18790}"
REMOTE_GATEWAY_PORT="${REMOTE_GATEWAY_PORT:-18789}"
LOCAL_NODE_DISPLAY_NAME="${LOCAL_NODE_DISPLAY_NAME:-Master-Mac}"
GATEWAY_TOKEN="${GATEWAY_TOKEN:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IDENTITY_FILE="${IDENTITY_FILE:-$SCRIPT_DIR/mac_node_identity.env}"
NODE_ID="${NODE_ID:-}"

if [[ -f "$IDENTITY_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$IDENTITY_FILE"
fi

NODE_ID="${NODE_ID:-master-mac-node}"
LOCAL_NODE_DISPLAY_NAME="${DISPLAY_NAME:-$LOCAL_NODE_DISPLAY_NAME}"

if ! command -v openclaw >/dev/null 2>&1; then
  echo "❌ 未找到 openclaw 命令，请先在本机安装 OpenClaw" >&2
  exit 1
fi

if ! command -v ssh >/dev/null 2>&1; then
  echo "❌ 未找到 ssh 命令" >&2
  exit 1
fi

if [[ -z "$GATEWAY_TOKEN" ]]; then
  echo "❌ 缺少 GATEWAY_TOKEN。先在云端执行 scripts/openclaw-node-pairing/cloud_show_token.sh 获取 token：" >&2
  echo "   GATEWAY_TOKEN=xxxx bash $0" >&2
  exit 1
fi

echo "== 本地环境检查 =="
openclaw --version || true

echo
echo "== 建立 SSH 本地转发 =="
echo "本地 127.0.0.1:${LOCAL_FORWARD_PORT} -> 云端 127.0.0.1:${REMOTE_GATEWAY_PORT}"
ssh -f -N \
  -i "$SSH_KEY" \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -L "${LOCAL_FORWARD_PORT}:127.0.0.1:${REMOTE_GATEWAY_PORT}" \
  "${CLOUD_USER}@${CLOUD_HOST}"

echo
echo "== 检查本地转发端口 =="
if command -v nc >/dev/null 2>&1; then
  nc -z 127.0.0.1 "$LOCAL_FORWARD_PORT"
  echo "✅ 本地转发端口 127.0.0.1:${LOCAL_FORWARD_PORT} 可连接"
else
  echo "ℹ️ 未找到 nc，跳过端口探测"
fi

echo
echo "== 前台启动本地 node 连接云端 Gateway =="
echo "按 Ctrl+C 可停止该 node 进程；SSH 本地转发保持后台运行。"
echo
OPENCLAW_GATEWAY_TOKEN="$GATEWAY_TOKEN" \
openclaw node run \
  --host 127.0.0.1 \
  --port "$LOCAL_FORWARD_PORT" \
  --node-id "$NODE_ID" \
  --display-name "$LOCAL_NODE_DISPLAY_NAME"
