---
name: resume-intake-orchestrator
description: Orchestrate resume-intake requests from a main/orchestrator workspace into the existing workspace-resume-intake business session. Use when a user sends a resume PDF or ZIP for Feishu intake and the current workspace should only dispatch, normalize inbound attachment facts, build a dispatch envelope, target the existing OAuth-backed worker session, and relay the final result. Not for direct resume parsing, field extraction, Bitable writes, or worker-side business execution.
---

# Resume-intake orchestrator

This skill is the orchestration layer for resume-intake.

It is responsible for:

- reading the current inbound user message as the source of truth
- extracting attachment facts needed for dispatch
- inferring input mode from real files
- building a standard dispatch envelope
- targeting the existing `workspace-resume-intake` business session
- enforcing reply-target and handoff boundaries

It is not responsible for:

- parsing PDF content
- extracting candidate fields
- generating create/update business payloads
- uploading attachments
- executing actual Bitable writes

## Core rule

The current workspace is only the orchestrator. Actual resume-intake business execution belongs to the existing `workspace-resume-intake` worker session.

## What to read

Read these references as needed:

- `references/orchestration.md`
  - overall boundary, direct-worker vs orchestrated-worker model, inbound source, dispatch envelope purpose
- `references/session-targeting.md`
  - how to resolve the existing worker session safely
- `references/routing.md`
  - when to delegate and how to handle worker results
- `references/delegation-prompt.md`
  - what a valid orchestrator-to-worker handoff must contain
- `references/migration-notes.md`
  - staged migration notes and rollout boundaries
- `references/compat-doc-map.md`
  - mapping between current root docs and the new skill-reference layout
- `references/script-migration-plan.md`
  - cutover history and current script-path policy for the orchestrator
- `references/cutover-checklist.md`
  - pre-cutover checklist for switching live guidance to skill-local scripts without touching business semantics

## Stable scripts

A skill-local `scripts/` copy now exists for staged migration and parity checks:

- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/derive_session_target.py`
- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/prepare_dispatch_envelope.py`
- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/prepare_dispatch_envelope_from_inbound.py`
- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/prepare_sessions_send.py`
- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/prepare_confirmed_sessions_send.py`
- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/build_delegation_message.py`

Current live policy:

- use the skill-local copies as the canonical execution path
- keep guidance and examples aligned with `skills/resume-intake-orchestrator/scripts/*`
- if a regression appears after cutover, restore the deleted root copies from Git rather than improvising alternate paths

## Hard boundaries

- Do not run resume-intake business logic in this workspace.
- Do not create a fresh worker for actual resume-intake execution.
- Do not continue dispatch if helper output still has `input_files=[]` or `mode=unknown`.
- Do not hand-build worker payloads when a stable helper already exists.
- Do not assume a session-local reply means the Feishu user already received the result.

## Current runtime scope

This skill is now the live orchestration entry for the main workspace resume-intake path.

It centralizes dispatch guidance, skill-local helper usage, and worker handoff boundaries while leaving business execution in `workspace-resume-intake`.
