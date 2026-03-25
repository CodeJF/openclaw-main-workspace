#!/usr/bin/env python3
"""
最小验证脚本：使用飞书开放平台 OAuth 用户令牌创建多维表格（Bitable）。

用途：验证“用户身份是否可以通过 API 创建多维表格”。

环境变量：
  FEISHU_USER_ACCESS_TOKEN   必填，用户访问令牌（OAuth user_access_token）
  FEISHU_FOLDER_TOKEN        可选，创建到指定文件夹；不填则创建到“我的空间”根目录
  FEISHU_BITABLE_NAME        可选，多维表格名称
  FEISHU_BASE_URL            可选，默认 https://open.feishu.cn

用法：
  python3 scripts/feishu_create_bitable_test.py

说明：
- 这是直接走飞书开放平台 API，不依赖聊天式助手 UI。
- 若返回权限错误，需要在飞书开放平台为应用开通相应 scopes，并重新授权。
"""

from __future__ import annotations

import json
import os
import sys
import time
from urllib import error, request


BASE_URL = os.getenv("FEISHU_BASE_URL", "https://open.feishu.cn").rstrip("/")
USER_ACCESS_TOKEN = os.getenv("FEISHU_USER_ACCESS_TOKEN", "").strip()
FOLDER_TOKEN = os.getenv("FEISHU_FOLDER_TOKEN", "").strip()
BITABLE_NAME = os.getenv(
    "FEISHU_BITABLE_NAME",
    f"OpenClaw API 测试多维表格 {time.strftime('%Y-%m-%d %H:%M:%S')}",
).strip()


def fail(msg: str, code: int = 1) -> None:
    print(msg, file=sys.stderr)
    sys.exit(code)


def http_post_json(url: str, payload: dict, headers: dict) -> tuple[int, dict | str]:
    data = json.dumps(payload).encode("utf-8")
    req = request.Request(url=url, data=data, method="POST")
    req.add_header("Content-Type", "application/json; charset=utf-8")
    for k, v in headers.items():
        req.add_header(k, v)

    try:
        with request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            try:
                return resp.status, json.loads(raw)
            except json.JSONDecodeError:
                return resp.status, raw
    except error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            return e.code, json.loads(raw)
        except json.JSONDecodeError:
            return e.code, raw
    except Exception as e:
        fail(f"请求失败: {e}")


def main() -> None:
    if not USER_ACCESS_TOKEN:
        fail(
            "缺少环境变量 FEISHU_USER_ACCESS_TOKEN。\n"
            "请先准备 OAuth 用户令牌，再执行：\n"
            "  FEISHU_USER_ACCESS_TOKEN='u-xxx' python3 scripts/feishu_create_bitable_test.py"
        )

    url = f"{BASE_URL}/open-apis/bitable/v1/apps"
    payload = {"name": BITABLE_NAME}
    if FOLDER_TOKEN:
        payload["folder_token"] = FOLDER_TOKEN

    headers = {
        "Authorization": f"Bearer {USER_ACCESS_TOKEN}",
    }

    status, body = http_post_json(url, payload, headers)

    print("=== Request ===")
    print(json.dumps({
        "url": url,
        "payload": payload,
        "headers": {"Authorization": "Bearer ***"},
    }, ensure_ascii=False, indent=2))
    print()
    print("=== Response ===")
    print(f"HTTP {status}")
    if isinstance(body, dict):
        print(json.dumps(body, ensure_ascii=False, indent=2))
    else:
        print(body)

    if status >= 400:
        sys.exit(2)

    if isinstance(body, dict) and body.get("code") not in (0, None):
        sys.exit(3)

    data = body.get("data", {}) if isinstance(body, dict) else {}
    app = data.get("app", {}) if isinstance(data, dict) else {}

    if app:
        print()
        print("=== Parsed Result ===")
        print(json.dumps({
            "app_token": app.get("app_token"),
            "name": app.get("name"),
            "url": app.get("url"),
            "revision": app.get("revision"),
        }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
