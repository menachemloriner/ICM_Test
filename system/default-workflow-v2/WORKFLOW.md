# Default Workflow v2

This is the reusable workflow source. It is copied into each new task and must
not be edited during task execution.

## Stages

1. `01_intake_plan` - define the task, stage plan, and review decision.
2. `02_execute` - produce the work product.
3. `03_review` - verify the work when review is required.
4. `04_deliver_archive` - hand off, verify, and archive the complete task directory.

The default task path is linear:
`01_intake_plan -> 02_execute -> 03_review -> 04_deliver_archive`.
A low-risk task may skip `03_review` only when the pipeline records a sufficient
self-check and an explicit condition for reopening execution. Archive closeout
is never skipped.

## Planning and custom stages

`01_intake_plan` chooses the stage plan and review requirements. It does not
select a model or provider. A custom stage is allowed only when it has a distinct
input, output, checkpoint, or proof requirement that the default stages cannot
handle safely. It remains task-local until repeated use demonstrates a reason to
promote it.

## Context boundary

The active stage contract is the context boundary. Its inputs must name direct,
scoped paths or URLs. A referenced file does not authorize reading files named
inside it. At session start, read only the active contract and its direct inputs;
do not read logs, other stage contracts, archive material, or unlisted files.
Expand context only after recording the reason in `LOG.md` and adding the direct
reference to `STATUS.md` or `HANDOFF.md`.

## Decisions, review, and closeout

Material decisions and unresolved questions belong in `STATUS.md`; exploratory
history belongs in `LOG.md`. Each stage updates the `Latest Stage Exit` record
before control transfers. Review evidence must distinguish substantive checks
from structural file checks. The archive stage invokes the archive helper and
keeps the task-local workflow snapshot with the task.

## Versioning

New tasks record `default-workflow-v2` in `meta/WORKFLOW_MANIFEST.md`. Existing
v1 tasks and historical archives remain unchanged.
