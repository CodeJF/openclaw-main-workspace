# Routing reference

Delegate when the request is an actual resume-intake task, for example:

- single PDF resume for Feishu intake
- ZIP batch of resumes
- explicit request to import a resume into the hiring table

Do not delegate when the user is only asking about:

- architecture
- rules
- status
- design discussion
- generic Bitable operations unrelated to the fixed resume-intake business flow

## Handoff rules

- Prefer `prepare_dispatch_envelope_from_inbound.py` when the source request is a raw attachment message.
- When the inbound text contains markdown fences, JSON snippets, or multiple shell-sensitive lines, prefer `--inbound-text-file` instead of shell-inlining the whole message.
- If helper output still has `input_files=[]`, stop.
- If helper output still has `mode=unknown`, stop.
- Only after the envelope is valid should the orchestrator call `sessions_send`.
- For orchestrator -> worker dispatch, prefer the helper-generated `sessions_send` arguments as-is, including `timeoutSeconds=0`; do not turn the handoff into a long synchronous wait unless the user explicitly needs blocking behavior.
- Worker returns one formal result or blocker to the designated source session.
- Orchestrator is responsible for the final explicit user-facing reply.

## Handling worker replies

When the worker pushes a result back to the orchestrator via `sessions_send`, the orchestrator's only job is to relay to the Feishu user. Do not re-run business logic, do not re-parse the PDF, do not re-compute payloads.

Expected worker response shapes (aligned with the business session):

- `completed`
  - 简历已经完成录入或更新
  - main 直接把完成结果（候选人姓名、记录 id / 链接等）转述给用户
- `blocked`
  - 业务因可解释原因停下（如姓名缺失、PDF 不可读、schema 不匹配）
  - main 把 blocker 原因清晰转述给用户，不尝试代替 worker 修复
- `analysis_only`
  - 用户只让分析，没有要求录入
  - main 把分析结论整理后回用户，不进入录入链路
- `partial`
  - worker 做了一部分（如 create 成功但 attachment 未上传）
  - main 如实转述，说明哪些步骤已完成、哪些未完成

Hard lines for the orchestrator after receiving a worker reply:

- 不在 main workspace 重跑 PDF 文本提取、字段抽取、payload 构造、Bitable 写入、附件上传
- 不二次派发同一个任务
- 不沉默吞掉 worker 的 blocker / partial，必须显式回给用户
