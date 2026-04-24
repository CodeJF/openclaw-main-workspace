# Session targeting reference

Current stable worker session pattern:

```text
agent:resume-intake-local-test:feishu:direct:<sender_open_id>
```

Use the existing helper for targeting:

- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/derive_session_target.py`

## Rules

- Only target the existing OAuth-backed worker session.
- Do not create a new worker for actual business execution.
- If `sender_open_id` or Feishu direct-chat identity cannot be established safely, stop and report a blocker.
