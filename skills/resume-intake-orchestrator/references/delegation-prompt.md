# Delegation prompt reference

Use this reference to remember what a valid orchestrator-to-worker handoff must contain.

Minimum facts to carry into the worker handoff:

- original user request
- input file paths
- original display file name / `source_name` when available
- input mode
- message id when known
- exact reply target constraint

Core expectation:

- the orchestrator only dispatches
- the worker performs actual resume-intake execution
- the worker returns one formal result or blocker

Prefer the skill-local helpers instead of hand-writing delegation text:

- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/prepare_dispatch_envelope.py`
- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/prepare_dispatch_envelope_from_inbound.py`
- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/prepare_sessions_send.py`
- `/Users/jianfengxu/.openclaw/workspace/skills/resume-intake-orchestrator/scripts/prepare_confirmed_sessions_send.py`

Cutover note:

- the skill-local copies under `skills/resume-intake-orchestrator/scripts/` are now the default path for delegation helpers.
