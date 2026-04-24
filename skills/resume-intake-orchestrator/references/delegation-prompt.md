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

Prefer the stable helpers in the workspace root instead of hand-writing delegation text:

- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_dispatch_envelope.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_dispatch_envelope_from_inbound.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_sessions_send.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_confirmed_sessions_send.py`
