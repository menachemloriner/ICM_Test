# 02_execute - Execute

## Purpose

Produce the work product within the task scope and record the evidence needed by
the next stage.

## Inputs

- `TASK.md`: objective, constraints, success criteria, deliverables, and direct source references.
- `pipeline.md`: selected stage sequence, review decision, reopen condition, and custom-stage reason when present.
- `STATUS.md`: current action, material decisions, unresolved questions, and latest stage exit.
- `HANDOFF.md` when present and addressed to `02_execute`: one-successor instructions and allowed files.
- Direct source references listed in `TASK.md` or the current handoff: only the declared path or URL and declared scope.

## Process

1. Read only the inputs listed above. The existence of a reference in an allowed file does not authorize a transitive read of files named inside it.
2. If an additional file is needed, record the reason in `LOG.md` before reading it and add the direct reference to `STATUS.md` or `HANDOFF.md`.
3. Produce work only in `work/`, `deliverables/`, or the explicit output path named in `TASK.md`.
4. Put material decisions and unresolved questions in `STATUS.md`; append detailed history and exploration to `LOG.md`.
5. Update `STATUS.md` with a completed `Latest Stage Exit` containing output paths, checks run and their result, remaining issues, and the direct inputs allowed for the next stage.
6. Create a short `HANDOFF.md` only when a real transfer to one successor stage, session, or worker needs instructions not already captured by `STATUS.md`.

## Outputs / exit criteria

- The planned work product exists at the declared output path.
- Material decisions and unresolved questions are visible in `STATUS.md`.
- `LOG.md` contains the dated execution history.
- The latest stage exit identifies outputs, checks and results, issues, and the next stage's direct inputs.

## Handoff

Next stage: `03_review` when review is required, otherwise `04_deliver_archive`.
Allow only the files named in `TASK.md`, `pipeline.md`, `STATUS.md`, a current
one-successor handoff when present, and the declared work products or direct
review references needed by the next stage.
