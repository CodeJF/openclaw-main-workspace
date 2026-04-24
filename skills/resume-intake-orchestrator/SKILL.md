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
  - future plan for making the orchestrator skill self-contained without moving live scripts yet

## Stable scripts

Use these existing scripts in the workspace root. Do not move them as part of this skill bootstrap:

- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/derive_session_target.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_dispatch_envelope.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_dispatch_envelope_from_inbound.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_sessions_send.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_confirmed_sessions_send.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/build_delegation_message.py`

## Hard boundaries

- Do not run resume-intake business logic in this workspace.
- Do not create a fresh worker for actual resume-intake execution.
- Do not continue dispatch if helper output still has `input_files=[]` or `mode=unknown`.
- Do not hand-build worker payloads when a stable helper already exists.
- Do not assume a session-local reply means the Feishu user already received the result.

## Current bootstrap scope

This skill is currently a knowledge-entry skeleton only.

It exists to centralize orchestration guidance without changing the live routing path yet.
