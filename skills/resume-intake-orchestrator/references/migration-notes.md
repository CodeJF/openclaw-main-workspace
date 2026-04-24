# Migration notes

This skill is introduced as a low-risk migration step.

## Current scope

- skill-local scripts are now the default orchestrator path
- root script copies are no longer the intended entry point
- no business execution semantics changed

## Near-term intent

- centralize orchestration rules here
- gradually shrink workspace-level duplication in `AGENTS.md` and root `docs/`
- keep existing scripts and business skill untouched until the orchestrator skill proves stable as the primary knowledge entry

## Do not do yet

- do not change worker business semantics during this migration
- do not delete current root docs solely for tidiness
- do not introduce alternate non-skill script paths
