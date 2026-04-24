#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys

DEFAULT_AGENT = "resume-intake-local-test"
DEFAULT_CHANNEL = "feishu"
DEFAULT_CHAT_TYPE = "direct"
OPEN_ID_PREFIX = "ou_"


def fail(message: str) -> int:
    print(json.dumps({"ok": False, "error": message}, ensure_ascii=False, indent=2))
    return 1


def main() -> int:
    ap = argparse.ArgumentParser(description="Derive the existing workspace-resume-intake business session key")
    ap.add_argument("--sender-open-id", required=True)
    ap.add_argument("--channel", default=DEFAULT_CHANNEL)
    ap.add_argument("--chat-type", default=DEFAULT_CHAT_TYPE)
    ap.add_argument("--agent-id", default=DEFAULT_AGENT)
    args = ap.parse_args()

    sender_open_id = (args.sender_open_id or "").strip()
    if not sender_open_id:
        return fail("缺少 sender_open_id，无法安全命中 resume-intake 业务会话")
    if not sender_open_id.startswith(OPEN_ID_PREFIX):
        return fail(f"sender_open_id 格式不合法: {sender_open_id}")
    if args.channel != DEFAULT_CHANNEL:
        return fail(f"当前 channel={args.channel}，仅支持 {DEFAULT_CHANNEL} 私聊命中")
    if args.chat_type != DEFAULT_CHAT_TYPE:
        return fail(f"当前 chat_type={args.chat_type}，仅支持 {DEFAULT_CHAT_TYPE} 会话命中")

    session_key = f"agent:{args.agent_id}:{args.channel}:{args.chat_type}:{sender_open_id}"
    print(json.dumps({
        "ok": True,
        "agentId": args.agent_id,
        "channel": args.channel,
        "chatType": args.chat_type,
        "senderOpenId": sender_open_id,
        "sessionKey": session_key,
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
