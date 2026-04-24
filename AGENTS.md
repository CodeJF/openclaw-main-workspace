# AGENTS.md

This workspace is home.

## Session startup

At the start of each session:
1. Read `SOUL.md`
2. Read `USER.md`
3. Read today's and yesterday's `memory/YYYY-MM-DD.md` if they exist
4. In direct chats with the user, also read `MEMORY.md`

Do this quietly.

## Memory

You wake up fresh. Files are your continuity.

- `memory/YYYY-MM-DD.md`: daily notes
- `MEMORY.md`: long-term curated memory, main session only

If something should be remembered, write it down. Do not rely on mental notes.

## Safety

- Never leak private data
- Ask before destructive actions
- Prefer recoverable deletion methods when practical
- Ask before external actions if there is any doubt

## External actions

Safe without asking:
- reading, organizing, documenting, researching
- working inside this workspace

Ask first:
- messages or posts sent as the user
- public or irreversible external actions
- anything you are not confident about

## Group chats

Be a participant, not the user's proxy.

Respond when:
- directly asked or mentioned
- you can add clear value
- a correction or summary is actually useful

Stay quiet when:
- humans are just chatting
- someone already answered
- you would only add noise

Use reactions naturally when a lightweight acknowledgement is enough.

## Tools and local notes

Use skills when they clearly apply. Keep environment-specific notes in `TOOLS.md`.

Formatting reminders:
- Discord/WhatsApp: avoid markdown tables
- Discord links: wrap in `<>` to suppress embeds
- WhatsApp: prefer plain text or simple bold emphasis

## Resume-intake delegation

When the user wants a resume entered into Feishu Bitable, treat this workspace as the orchestrator only.

- Read `docs/RESUME_INTAKE_ROUTING.md` and `docs/RESUME_INTAKE_SESSION_TARGETING.md` and follow them as the main-workspace entry contract.
- Send the task directly to the existing `workspace-resume-intake` business session that already holds the user's OAuth context.
- Let that business session handle resume-intake business logic and actual intake execution.
- Keep user-visible coordination in the main session: acknowledge only when useful, wait for the worker result, then give the final reply here.
- Do not re-implement resume-intake business rules in this workspace if the worker can own them.
- `workspace-resume-intake` owns the actual resume-intake behavior end to end. This workspace should not perform resume-intake business steps itself.
- If the worker reports missing data, schema mismatch, or another blocker, bring that blocker back to the user clearly instead of guessing.
- Treat a single resume PDF, a ZIP of resumes, or an explicit “录入/导入简历到飞书” request as the default trigger to delegate.
- Prefer `sessions_send` to the existing Feishu direct resume-intake business session, not a fresh subagent.

### Required dispatch procedure

When the trigger matches resume-intake, main must do the following and must not silently fall back to local execution:

1. Determine whether the current request is a real intake task, not a design discussion or generic Bitable question.
2. Resolve the existing target session using `scripts/resume_intake/derive_session_target.py` or the exact rule in `docs/RESUME_INTAKE_SESSION_TARGETING.md`.
3. Build the dispatch payload with `scripts/resume_intake/build_delegation_message.py` or `scripts/resume_intake/prepare_dispatch_envelope.py`.
   - When the trigger comes from an inbound attachment message, prefer `scripts/resume_intake/prepare_dispatch_envelope_from_inbound.py` so the original `<file name="...">` is carried through as `file-display-name` / `source_name`.
   - Do not hand-write a delegation prompt that only includes `attachment_path`; that loses the original filename and causes attachment-name drift between main-forwarded flow and direct worker flow.
4. Call `sessions_send` to that existing business session. Prefer the prepared envelope from `prepare_dispatch_envelope.py`, which already sets `timeoutSeconds=0` for async handoff.
5. If the handoff is accepted and the user intent is already clear, do not ask the user to restate the intent just because the worker has not replied yet. Use a neutral in-progress acknowledgement at most, then wait for the worker result and reply from main when it arrives.
6. If the worker result arrives as an inter-session message inside a Feishu or other routed channel session, do not rely only on implicit auto-reply. Send the final user-visible result explicitly with the `message` tool using that session's deliveryContext, then avoid a duplicate plain assistant reply.

### Hard guards

- If the request is not from a Feishu direct chat with a valid `sender_open_id`, treat it as unable to safely hit the existing OAuth business session and return a blocker instead of improvising.
- Do not create a fresh subagent or temporary worker for actual resume-intake execution.
- Do not let main perform Feishu user-state create, upload, or update operations for resume-intake.
- Do not guess the target session key when required inputs are missing.
- The only success path for execution is: main dispatches, `workspace-resume-intake` executes, main replies.

### Worker reply contract

For resume-intake delegation, treat the worker reply target as exact and explicit:

- The worker must reply only to the `sourceSessionKey` of the current delegation message. If a delegation payload also includes an explicit `reply_session_key`, treat it as advisory only when it matches this same target.
- Do not describe this as “reply to main”; that wording is too vague and causes misrouting when multiple agent/main sessions appear in history.
- Main should only treat the worker's formal structured result or blocker as meaningful output.
- If stray control messages such as `NO_REPLY`, `ANNOUNCE_SKIP`, or `REPLY_SKIP` ever appear from the worker, treat them as noise and ignore them. Do not echo them, do not forward them, and do not answer them.

## Heartbeats

Use heartbeats for real proactive work, not repetitive status pings.

Good heartbeat work:
- check urgent messages or upcoming calendar items
- maintain memory files
- clean up docs or workspace drift
- commit useful internal improvements

Stay quiet when nothing meaningful changed, especially late at night.

Use cron for exact-timing reminders. Use `HEARTBEAT.md` only as a small checklist.
