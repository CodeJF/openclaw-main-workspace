#!/usr/bin/env bash
set -euo pipefail

# cloud_approve_latest_node.sh
# 用途：在云端 Gateway 上批准最新的 pending node pairing request。

CONFIG_PATH="${CONFIG_PATH:-/root/.openclaw/openclaw.json}"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "❌ 找不到配置文件: $CONFIG_PATH" >&2
  exit 1
fi

TOKEN="$(python3 - <<'PY' "$CONFIG_PATH"
import json, sys
p = sys.argv[1]
with open(p, 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data.get('gateway', {}).get('auth', {}).get('token', ''))
PY
)"

if [[ -z "$TOKEN" ]]; then
  echo "❌ 读取不到 gateway token" >&2
  exit 1
fi

echo "== pending nodes =="
openclaw nodes pending --token "$TOKEN" --url ws://127.0.0.1:18789 || true

echo
echo "如果上面已经出现 pending request，请复制 requestId 执行："
echo "openclaw nodes approve <requestId> --token \"$TOKEN\" --url ws://127.0.0.1:18789"
