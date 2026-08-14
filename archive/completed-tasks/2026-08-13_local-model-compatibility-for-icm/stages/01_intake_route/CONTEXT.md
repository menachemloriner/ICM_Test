# 01_intake_route — Intake and Route

## Purpose
Turn the user's request into a bounded task with clear success criteria, deliverables,
and an appropriate workflow.

## Inputs
- User request
- Relevant files or references identified by the request
- `TASK.md`, `STATUS.md`, and `pipeline.md` in the task directory

## Process
1. State the objective in one or two sentences.
2. Record constraints, assumptions, inputs, risks, and required deliverables.
3. Define observable success criteria and identify what must be verified.
4. Perform the user-input checkpoint. Ask the user about any non-obvious decision
   that materially affects scope, priorities, risk, deliverables, or an irreversible
   action. If no question is needed, record why the answer is obvious.
5. Choose the default four-stage pipeline unless a distinct requirement needs a
   separate stage, checkpoint, or verification standard.
6. For a low-risk, clearly bounded task, consider the lightweight pipeline that skips
   `03_review`. Record why the execution-stage self-check is sufficient.
7. If custom stages are needed, create them from the task-local template, add them to
   `pipeline.md`, and explain why the default pipeline was insufficient.

## Outputs / exit criteria
- `TASK.md` contains the objective, constraints, success criteria, inputs, and
  deliverables.
- `pipeline.md` records the chosen pipeline and any custom-stage rationale.
- The user-input checkpoint is recorded.
- The chosen full or lightweight pipeline is recorded with its rationale.
- The next stage and its starting inputs are clear in `STATUS.md`.

## Notes (fill in per task)
