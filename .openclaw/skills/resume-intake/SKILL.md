---
name: resume-intake
description: Parse inbound resume PDFs into conservative candidate fields and generate guarded Feishu write plans for the resume-intake business flow. Use when handling 简历录入 / resume intake tasks such as: (1) downloading or receiving a candidate PDF resume, (2) extracting text from the PDF, (3) mapping resume text into the approved safe fields set, (4) preparing Feishu Bitable create/update payloads for the fixed intake target, (5) attaching the original PDF to the created record, or (6) checking whether a requested intake write is allowed by the business guardrails. Do not use for generic Bitable exploration or creating new business targets without explicit confirmation.
---

# Resume Intake

## Overview

Use this skill for the fixed 简历录入业务链路: PDF 简历 → 文本提取 → 保守字段抽取 → 受保护写入计划 → 附件回填。

Keep the default path narrow. Prefer the approved target and safe fields only. If the target, table, or field mapping is ambiguous, stop and confirm instead of guessing.

## Quick workflow

1. Confirm this is a resume-intake task, not generic Bitable work.
2. If you need the business rules or target registry, read `references/business-rules.md`.
3. If you need the exact field set or extraction heuristics, read `references/field-mapping.md`.
4. If you need to produce a guarded execution plan, run the scripts in `scripts/` rather than re-deriving payloads ad hoc.
5. Execute actual writes with first-class OpenClaw Feishu tools, not direct tenant-token OpenAPI calls.

## Guardrails

- Use the fixed business target unless the user explicitly asks to register or switch targets.
- Do not invent candidate data. Leave uncertain fields empty.
- Treat success as:
  - fields create success + attachment update success => complete success
  - fields create success + attachment failure => partial success
  - fields create failure => failed
- For the fixed path, allow only record `create` and attachment `update` against an approved target.
- Do not use this skill for generic table discovery, broad search, or schema exploration in the production intake path.

## What to read and when

- Read `references/business-rules.md` when you need the target registry, write policy, runtime sequence, or success criteria.
- Read `references/field-mapping.md` when you need the approved safe fields, extraction heuristics, normalization choices, or examples.
- Run `scripts/extract_resume_text.py` when you have a PDF and need plain text.
- Run `scripts/build_candidate_fields.py` when you have resume text and need conservative field JSON.
- Run `scripts/guarded_bitable_write.py` when you need a validated create/update payload for an approved target.
- Run `scripts/guarded_attachment_update.py` when you already have `record_id` and `file_token` and need the attachment update payload.
- Run `scripts/tool_entry_resume_intake.py` when you want the end-to-end local planning artifact for the full business flow.

## Execution pattern

### 1) Local planning

Prefer local planning scripts to produce deterministic artifacts:

- `resume.txt`
- `fields.json`
- `create_payload.json`
- `tool_plan.json`

Recommended work directory pattern:

```text
runtime/inbound/<message_id>/
```

### 2) Real writes

Use OpenClaw Feishu tools for the actual writes:

- `feishu_bitable_app_table_record.create`
- `feishu_drive_file.upload`
- `feishu_bitable_app_table_record.update`

### 3) User-visible response

Report whether the result is complete success, partial success, or failure. Be explicit about attachment failures.

## Notes for future extension

If the user wants to support a new intake target, new safe-field set, or a second business flow, add that as a separate reference or sibling skill instead of bloating this one. Keep this skill focused on the production resume-intake path and progressive disclosure.
