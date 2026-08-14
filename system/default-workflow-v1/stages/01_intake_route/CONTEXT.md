# 01_intake_route — Intake and Route

## Purpose

Turn the user request into a bounded task.

## Inputs

- User request + any referenced files
- `TASK.md` to fill
- `pipeline.md` to set routing
- `STATUS.md` to advance

## Process

1. Define objective, constraints, success criteria, deliverables.
2. Perform user-input checkpoint; ask only material questions.
3. Choose full or lightweight pipeline, record why.

## Outputs / exit criteria

- `TASK.md` complete.
- `pipeline.md` routing decision recorded.
- `STATUS.md` current_stage set to next stage.
- Log entry appended to `LOG.md`.

## Handoff

Next stage: 02_execute.
Allow `TASK.md`, `pipeline.md`, and `02_execute/CONTEXT.md`.
