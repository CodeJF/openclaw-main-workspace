# Script migration plan

This reference defines the **next-stage script migration plan** for `resume-intake-orchestrator`.

Current policy:

- do **not** move live scripts yet
- do **not** change current live imports/calls yet
- do **not** make orchestrator skill the only runtime path yet

The goal here is only to define a safe future script layout and migration order.

## Current live scripts still in root workspace

These scripts remain the current source of truth for live orchestration behavior:

- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/derive_session_target.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/build_delegation_message.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_sessions_send.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_confirmed_sessions_send.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_dispatch_envelope.py`
- `/Users/jianfengxu/.openclaw/workspace/scripts/resume_intake/prepare_dispatch_envelope_from_inbound.py`

## Target future layout

When the orchestrator skill is ready to become self-contained, the target layout should look like this:

```text
skills/
  resume-intake-orchestrator/
    SKILL.md
    scripts/
      derive_session_target.py
      build_delegation_message.py
      prepare_sessions_send.py
      prepare_confirmed_sessions_send.py
      prepare_dispatch_envelope.py
      prepare_dispatch_envelope_from_inbound.py
    references/
      orchestration.md
      session-targeting.md
      routing.md
      delegation-prompt.md
      migration-notes.md
      compat-doc-map.md
      script-migration-plan.md
```

## Migration order

Use this order only in a later migration phase:

### Step 1: Copy, do not replace

- copy the root orchestrator scripts into `skills/resume-intake-orchestrator/scripts/`
- keep root scripts untouched
- verify the copied scripts still run correctly from the new location
- update the skill references to mention both paths during transition

### Step 2: Make skill references prefer local scripts

After copied scripts are verified:

- update `SKILL.md` to prefer `scripts/...` under the skill directory
- keep a compatibility note pointing to the root copies

### Step 3: Compare behavior, not just file contents

Before any live cutover:

- run the same attachment-based dispatch preparation through both old-root and new-skill script paths
- compare outputs for:
  - `input_files`
  - `input_mode`
  - `source_name`
  - `sessionKey`
  - final `sessions_send` envelope
- require identical or intentionally-documented output before cutover

### Step 4: Cut live references only after stable parity

Only after parity is confirmed:

- update live docs / entry instructions to point to the skill-local scripts first
- leave the root scripts in place for a compatibility window

### Step 5: Remove root copies last

Only after a stable observation window:

- delete the redundant root copies
- keep the skill-local scripts as the only canonical copies

## Cutover gates

Do not move to live cutover unless all are true:

1. skill-local scripts produce the same envelope output as root scripts
2. single PDF attachment flow still resolves to `single_pdf`
3. empty-input and `mode=unknown` blocker behavior remains identical
4. worker targeting remains unchanged
5. no existing workspace docs or entry rules silently point at removed root paths

## Rollback boundary

If any discrepancy appears during migration:

- revert references back to root scripts
- keep skill-local copies as inactive staging files
- do not delete root scripts

## Why this plan is conservative

The root scripts are already on the live path. Moving them too early would turn a documentation/skill migration into a runtime refactor.

This plan keeps current business stable while still giving the orchestrator skill a clear path toward becoming self-contained later.
