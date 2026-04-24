# Migration notes

This skill is introduced as a low-risk migration step.

## Current scope

- skill-local script copies now exist for staged migration
- no live path replacement yet
- no root-script removal yet
- no business execution changes

## Near-term intent

- centralize orchestration rules here
- gradually shrink workspace-level duplication in `AGENTS.md` and root `docs/`
- keep existing scripts and business skill untouched until the orchestrator skill proves stable as the primary knowledge entry

## Do not do yet

- do not delete `scripts/resume_intake/*`
- do not delete current root docs
- do not switch the live path solely because the skill-local copies now exist
