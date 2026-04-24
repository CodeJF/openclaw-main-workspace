#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PREPARE = ROOT / "prepare_sessions_send.py"
CONFIRM_TOKEN = "SEND_TO_EXISTING_RESUME_INTAKE_SESSION"


def run_json(cmd: list[str]) -> dict:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit(proc.stderr.strip() or proc.stdout.strip() or f"命令失败: {' '.join(cmd)}")
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"输出不是合法 JSON: {exc}\n{proc.stdout}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Prepare a confirmed sessions_send payload for the existing resume-intake business session")
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
    ap.add_argument("--confirm-token")
    args = ap.parse_args()

    prepared = run_json([
        sys.executable,
        str(PREPARE),
        "--sender-open-id", args.sender_open_id,
        "--user-request", args.user_request,
        "--mode", args.mode,
        "--message-id", args.message_id,
        "--channel", args.channel,
        "--chat-type", args.chat_type,
        "--agent-id", args.agent_id,
        "--reply-session-key", args.reply_session_key,
        *sum((["--file", path] for path in args.files), []),
        *sum((["--file-display-name", name] for name in args.file_display_names), []),
    ])

    confirmed = args.confirm_token == CONFIRM_TOKEN
    result = {
        "ok": prepared.get("ok", False),
        "confirmed": confirmed,
        "requiredConfirmToken": CONFIRM_TOKEN,
        "dispatchMethod": "assistant_tool_sessions_send",
        "note": "实际发送应由 assistant 使用 sessions_send 工具完成，不要假设存在等价 CLI。",
        "sessionKey": prepared.get("sessionKey"),
        "replySessionKey": args.reply_session_key,
        "sessionsSendCall": prepared.get("sessionsSendCall"),
        "prepared": prepared,
    }

    if not confirmed:
        result["warning"] = "未提供正确确认 token，当前仅生成待发送 payload，不应执行真实发送。"

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
