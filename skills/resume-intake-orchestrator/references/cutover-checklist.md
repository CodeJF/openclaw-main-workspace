# Cutover checklist

Use this reference only when preparing to switch live orchestrator guidance from the former root script copies to the skill-local `scripts/` copies.

This checklist records the cutover gate for the 2026-04-24 switch and remains the reference for any future re-check.

## Preconditions

All of these must already be true:

1. skill-local script copies exist
2. representative old-path vs new-path parity checks have passed
3. root scripts are still intact
4. current business path is stable

Recorded status on 2026-04-24: satisfied before cutover.

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

During any future compatibility window:

- keep guidance aligned to the skill-local scripts
- use Git restoration rather than shadow copies if rollback is needed
- avoid reviving duplicate root paths casually

## Explicit no-go conditions

Do **not** cut over if any of these are true:

- parity checks are stale or incomplete
- recent resume-intake incidents are unresolved
- production worker routing is under investigation
- someone is relying on undocumented root-path behavior

## Rollback

If a cutover causes confusion or drift:

1. restore the deleted root copies from Git if needed
2. keep the skill-local copies as the intended canonical path unless rollback requires otherwise
3. re-establish parity before attempting another cutover
