# Routing reference

Delegate when the request is an actual resume-intake task, for example:

- single PDF resume for Feishu intake
- ZIP batch of resumes
- explicit request to import a resume into the hiring table

Do not delegate when the user is only asking about:

- architecture
- rules
- status
- design discussion
- generic Bitable operations unrelated to the fixed resume-intake business flow

## Handoff rules

- Prefer `prepare_dispatch_envelope_from_inbound.py` when the source request is a raw attachment message.
- When the inbound text contains markdown fences, JSON snippets, or multiple shell-sensitive lines, prefer `--inbound-text-file` instead of shell-inlining the whole message.
- If helper output still has `input_files=[]`, stop.
- If helper output still has `mode=unknown`, stop.
- Only after the envelope is valid should the orchestrator call `sessions_send`.
- For orchestrator -> worker dispatch, prefer the helper-generated `sessions_send` arguments as-is, including `timeoutSeconds=0`; do not turn the handoff into a long synchronous wait unless the user explicitly needs blocking behavior.
- Worker returns one formal result or blocker to the designated source session.
- Orchestrator is responsible for the final explicit user-facing reply.
