# 04_deliver_archive — Deliver and Archive

## Purpose
Finalize the task, hand off the result when needed, and preserve a complete task
record without changing the reusable workflow.

## Inputs
- Reviewed work product
- `TASK.md` required-deliverables list
- Task-local `STATUS.md` and `pipeline.md`

## Process
1. Perform the final handoff when the task needs a formal handoff. A simple artifact
   may only need a concise completion note.
2. Verify every required deliverable exists at the stated path.
3. Add an archive note recording the final status, workflow version, and any accepted
   limitations.
4. Move the entire task directory into
   `archive/completed-tasks/YYYY-MM-DD_short-task-slug/`. Preserve stage contracts,
   custom stages, work files, deliverables, and task logs together.
5. Add a dated entry to the root `INDEX.md`.
6. Clear the root `STATUS.md` active-task pointer and add a dated closeout log.

## Outputs / exit criteria
- Final deliverables are handed off or explicitly marked complete.
- All required deliverables were verified.
- The complete task directory is archived.
- `INDEX.md` and root `STATUS.md` are current.

## Notes (fill in per task)
