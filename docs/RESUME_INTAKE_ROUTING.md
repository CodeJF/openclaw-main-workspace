# Resume-intake routing from main agent

这个文档定义 `main agent` 在收到简历相关请求时的实际入口动作。

如果要理解为什么 direct worker 稳、而 orchestrated path 更容易出错，以及主编排和 worker 的边界应该怎么划，先看 `docs/RESUME_INTAKE_ORCHESTRATION_NOTES.md`。

迁移期间，这份 root doc 继续保留；更接近长期 skill 结构的对应材料在 `skills/resume-intake-orchestrator/references/` 下。

## 什么时候触发委派

满足以下任一条件时，默认走 `workspace-resume-intake`：

- 用户发送单个 PDF 简历，并希望录入 / 导入 / 入库到飞书
- 用户发送一个 ZIP，且语义上是在批量录入简历
- 用户明确说“把这份简历录入飞书 / 录入多维表格 / 加到招聘表里”
- 用户要求只分析简历，但对象仍然是简历 PDF / ZIP，此时也委派给业务工作区判断 `analysis_only`

以下情况不要直接走这个委派：

- 用户只是问架构、进度、规则说明
- 用户要做通用 Feishu Bitable 操作，而不是固定简历录入链路
- 用户给的是非简历文件，或目标不是 resume-intake 业务

## main agent 的动作

触发后，`main agent` 应做 4 步：

1. 先按 `docs/RESUME_INTAKE_SESSION_TARGETING.md` 命中已有 OAuth 上下文的 `workspace-resume-intake` 业务会话
2. 可先用 `skills/resume-intake-orchestrator/scripts/derive_session_target.py` 推导目标 `sessionKey`
3. 再用 `skills/resume-intake-orchestrator/scripts/build_delegation_message.py` 生成委派消息，并通过 `sessions_send` 发给这个既有业务会话
   - 如果请求来自原始附件消息，优先用 `skills/resume-intake-orchestrator/scripts/prepare_dispatch_envelope_from_inbound.py`，避免只传缓存 `attachment_path` 而丢掉原始文件名
4. 优先走异步 handoff，不要因为 worker 尚未在当前等待窗口内返回，就让用户重复确认已经明确的录入意图
5. 等它返回最终结果后，再由 `main agent` 对用户回复

## 给业务会话的委派口径

委派给 `workspace-resume-intake` 的既有业务会话时，至少要把下面这些信息说清楚：

- 用户原始请求
- 输入文件路径列表
- 输入文件的原始显示名 / `source_name`（如果原消息里有 `<file name="...">` 或等价元数据，必须一并带上）
- 输入模式：`single_pdf` / `zip_batch` / `analysis_only` / `unknown`
- 任何已知的 message_id
- 当前这次委派的唯一回传目标 `reply_session_key`（如果主编排拿得到自己的 sessionKey 就显式带上；拿不到时，worker 必须直接使用这条委派消息自己的 `sourceSessionKey` 作为唯一回传目标）

同时明确要求它：
1. 按本工作区 workflow 完成实际简历录入处理，而不是只生成方案。
2. 如果是单 PDF 或 ZIP 批量录入，resume-intake 业务步骤由它负责完成。
3. 返回结构化结果时，只能通过一次 `sessions_send` 回给本次委派提供的 `reply_session_key`；如果本次委派没有显式提供，则只能回给该委派消息自己的 `sourceSessionKey`。
4. 如果阻塞，也只能通过一次 `sessions_send` 回给同一个目标。
5. 回传后当前 worker 会话不再输出任何可见文本。

## 业务会话返回后的主会话处理

### 1. `completed`
- `main agent` 直接把完成结果转述给用户
- 不在主工作区重跑 resume-intake 业务逻辑
- 不在主工作区补做字段抽取、payload 构造、录入写表等业务动作

### 2. `blocked`
直接向用户说明阻塞原因，例如：
- 姓名缺失
- PDF/ZIP 不可读
- 目标不明确
- 字段或 schema 明显不匹配

### 3. `analysis_only`
把 worker 的分析结论整理后直接回复用户，不进入录入链路

## 最关键的边界

- `main agent` 只负责编排、等待、对用户回复
- `workspace-resume-intake` 的既有业务会话负责实际简历录入处理
- 主工作区不要承接 resume-intake 业务步骤

如果这三点被满足，就算入口接对了。
