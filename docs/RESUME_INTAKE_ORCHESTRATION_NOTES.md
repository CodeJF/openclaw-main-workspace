# Resume-intake orchestration notes

迁移期间，这份 root doc 继续保留；skill 化后的对应参考在 `skills/resume-intake-orchestrator/references/orchestration.md`。

这份文档补充说明：为什么 direct worker 路径稳定，而经过主编排的 orchestrated 路径更容易出错，以及以后类似需求应该优先检查哪里。

## 一句话模型

resume-intake 的稳定分层应是：

1. **渠道原始输入层**
   - Feishu / 其他渠道把原始消息送进当前会话
   - 原始 user message 本身就是 inbound 事实源
2. **主编排归一化层**
   - 从原始 inbound 文本提取附件路径、显示名、message_id、sender 等事实
   - 组装标准 dispatch envelope
3. **worker 业务执行层**
   - 只消费标准化后的输入
   - 执行简历解析、查重、写表、附件回填
4. **结果回传层**
   - worker 回主编排
   - 主编排显式回原渠道用户

## 为什么 direct worker 通常没问题

用户直接把 PDF/ZIP 发给 `workspace-resume-intake` 时：

- worker 直接拿到原始输入
- worker 直接走 skill 的稳定脚本链路
- 中间没有额外的“转述 / 委派 / 协议翻译”层

所以这条路径通常更稳。

## 为什么 orchestrated path 更容易出错

一旦多了“主编排 -> worker”的边界，就会多出一层协议转换。最常见的坑是：

1. **元数据丢失**
   - 只带了缓存 `attachment_path`
   - 没带原始 `source_name`
   - 结果附件文件名乱码
2. **mode 漂移**
   - 明明已经提取到 1 个 PDF
   - 却仍然停在 `unknown`
3. **payload 形状漂移**
   - direct create 用的是稳定脚本产物
   - duplicate update 却变成临时手工拼 payload
4. **结果回传漂移**
   - session 内有结果，不等于已经真正回到原渠道用户

## inbound 在哪里

对这条链路来说，`inbound` 不是额外系统接口，而是当前会话收到的原始 user message 内容。

常见事实会出现在：

- `[media attached: ... | ...]`
- `System: Feishu[...] [msg:om_xxx, file, ...]`
- `[File: /path/to/file]`
- `<file name="..." mime="...">`

因此，主编排做 resume-intake 时，原始 user message 就是 inbound 事实源。

## 为什么要组装 dispatch envelope

worker 不应该理解每个渠道原始消息的具体长相。

dispatch envelope 的作用是把上游事实统一成 worker 可稳定消费的结构，例如：

- `input_files`
- `input_mode`
- `source_name`
- `message_id`
- `reply_session_key` 或 sourceSessionKey 回传约束

这样 worker 才能专注业务，而不是兼做渠道适配器。

## mode 的正确判定方式

mode 应优先按“输入事实”判定，而不是按自由文本猜。

推荐硬规则：

- 1 个 `.pdf` -> `single_pdf`
- 1 个 `.zip` -> `zip_batch`
- 多个 `.pdf` -> `multi_pdf`（或按业务定义转成批量）
- 真没有输入文件 -> `unknown`

只要 helper 仍然产出：

- `input_files=[]`
- `mode=unknown`

就不应继续向 worker 委派。

## 为什么不要手工拼 update payload

尤其是 duplicate / 重名候选人的 update，手工拼 payload 最容易出错：

- 字段类型容易漂移
- 不同入口各拼各的
- 很容易绕过统一的 normalization / guard 逻辑

稳定做法是统一走受保护的 payload 生成器，例如：

- `guarded_bitable_write.py <target_key> update <fields_json> --record-id <record_id>`

这样可以把：

- 年龄字符串 -> 整数
- `[{"text": "大专"}]` -> `"大专"`
- 其他错误形态 -> 统一归一化

## 类似需求以后优先检查哪 4 个边界

如果出现“direct path 正常，但 orchestrated path 出错”，第一优先级检查：

1. **输入提取**
   - 是否从原始 inbound user message 提到了完整文件路径 / message_id / sender
2. **dispatch envelope**
   - `input_files`、`input_mode`、`source_name` 是否成形
3. **guarded payload**
   - create / update 是否走统一受保护脚本
4. **结果回传**
   - 是否真正发回原渠道用户，而不只是停在 session 内

## 这份文档的用途

这份说明是对 `RESUME_INTAKE_ROUTING.md`、`RESUME_INTAKE_SESSION_TARGETING.md` 的架构补充，不替代入口规则和 target 规则。
