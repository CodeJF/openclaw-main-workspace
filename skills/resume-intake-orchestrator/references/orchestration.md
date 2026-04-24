# Orchestration reference

Use this reference to understand the architecture boundary.

## Direct worker vs orchestrated worker

Direct worker path is usually more stable because the worker receives original inbound input and directly runs the business skill.

Orchestrated path introduces an extra protocol-conversion layer:

1. current workspace receives the original inbound message
2. current workspace normalizes facts into a dispatch envelope
3. worker consumes the normalized envelope
4. worker returns one formal result/blocker
5. orchestrator explicitly replies to the original user/channel

## Inbound source of truth

For this workflow, the current user message is the inbound fact source.

Typical facts may appear in:

- `[media attached: ... | ...]`
- `System: Feishu[...] [msg:om_xxx, file, ...]`
- `[File: /path/to/file]`
- `<file name="..." mime="...">`

## Why dispatch envelope exists

The worker should not need to understand every channel's raw message shape.

The dispatch envelope normalizes:

- input files
- input mode
- source/display file name
- message id
- reply target constraints

## Most common failure boundaries

When direct path works but orchestrated path fails, check these in order:

1. input extraction
2. dispatch envelope quality
3. guarded payload usage in worker
4. explicit return to the original channel/user
