# Cutover checklist

Use this reference only when preparing to switch live orchestrator guidance from the root `scripts/resume_intake/*` copies to the skill-local `scripts/` copies.

This is a **cutover-prep checklist**, not permission to cut over immediately.

## Preconditions

All of these must already be true:

1. skill-local script copies exist
2. representative old-path vs new-path parity checks have passed
3. root scripts are still intact
4. current business path is stable

## What cutover means here

For this migration, cutover means only:

- live docs and entry instructions start pointing to `skills/resume-intake-orchestrator/scripts/*` first
- root script copies remain in place during the compatibility window

It does **not** mean:

- deleting root scripts
- changing worker business logic
- changing session-targeting rules
- changing dispatch-envelope semantics
- changing Feishu production configuration

## Pre-cutover checks

Before changing any live-facing instruction paths, verify all of the following again:

### 1. Session targeting parity

Confirm old and new paths still agree on:

- valid `sender_open_id` -> same `sessionKey`
- invalid `sender_open_id` -> same blocker behavior
- non-Feishu / non-direct assumptions -> same blocker behavior

### 2. Dispatch envelope parity

Confirm old and new paths still agree on:

- `single_pdf`
- `zip_batch`
- `multi_pdf`
- no-files / `unknown`
- `source_name` propagation
- final `sessions_send` arguments

### 3. Worker-boundary parity

Confirm the cutover does not change these boundaries:

- orchestrator only dispatches
- worker still performs business execution
- reply target remains the designated source session only

### 4. Documentation impact scan

Before cutover, scan for remaining references to root script paths in active guidance files.

Especially check:

- `AGENTS.md`
- `skills/resume-intake-orchestrator/SKILL.md`
- `skills/resume-intake-orchestrator/references/*`
- root `docs/RESUME_INTAKE_*.md`

## Recommended cutover order

When the team decides the cutover is worth doing, use this order:

1. update active skill references first
2. update root compatibility docs second
3. keep root scripts untouched during the observation window
4. observe real usage before considering any deletion

## Compatibility window expectations

During the compatibility window:

- root scripts remain available
- old docs may still mention root paths in compatibility notes
- any regression should revert guidance back to the root copies first

## Explicit no-go conditions

Do **not** cut over if any of these are true:

- parity checks are stale or incomplete
- recent resume-intake incidents are unresolved
- production worker routing is under investigation
- someone is relying on undocumented root-path behavior

## Rollback

If a cutover causes confusion or drift:

1. point live guidance back to `scripts/resume_intake/*`
2. keep skill-local copies for staging only
3. do not delete either side until parity is re-established
