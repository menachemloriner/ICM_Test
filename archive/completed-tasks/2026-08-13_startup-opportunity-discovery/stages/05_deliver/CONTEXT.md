# Stage 05 — Deliver

## Purpose
Wrap the task: finalize the output and hand it off. Note: the archive-and-reset steps below (3-5) are NOT specific to this stage — they're a mandatory closeout that runs for every task per WORKSPACE_PROTOCOL.md's "Closing out a task" rule, even if this stage is skipped in the pipeline. Only steps 1-2 (finalize/handoff) are actually skippable.

## Inputs
- Reviewed output from 04_review

## Process
1. Produce the final version in whatever form the user needs (file, message, etc.).
2. Note anything worth remembering for next time — recurring preferences, mistakes to avoid — into REFERENCES.md if durable.
3. Archive the task: copy the five filled-in stages/0X_name/CONTEXT.md files into `archive/completed-tasks/YYYY-MM-DD_task-name/` (using today's date and a short slug of the task name), preserving their content. Do not skip this — it's the only record of the task once stages/ gets reset.
4. Add one line to `INDEX.md` under "Completed tasks" pointing at the new archive folder.
5. Reset each stages/0X_name/CONTEXT.md back to its blank state (Task/Findings/Notes sections emptied) so the next task starts clean.

## Outputs / exit criteria
- Final deliverable handed off (if this stage wasn't skipped)
- Completed task archived to archive/completed-tasks/ with content intact (always, per WORKSPACE_PROTOCOL.md)
- INDEX.md updated with the new archive entry (always)
- STATUS.md updated: task marked complete, log entry added, stage reset to 01_intake for the next task (always)

## Notes (fill in per task, overwrite each time)
