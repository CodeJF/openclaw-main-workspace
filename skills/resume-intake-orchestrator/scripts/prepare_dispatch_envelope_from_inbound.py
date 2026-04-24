#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PREPARE = ROOT / "prepare_dispatch_envelope.py"

MEDIA_ATTACHED_RE = re.compile(r"\[media attached:\s*(.+?)\]", re.IGNORECASE)
FILE_NAME_TAG_RE = re.compile(r'<file\s+name="([^"]+)"', re.IGNORECASE)
FILE_NAME_INLINE_RE = re.compile(r'\[File:\s+(.+?)\]')


def infer_mode(paths: list[str], explicit_mode: str) -> str:
    mode = (explicit_mode or "").strip().lower()
    if mode and mode != "unknown":
        return explicit_mode
    suffixes = [Path(p).suffix.lower() for p in paths if p]
    if len(suffixes) == 1 and suffixes[0] == ".pdf":
        return "single_pdf"
    if len(suffixes) == 1 and suffixes[0] == ".zip":
        return "zip_batch"
    if suffixes and all(s == ".pdf" for s in suffixes):
        return "multi_pdf"
    return explicit_mode


def extract_paths(text: str) -> list[str]:
    found: list[str] = []
    for match in MEDIA_ATTACHED_RE.finditer(text or ""):
        raw = match.group(1).strip()
        if "|" in raw:
            raw = raw.split("|", 1)[0].strip()
        raw = re.sub(r'\s+\([^()]+/[^()]+\)$', '', raw).strip()
        if raw and raw not in found:
            found.append(raw)
    return found


def extract_display_names(text: str) -> list[str]:
    found: list[str] = []
    for match in FILE_NAME_TAG_RE.finditer(text or ""):
        value = match.group(1).strip()
        if value:
            found.append(value)
    if found:
        return found
    for match in FILE_NAME_INLINE_RE.finditer(text or ""):
        raw = match.group(1).strip()
        value = Path(raw).name.strip()
        if value:
            found.append(value)
    return found


def main() -> int:
    ap = argparse.ArgumentParser(description="Build resume-intake dispatch envelope directly from inbound message text")
    ap.add_argument("--sender-open-id", required=True)
    ap.add_argument("--user-request", required=True)
    ap.add_argument("--message-id", default="unknown")
    ap.add_argument("--mode", default="unknown")
    inbound_group = ap.add_mutually_exclusive_group(required=True)
    inbound_group.add_argument("--inbound-text")
    inbound_group.add_argument("--inbound-text-file")
    ap.add_argument("--reply-session-key", default="")
    ap.add_argument("--channel", default="feishu")
    ap.add_argument("--chat-type", default="direct")
    ap.add_argument("--agent-id", default="resume-intake-local-test")
    ap.add_argument("--confirm-token", required=True)
    args = ap.parse_args()

    inbound_text = args.inbound_text
    if args.inbound_text_file:
        inbound_text = Path(args.inbound_text_file).read_text(encoding="utf-8")

    paths = extract_paths(inbound_text)
    names = extract_display_names(inbound_text)
    resolved_mode = infer_mode(paths, args.mode)

    cmd = [
        sys.executable,
        str(PREPARE),
        "--sender-open-id", args.sender_open_id,
        "--user-request", args.user_request,
        "--mode", resolved_mode,
        "--message-id", args.message_id,
        "--channel", args.channel,
        "--chat-type", args.chat_type,
        "--agent-id", args.agent_id,
        "--reply-session-key", args.reply_session_key,
        "--confirm-token", args.confirm_token,
    ]
    for path in paths:
        cmd.extend(["--file", path])
    for name in names[: len(paths) or None]:
        cmd.extend(["--file-display-name", name])

    proc = subprocess.run(cmd, capture_output=True, text=True)
    sys.stdout.write(proc.stdout)
    sys.stderr.write(proc.stderr)
    return proc.returncode


if __name__ == "__main__":
    raise SystemExit(main())
