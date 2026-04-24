# Session targeting reference

Current stable worker session pattern:

```text
agent:resume-intake-local-test:feishu:direct:<sender_open_id>
```

Prefer the skill-local helper for targeting:

- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/derive_session_target.py`

Compatibility note:

- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/derive_session_target.py` remains available as the live-compatible root copy during migration.

## Rules

- Only target the existing OAuth-backed worker session.
- Do not create a new worker for actual business execution.
- If `sender_open_id` or Feishu direct-chat identity cannot be established safely, stop and report a blocker.
