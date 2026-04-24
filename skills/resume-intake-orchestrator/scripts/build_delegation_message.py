#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


def normalize_mode(value: str) -> str:
    allowed = {"single_pdf", "multi_pdf", "zip_batch", "analysis_only", "unknown"}
    value = (value or "unknown").strip()
    if value not in allowed:
        raise SystemExit(f"不支持的 mode: {value}")
    return value


def main() -> int:
    ap = argparse.ArgumentParser(description="Build a delegation message for the existing resume-intake business session")
    ap.add_argument("--user-request", required=True)
    ap.add_argument("--mode", default="unknown")
    ap.add_argument("--message-id", default="unknown")
    ap.add_argument("--reply-session-key", default="")
    ap.add_argument("--file", dest="files", action="append", default=[])
    ap.add_argument("--file-display-name", dest="file_display_names", action="append", default=[])
    ap.add_argument("--note", default="请由该业务会话完成实际录入，main 只做编排。")
    args = ap.parse_args()

    mode = normalize_mode(args.mode)
    files = [str(Path(item)) for item in args.files]
    display_names = list(args.file_display_names)
    while len(display_names) < len(files):
        display_names.append("")

    reply_session_key = (args.reply_session_key or "").strip() or "USE_SOURCE_SESSION_KEY_OF_THIS_DELEGATION_MESSAGE"

    file_items = [
        {
            "path": path,
            "source_name": (display_names[idx] or "").strip() or None,
        }
        for idx, path in enumerate(files)
    ]
    file_lines = "\n".join(
        f"- path: {item['path']}" + (f"\n  source_name: {item['source_name']}" if item.get("source_name") else "")
        for item in file_items
    ) if file_items else "- none"
    files_json = json.dumps(file_items, ensure_ascii=False, indent=2) if file_items else "[]"

    message = f"""这是来自主编排 agent 的 resume-intake 委派任务。

用户原始请求：
{args.user_request}

输入文件：
{file_lines}

输入文件明细 JSON：
{files_json}

输入模式：
{mode}

message_id：
{args.message_id}

正式结果 / blocker 的唯一回传目标 sessionKey：
{reply_session_key}

要求：
1. 请按 workspace-resume-intake 的既有 workflow 完成实际简历录入处理，而不是只生成方案。
2. 如果是单 PDF 或 ZIP 批量录入，resume-intake 业务步骤由你负责完成。
3. 如果上面的 reply_session_key 是真实 sessionKey，则正式结果或 blocker 只能通过一次 `sessions_send` 回给它；如果上面是 `USE_SOURCE_SESSION_KEY_OF_THIS_DELEGATION_MESSAGE`，则只能回给本次委派消息自己的 `sourceSessionKey`。
4. 不要猜别的 main，不要回历史会话。
5. 结果回传后，当前 worker 会话不再输出任何可见文本。
6. {args.note}
7. 如果某个输入文件给了 `source_name`，实际执行 upload 时必须优先使用这个 `source_name` 作为附件文件名；必要时先复制到同工作目录下的 `source_name` 路径再上传，不要直接沿用 inbound 缓存路径里的乱码名。
"""

    print(json.dumps({
        "mode": mode,
        "messageId": args.message_id,
        "replySessionKey": reply_session_key,
        "files": files,
        "fileItems": file_items,
        "message": message,
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
