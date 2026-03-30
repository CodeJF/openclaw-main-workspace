#!/usr/bin/env bash
set -euo pipefail

# cloud_show_token.sh
# 用途：在云端服务器上打印 Gateway token、当前设备/节点状态，供本地 Mac 配对时使用。

CONFIG_PATH="${CONFIG_PATH:-/root/.openclaw/openclaw.json}"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "❌ 找不到配置文件: $CONFIG_PATH" >&2
  exit 1
fi

echo "== Gateway token =="
python3 - <<'PY' "$CONFIG_PATH"
import json, sys
p = sys.argv[1]
with open(p, 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data.get('gateway', {}).get('auth', {}).get('token', ''))
PY

echo
echo "== devices list =="
openclaw devices list || true

echo
echo "== nodes pending =="
openclaw nodes pending || true

echo
echo "== nodes status =="
openclaw nodes status || true
