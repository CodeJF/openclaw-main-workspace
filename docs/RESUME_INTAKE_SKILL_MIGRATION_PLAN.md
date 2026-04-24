# Resume-intake skill migration plan

迁移期间，这份 root doc 继续保留；skill 化后的对应参考在 `skills/resume-intake-orchestrator/references/migration-notes.md`。

这份文档只定义**低风险迁移方案**，目标是把当前 workspace 里分散的 resume-intake 编排约束逐步收敛成 OpenClaw skills 结构。

**注意：本方案当前不要求修改正在工作的主链路代码。**

## 目标

把当前分散在以下位置的编排规则逐步收敛：

- `AGENTS.md`
- `docs/RESUME_INTAKE_ROUTING.md`
- `docs/RESUME_INTAKE_SESSION_TARGETING.md`
- `docs/RESUME_INTAKE_ORCHESTRATION_NOTES.md`
- `scripts/resume_intake/*`

最终形成更清晰的两层结构：

1. **主 workspace skill：编排层**
   - 负责 inbound 提取、dispatch envelope、session targeting、回传边界
2. **workspace-resume-intake skill：业务层**
   - 负责 PDF/ZIP 处理、字段抽取、guarded payload、附件回填、duplicate update

## 为什么要这样迁移

当前规则虽然已经能工作，但主要问题是：

- 入口规则散落在多个文件里
- 一部分规则属于主编排，一部分规则属于业务 worker，边界不够集中
- 以后如果不只 `main` 需要编排 resume-intake，复用成本会偏高
- 新 agent 接手时，很难快速知道“该看哪一层规则”

Skill 化后的目标是：

- workspace 级文件只保留薄入口
- 核心流程和硬约束进入 skill
- 详细说明进入 `references/`
- 可复用脚本继续放在 `scripts/`

## 目标结构（建议）

### 主 workspace

建议新增一个 orchestrator skill，例如：

```text
skills/
  resume-intake-orchestrator/
    SKILL.md
    references/
      orchestration.md
      dispatch-envelope.md
      session-targeting.md
      failure-modes.md
```

这个 skill 只负责“主编排 -> worker”这层。

### workspace-resume-intake

继续保留当前业务 skill：

```text
skills/
  resume-intake-workflow/
    SKILL.md
    scripts/
    references/
```

它继续承接实际业务执行，不承担渠道适配和主编排入口解释。

## 各层职责边界

### A. 主 workspace skill（新）

只负责：

- 判断何时触发委派
- 从原始 inbound user message 提取事实
- 组装标准 dispatch envelope
- 依据事实判定 `single_pdf` / `zip_batch` / `multi_pdf` / `unknown`
- 命中已有 worker session
- 规定 worker 回传目标
- 规定主编排如何显式回原渠道用户

不负责：

- PDF 文本提取
- 候选人字段抽取
- Bitable create/update 细节
- 附件上传执行

### B. worker business skill（现有）

继续负责：

- PDF/ZIP 业务处理
- `fields.json` / `create_payload.json` / `tool_plan.json`
- guarded create/update payload
- duplicate candidate update
- attachment upload / attachment update

不负责：

- 各渠道原始消息形态适配
- 主编排如何选 session
- 主编排最终怎么对用户回复

## 迁移分期（最小风险）

### Phase 0：冻结现有主链路

当前状态：

- 不移动现有脚本
- 不修改当前 live 入口逻辑
- 不删除现有 docs

目标：

- 先把“正在工作的东西”视为稳定基线

### Phase 1：新增 orchestrator skill，但不切流

动作：

- 新增 `skills/resume-intake-orchestrator/`
- 先把现有主编排规则整理成 skill 结构
- 只做文档/结构收敛，不修改 live 路由代码

来源迁移建议：

- `docs/RESUME_INTAKE_ROUTING.md` -> `references/orchestration.md`
- `docs/RESUME_INTAKE_SESSION_TARGETING.md` -> `references/session-targeting.md`
- `docs/RESUME_INTAKE_ORCHESTRATION_NOTES.md` -> `references/failure-modes.md` 或 `references/orchestration.md`
- `scripts/resume_intake/*` 暂时原地保留，可由 skill 引用

目标：

- 先让规则“有新的唯一入口”
- 但旧入口继续保留，业务不受影响

### Phase 2：把 AGENTS.md 缩薄

动作：

- 只保留 resume-intake 的入口触发原则和边界
- 不再在 `AGENTS.md` 重复细节流程

保留内容建议：

- 这是编排，不在 main 执行业务
- 命中 orchestrator skill
- 把任务派给已有 worker session
- worker 只回当前 sourceSessionKey

删除/迁出建议：

- 细粒度 dispatch 文案
- mode 判定细节
- helper 参数细节
- 架构解释

### Phase 3：让 orchestrator skill 成为默认知识入口

动作：

- 当 resume-intake 触发时，优先读取 orchestrator skill
- 旧 docs 仍然保留一段时间，但只作为兼容参考

目标：

- 新 agent 或新编排层不再需要从 workspace 根 docs 拼装知识

### Phase 4：再决定是否归并旧 docs

只在确认稳定后才做：

- 删掉明显重复的 docs
- 或把 docs 改成单行跳转说明

在这一步之前，不建议删除任何现在仍被引用的文档。

## 文件迁移建议

### 现有文件建议保留/迁移关系

- `docs/RESUME_INTAKE_ROUTING.md`
  - **短期保留**
  - 中期可精简成 skill 导航页
- `docs/RESUME_INTAKE_SESSION_TARGETING.md`
  - **短期保留**
  - 中期迁入 orchestrator skill reference
- `docs/RESUME_INTAKE_ORCHESTRATION_NOTES.md`
  - **内容适合直接迁进 skill references**
- `docs/RESUME_INTAKE_DELEGATION_PROMPT.md`
  - 可保留，也可迁成 skill reference 的模板说明
- `scripts/resume_intake/*`
  - **短期不移动**，避免改动主链路引用路径
  - 中后期再评估是否迁到 orchestrator skill 目录

## 为什么短期不移动 scripts

虽然从结构上看，把 `scripts/resume_intake/*` 一起迁进 skill 更整洁，但现在不建议立刻做，因为：

- 这些脚本已经被当前文档和主链路引用
- 一旦改路径，就不再是“只做结构整理”，而是变成真实主链路改造
- 当前优先级是“规则收敛”，不是“路径重构”

因此短期建议：

- **先由 orchestrator skill 引用现有 scripts 路径**
- 等业务稳定一段时间后，再考虑迁目录

## 验收标准

当下面条件满足时，可以认为迁移成功：

1. 新人查看 orchestrator skill 就能理解：
   - inbound 从哪里来
   - 为什么要 dispatch envelope
   - mode 如何判定
   - worker 和主编排如何分工
2. `AGENTS.md` 不再承载大量 resume-intake 细节
3. 不修改主链路代码的前提下，现有业务行为不变
4. direct worker path 和 orchestrated path 的边界能在一个地方看清楚

## 回滚边界

这份迁移方案的设计原则是：

- **Phase 1-2 只新增/收敛，不替换 live 行为**
- 任意时刻如果觉得不稳，可以停在当前阶段
- 只要不移动主链路脚本、不删除旧 docs，就没有高风险回滚成本

## 推荐下一步

最小风险的下一步不是改代码，而是：

1. 新建 orchestrator skill 骨架
2. 把现有编排规则整理进去
3. 先让 skill 成为“新的知识入口”
4. 观察一段时间后再缩薄 AGENTS/docs

这一步完成前，不建议动当前已经工作的业务路径。
