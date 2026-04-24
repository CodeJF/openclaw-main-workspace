# Resume-intake session targeting

这个文件定义 main agent 如何把任务直接送到**已有 OAuth 上下文**的 `workspace-resume-intake` 业务会话。

## 目标原则

- 不新开 subagent 去执行 resume-intake 业务
- 不让 main 自己执行 resume-intake 业务
- 直接把任务发给已有的 `workspace-resume-intake` Feishu 业务会话

## 当前环境下的目标会话规则

当前稳定样本的业务会话 key 形态为：

```text
agent:resume-intake-local-test:feishu:direct:<sender_open_id>
```

例如：

```text
agent:resume-intake-local-test:feishu:direct:ou_f7968e7d401919cb6d73093101319594
```

## 命中规则

当 main agent 收到需要录入简历的 Feishu 私聊任务时：

1. 先提取当前用户的 `sender_open_id`
2. 直接构造目标 session key：

```text
agent:resume-intake-local-test:feishu:direct:<sender_open_id>
```

3. 优先使用 `sessions_send` 把任务发给这个既有业务会话
4. 由该业务会话完成实际简历录入
5. main 只等待结果并对用户回复

## 辅助脚本

为避免 main 侧每次手写 key 和委派文本，当前工作区提供两个辅助脚本：

- `scripts/resume_intake/derive_session_target.py`
  - 输入：`sender_open_id`、`channel`、`chat_type`
  - 输出：可安全使用的 `sessionKey`
- `scripts/resume_intake/build_delegation_message.py`
  - 输入：用户请求、文件路径、mode、message_id
  - 输出：发给既有业务会话的委派消息正文
- `scripts/resume_intake/prepare_sessions_send.py`
  - 输入：`sender_open_id` + 用户请求 + 文件路径 + mode + message_id（`reply_session_key` 可选）
  - 输出：可直接用于 `sessions_send` 的 dry-run payload（不真实发送）
- `scripts/resume_intake/prepare_confirmed_sessions_send.py`
  - 输入：与上面相同，外加 `--confirm-token`（`reply_session_key` 可选）
  - 输出：带显式确认门槛的待发送 payload
- `scripts/resume_intake/prepare_dispatch_envelope.py`
  - 输入：与上面相同，且必须带 `--confirm-token`（`reply_session_key` 可选）
  - 输出：最终可交给 assistant `sessions_send` 工具执行的 envelope
- `scripts/resume_intake/prepare_dispatch_envelope_from_inbound.py`
  - 输入：`sender_open_id` + `user_request` + 原始 inbound message text + `message_id` + `confirm-token`（`reply_session_key` 可选）
  - 输出：自动从原消息里提取 `attachment_path` 与 `<file name="...">`，再生成最终 dispatch envelope，适合附件入口避免文件名乱码漂移

## 失败时的保守处理

如果无法确认当前任务来自 Feishu 私聊，或无法确定 `sender_open_id`，不要擅自切到新 subagent 执行录入。

此时应视为“无法安全命中已有 OAuth 业务会话”，先停下来说明 blocker。

## Dry-run 准备方式

在真正调用 `sessions_send` 前，可以先运行：

```bash
python3 scripts/resume_intake/prepare_sessions_send.py \
  --sender-open-id <sender_open_id> \
  --user-request '把这份简历录入飞书' \
  --mode single_pdf \
  --message-id <message_id> \
  --file <pdf_path>
```

它会输出：
- 命中的 `sessionKey`
- 组装好的 `sessionsSendCall.message`
- 但不会真实发送

如果要进入“可发送”状态，可以再运行：

```bash
python3 scripts/resume_intake/prepare_confirmed_sessions_send.py \
  --sender-open-id <sender_open_id> \
  --user-request '把这份简历录入飞书' \
  --mode single_pdf \
  --message-id <message_id> \
  --file <pdf_path> \
  --confirm-token SEND_TO_EXISTING_RESUME_INTAKE_SESSION
```

注意：这一步依然只生成 **已确认的 payload**。真实发送仍应由 assistant 使用 `sessions_send` 工具完成，不假设存在等价 CLI。

如果要得到最终 dispatch envelope，可以再运行：

```bash
python3 scripts/resume_intake/prepare_dispatch_envelope.py \
  --sender-open-id <sender_open_id> \
  --user-request '把这份简历录入飞书' \
  --mode single_pdf \
  --message-id <message_id> \
  --file <pdf_path> \
  --confirm-token SEND_TO_EXISTING_RESUME_INTAKE_SESSION
```

它会输出：
- `sessionKey`
- `message`
- `assistantToolCall.tool = sessions_send`
- `assistantToolCall.arguments`

但依然不会自行发送。

## 委派内容

发送给目标业务会话时，至少带上：

- 用户原始请求
- 输入文件路径列表
- 输入模式：`single_pdf` / `zip_batch` / `analysis_only` / `unknown`
- message_id
- `reply_session_key`（如果当前这次主编排能拿到自己的 sessionKey 就显式带上；拿不到时可以留空，worker 必须回到该委派消息自己的 `sourceSessionKey`）
- 一句明确要求：由该业务会话完成实际录入，main 只做编排
