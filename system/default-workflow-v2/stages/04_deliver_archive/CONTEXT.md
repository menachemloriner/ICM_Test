# 04_deliver_archive - Deliver and Archive

## Purpose

Finalize the handoff, verify structural closeout requirements, and preserve the
complete task-local workflow snapshot.

## Inputs

- `TASK.md`: declared deliverable paths and stable task scope.
- `pipeline.md`: stage sequence, review decision, self-check when review is skipped, and reopen condition.
- `STATUS.md`: current stage, latest stage exit, material decisions, and review evidence.
- Current `HANDOFF.md` when present: one-successor delivery instructions.
- Declared deliverables and review evidence needed for closeout: only the paths named in `TASK.md` or the latest stage exit.
- `meta/WORKFLOW_MANIFEST.md`: workflow snapshot identity and source hashes.
- `tools/archive-task.ps1`: structural archive helper to invoke for final checks and the archive move.

## Process

1. Read only the listed task files, declared deliverables, and review evidence needed for closeout.
2. Confirm every declared deliverable path exists.
3. Confirm the review decision was satisfied: a completed review exit exists when review is required, or the recorded self-check and reopen condition exist when review is skipped.
4. Confirm `meta/WORKFLOW_MANIFEST.md` exists and declares the task workflow.
5. Invoke `tools/archive-task.ps1` for the final structural checks and archive move.
6. Treat file-existence and state checks as structural only. They do not prove substantive quality; substantive checks belong in the latest stage exit and review record.

## Outputs / exit criteria

- Declared deliverables and required evidence are structurally present.
- The archive helper creates `meta/ARCHIVE.md`, moves the complete task directory, updates `INDEX.md`, resets root status, and records the closeout.
- The archive record states that the helper verified structure and file presence only.

## Handoff

None. The workspace is ready for the next task.
