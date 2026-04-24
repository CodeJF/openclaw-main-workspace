#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONFIRMED = ROOT / "prepare_confirmed_sessions_send.py"
FORBIDDEN_AGENT_IDS = {"main", "agent:main"}


def run_json(cmd: list[str]) -> dict:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit(proc.stderr.strip() or proc.stdout.strip() or f"命令失败: {' '.join(cmd)}")
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"输出不是合法 JSON: {exc}\n{proc.stdout}")


def normalize_agent_id(value: str) -> str:
    agent_id = (value or "resume-intake-local-test").strip()
    if not agent_id:
        raise SystemExit("agent-id 不能为空")
    if agent_id in FORBIDDEN_AGENT_IDS:
        raise SystemExit(
            "agent-id 不能指向 main。resume-intake 主编排只能把任务派给既有业务 worker，会话目标应保持为 resume-intake-local-test。"
        )
    return agent_id


def main() -> int:
    ap = argparse.ArgumentParser(description="Prepare a final assistant-side dispatch envelope for sessions_send")
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
    ap.add_argument("--confirm-token", required=True)
    args = ap.parse_args()
    agent_id = normalize_agent_id(args.agent_id)

    cmd = [
        sys.executable,
        str(CONFIRMED),
        "--sender-open-id", args.sender_open_id,
        "--user-request", args.user_request,
        "--mode", args.mode,
        "--message-id", args.message_id,
        "--channel", args.channel,
        "--chat-type", args.chat_type,
        "--agent-id", agent_id,
        "--reply-session-key", args.reply_session_key,
        "--confirm-token", args.confirm_token,
    ]
    for path in args.files:
        cmd.extend(["--file", path])
    for name in args.file_display_names:
        cmd.extend(["--file-display-name", name])

    confirmed = run_json(cmd)
    if not confirmed.get("confirmed"):
        print(json.dumps({
            "ok": False,
            "stage": "not_confirmed",
            "error": confirmed.get("warning") or "payload 尚未确认，不应进入真实派发阶段",
            "requiredConfirmToken": confirmed.get("requiredConfirmToken"),
            "prepared": confirmed,
        }, ensure_ascii=False, indent=2))
        return 1

    delegation = (confirmed.get("prepared") or {}).get("delegation") or {}
    resolved_mode = delegation.get("mode") or "unknown"
    resolved_files = delegation.get("files") or []
    if not resolved_files:
        print(json.dumps({
            "ok": False,
            "stage": "blocked_empty_input",
            "error": "input_files=[]，主编排不应继续派发给 worker",
            "prepared": confirmed,
        }, ensure_ascii=False, indent=2))
        return 2
    if resolved_mode == "unknown":
        print(json.dumps({
            "ok": False,
            "stage": "blocked_unknown_mode",
            "error": "mode=unknown，主编排不应继续派发给 worker",
            "prepared": confirmed,
        }, ensure_ascii=False, indent=2))
        return 2

    call = confirmed.get("sessionsSendCall") or {}
    envelope = {
        "ok": True,
        "stage": "dispatch_ready",
        "dispatchMethod": "assistant_tool_sessions_send",
        "sessionKey": call.get("sessionKey"),
        "replySessionKey": args.reply_session_key,
        "message": call.get("message"),
        "assistantToolCall": {
            "tool": "sessions_send",
            "arguments": {
                "sessionKey": call.get("sessionKey"),
                "message": call.get("message"),
                "timeoutSeconds": 0,
            },
        },
        "note": "下一步应由 assistant 直接调用 sessions_send；该脚本本身不会发送任何消息。",
        "confirmedPayload": confirmed,
    }
    print(json.dumps(envelope, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
