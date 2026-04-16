#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="root@47.119.177.99"
SSH_KEY="/Users/jianfengxu/Downloads/has_jianfeng_key.pem"
LOCAL_ARCHIVE="/Users/jianfengxu/.openclaw/workspace/notes/feishu-plugin-auth-hotfix-2026-04-16-files.tar.gz"
REMOTE_TMP_DIR="/root/feishu-plugin-auth-hotfix-restore"
PLUGIN_BASE="/root/.openclaw/extensions/openclaw-lark/src"

if [[ ! -f "$LOCAL_ARCHIVE" ]]; then
  echo "Archive not found: $LOCAL_ARCHIVE" >&2
  exit 1
fi

echo "== Uploading hotfix archive =="
scp -i "$SSH_KEY" "$LOCAL_ARCHIVE" "$REMOTE_HOST:/root/feishu-plugin-auth-hotfix-2026-04-16-files.tar.gz"

echo "== Restoring hotfix files on server =="
ssh -i "$SSH_KEY" "$REMOTE_HOST" 'bash -s' <<'REMOTE_EOF'
set -euo pipefail
REMOTE_TMP_DIR="/root/feishu-plugin-auth-hotfix-restore"
PLUGIN_BASE="/root/.openclaw/extensions/openclaw-lark/src"
ARCHIVE="/root/feishu-plugin-auth-hotfix-2026-04-16-files.tar.gz"
STAMP="$(date +%Y%m%d%H%M%S)"

rm -rf "$REMOTE_TMP_DIR"
mkdir -p "$REMOTE_TMP_DIR"
tar -xzf "$ARCHIVE" -C "$REMOTE_TMP_DIR"

cp "$PLUGIN_BASE/tools/oauth.js" "$PLUGIN_BASE/tools/oauth.js.pre-restore.$STAMP"
cp "$PLUGIN_BASE/core/tool-client.js" "$PLUGIN_BASE/core/tool-client.js.pre-restore.$STAMP"
cp "$PLUGIN_BASE/tools/oauth-batch-auth.js" "$PLUGIN_BASE/tools/oauth-batch-auth.js.pre-restore.$STAMP"
cp "$PLUGIN_BASE/messaging/inbound/dispatch.js" "$PLUGIN_BASE/messaging/inbound/dispatch.js.pre-restore.$STAMP"

cp "$REMOTE_TMP_DIR/feishu-plugin-auth-hotfix-2026-04-16-files/oauth.js" "$PLUGIN_BASE/tools/oauth.js"
cp "$REMOTE_TMP_DIR/feishu-plugin-auth-hotfix-2026-04-16-files/tool-client.js" "$PLUGIN_BASE/core/tool-client.js"
cp "$REMOTE_TMP_DIR/feishu-plugin-auth-hotfix-2026-04-16-files/oauth-batch-auth.js" "$PLUGIN_BASE/tools/oauth-batch-auth.js"
cp "$REMOTE_TMP_DIR/feishu-plugin-auth-hotfix-2026-04-16-files/dispatch.js" "$PLUGIN_BASE/messaging/inbound/dispatch.js"

node --check "$PLUGIN_BASE/tools/oauth.js"
node --check "$PLUGIN_BASE/core/tool-client.js"
node --check "$PLUGIN_BASE/tools/oauth-batch-auth.js"
node --check "$PLUGIN_BASE/messaging/inbound/dispatch.js"

systemctl restart openclaw
sleep 4
systemctl status openclaw --no-pager -l | sed -n '1,20p'
REMOTE_EOF

echo "== Hotfix restore complete =="
