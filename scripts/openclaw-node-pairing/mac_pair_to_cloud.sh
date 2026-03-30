#!/usr/bin/env bash
set -euo pipefail

# mac_pair_to_cloud.sh
# 用途：在本地 macOS 上启动 OpenClaw node，并通过 SSH 反向隧道暴露给云端 OpenClaw Gateway。
#
# 默认拓扑：
#   cloud gateway (47.119.177.99) --connects--> 127.0.0.1:18790 on cloud
#   该端口由本机 SSH 反向隧道转发到 macOS 上本地 node host 监听端口（默认 18791）
#
# 使用前：
#   1) 先在云端拿到 GATEWAY_TOKEN
#   2) 确保本机已安装 openclaw CLI
#   3) 确保 SSH key 可用

CLOUD_HOST="${CLOUD_HOST:-47.119.177.99}"
CLOUD_USER="${CLOUD_USER:-root}"
SSH_KEY="${SSH_KEY:-/Users/jianfengxu/Downloads/has_jianfeng_key.pem}"
CLOUD_TUNNEL_PORT="${CLOUD_TUNNEL_PORT:-18790}"
LOCAL_NODE_PORT="${LOCAL_NODE_PORT:-18791}"
LOCAL_NODE_DISPLAY_NAME="${LOCAL_NODE_DISPLAY_NAME:-macOS-node}"
GATEWAY_TOKEN="${GATEWAY_TOKEN:-}"

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
echo "== 启动/重启本地 OpenClaw node host 服务 =="
openclaw node install || true
openclaw node restart || openclaw node install
sleep 2
openclaw node status || true

echo
echo "== 通过 SSH 建立反向隧道 =="
echo "云端 127.0.0.1:${CLOUD_TUNNEL_PORT} -> 本地 127.0.0.1:${LOCAL_NODE_PORT}"
ssh -f -N \
  -i "$SSH_KEY" \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -R "${CLOUD_TUNNEL_PORT}:127.0.0.1:${LOCAL_NODE_PORT}" \
  "${CLOUD_USER}@${CLOUD_HOST}"

echo
echo "== 前台启动本地 node 连接到云端隧道入口 =="
echo "按 Ctrl+C 可停止该 node 进程；SSH 隧道保持后台运行。"
echo
OPENCLAW_GATEWAY_TOKEN="$GATEWAY_TOKEN" \
openclaw node run \
  --host 127.0.0.1 \
  --port "$CLOUD_TUNNEL_PORT" \
  --display-name "$LOCAL_NODE_DISPLAY_NAME"
