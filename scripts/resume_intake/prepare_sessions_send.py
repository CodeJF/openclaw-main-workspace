#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DERIVE = ROOT / "derive_session_target.py"
BUILD = ROOT / "build_delegation_message.py"


def run_json(cmd: list[str]) -> dict:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit(proc.stderr.strip() or proc.stdout.strip() or f"命令失败: {' '.join(cmd)}")
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"输出不是合法 JSON: {exc}\n{proc.stdout}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Prepare a dry-run payload for sessions_send to the existing resume-intake business session")
    ap.add_argument("--sender-open-id", required=True)
    ap.add_argument("--user-request", required=True)
    ap.add_argument("--mode", default="unknown")
    ap.add_argument("--message-id", default="unknown")
    ap.add_argument("--channel", default="feishu")
    ap.add_argument("--chat-type", default="direct")
    ap.add_argument("--agent-id", default="resume-intake-local-test")
    ap.add_argument("--reply-session-key", default="")
    ap.add_argument("--file", dest="files", action="append", default=[])
    ap.add_argument("--file-display-name", dest="file_display_names", action="append", default=[])
    args = ap.parse_args()

    target = run_json([
        sys.executable,
        str(DERIVE),
        "--sender-open-id",
        args.sender_open_id,
        "--channel",
        args.channel,
        "--chat-type",
        args.chat_type,
        "--agent-id",
        args.agent_id,
    ])
    if not target.get("ok"):
        print(json.dumps(target, ensure_ascii=False, indent=2))
        return 1

    build_cmd = [
        sys.executable,
        str(BUILD),
        "--user-request",
        args.user_request,
        "--mode",
        args.mode,
        "--message-id",
        args.message_id,
        "--reply-session-key",
        args.reply_session_key,
    ]
    for path in args.files:
        build_cmd.extend(["--file", path])
    for name in args.file_display_names:
        build_cmd.extend(["--file-display-name", name])
    payload = run_json(build_cmd)

    result = {
        "ok": True,
        "dryRun": True,
        "sessionKey": target["sessionKey"],
        "sessionsSendCall": {
            "sessionKey": target["sessionKey"],
            "message": payload["message"],
        },
        "target": target,
        "replySessionKey": args.reply_session_key,
        "delegation": payload,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
