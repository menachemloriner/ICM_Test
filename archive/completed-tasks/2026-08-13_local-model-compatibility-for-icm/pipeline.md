# Pipeline

## Workflow
default-workflow-v1

## Stages
1. 01_intake_route
2. 02_execute
3. 03_review
4. 04_deliver_archive

## Custom stages
None.

## Routing decision
Full default pipeline used (not lightweight). Reason: success criteria include a
sourcing requirement ("every claim... is sourced") — that's a material verification
requirement, so 03_review is not skipped. Task is also intentionally multi-session
to exercise a mid-stage handoff test, which needs the stage boundaries intact.

## Context plan
Active stage: 03_review (01_intake_route, 02_execute complete)
Files to read now: this pipeline, `TASK.md`, task `STATUS.md`, the 03_review stage
contract, and `deliverables/local-model-compatibility-report.md`.

## Handoff note (for whichever model picks this up next)
This task is a deliberate test of switching AI models mid-stage. If you are not
Claude: read `WORKSPACE_PROTOCOL.md` at the workspace root first, then this file,
then `STATUS.md` in this task directory, then the active stage's `CONTEXT.md`. Do
the work the stage contract describes — do not restart from scratch or re-ask
questions already answered in `TASK.md`. When you finish your portion, update this
task's `STATUS.md` log with what you did and what's left, so the handoff stays clean
regardless of which model reads it next.

**This is the actual handoff point.** 01_intake_route and 02_execute were done by
Claude in one continuous session. 03_review (checking the deliverable against
TASK.md's 5 success criteria) is intentionally left for whichever model Max switches
to next, so the test measures a real mid-task pickup, not just a fresh-task start.
