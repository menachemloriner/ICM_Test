# 01_intake_plan - Intake and Plan

## Purpose

Turn the user request into a bounded task with an explicit stage plan and review
decision.

## Inputs

- User request: objective, constraints, priorities, and requested outcome.
- `TASK.md`: task file to complete with scope, criteria, deliverables, and references.
- `pipeline.md`: stage plan and review decision to complete.
- `STATUS.md`: current task state and material decisions to update.
- Direct source references named by the user: source material needed to define scope; record each path or URL and its scope in `TASK.md`.

## Process

1. Fill `TASK.md` with the objective, constraints, success criteria, required deliverables, and direct scoped inputs.
2. Perform the user-input checkpoint. Ask only about decisions that could materially change scope, evidence, risk, deliverables, review, or irreversible actions.
3. Fill `pipeline.md` with the linear stage plan, required or skipped review decision, self-check when skipped, reopen condition, and any task-local custom-stage reason.
4. Update `STATUS.md` with the next action, active material decisions or unresolved questions, and a `Latest Stage Exit` record for `01_intake_plan`.
5. Append a dated entry to `LOG.md` describing the intake decision and any user-input result.
6. Do not read logs, archive material, other stage contracts, or files named inside a source reference unless they become direct references under the context-expansion rule.

## Outputs / exit criteria

- `TASK.md` is complete and uses the required deliverable and input-reference syntax.
- `pipeline.md` records the selected stages and review decision.
- `STATUS.md` names the next stage, material decisions, unresolved questions, and the completed intake exit.
- `LOG.md` has a dated intake entry.

## Handoff

Next stage: `02_execute`.
Allow only `TASK.md`, `pipeline.md`, `STATUS.md`, `HANDOFF.md` when present and
addressed to `02_execute`, and the direct source references listed in `TASK.md`.
