# Resume-intake delegation notes

这个文件定义 main agent 发给既有 `workspace-resume-intake` 业务会话的委派内容。

它只保留 main agent 向 `workspace-resume-intake` 委派任务时，必须讲清楚的内容：

- 用户原始请求
- 输入文件路径列表
- 输入模式：`single_pdf` / `zip_batch` / `analysis_only` / `unknown`
- 任何已知的 message_id
- 期望返回：`completed` / `blocked` / `analysis_only` / `partial`

推荐调用方式：

- `sessions_send`
- 目标：按 `docs/RESUME_INTAKE_SESSION_TARGETING.md` 命中的既有 Feishu direct 业务会话
- 可先用 `scripts/resume_intake/prepare_sessions_send.py`、`prepare_confirmed_sessions_send.py`，或最终的 `prepare_dispatch_envelope.py` 生成 payload，再由 assistant 调用 `sessions_send`

原则只有一条：

- `main agent` 只做编排、等待结果、对用户回复
- `workspace-resume-intake` 负责实际简历录入处理

不要在这里把任务转给新的 subagent 去实际执行录入，也不要发明不存在的 CLI 来替代 `sessions_send`。
