# 03_review - Review

## Purpose

Verify the work product against the task criteria and record substantive review
evidence before delivery.

## Inputs

- `TASK.md`: success criteria, required deliverables, constraints, and direct review references.
- `pipeline.md`: review decision and reopen condition.
- `STATUS.md`: latest execute exit, material decisions, unresolved questions, and named work products.
- Prior `HANDOFF.md` when present and addressed to `03_review`: one-successor instructions and allowed files.
- Work products named in the latest stage exit: artifacts produced by `02_execute`.
- Direct review references already listed in `TASK.md` or the handoff: only the declared path or URL and declared scope.

## Process

1. Read only the listed inputs and work products. Do not follow references transitively.
2. Check every success criterion and record the result with an evidence location.
3. Verify material claims, calculations, citations, changed files, or other task-specific proof when applicable.
4. Reopen `02_execute` when the pipeline reopen condition occurs or a required check fails. Record the reason and the needed revision in `STATUS.md`.
5. Update `STATUS.md` with a completed `Latest Stage Exit` for `03_review`, including outputs, checks and results, outstanding issues, and the direct inputs allowed for `04_deliver_archive`.
6. Create a one-successor `HANDOFF.md` only when the next stage needs instructions not already present in `STATUS.md`.

## Outputs / exit criteria

- Every success criterion has a recorded pass, fail, or accepted unresolved result with evidence.
- Material claims and task-specific checks have been verified when applicable.
- Required revisions are complete, or the unresolved issue and decision are recorded.
- The latest stage exit identifies verified work products and archive-stage inputs.

## Handoff

Next stage: `04_deliver_archive`.
Allow only `TASK.md`, `pipeline.md`, `STATUS.md`, a current handoff when present,
the declared deliverables, the review evidence named in the latest exit, and
direct review references already declared in `TASK.md` or the handoff.
