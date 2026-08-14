# Default Workflow v1

This is the reusable workflow source. It is copied into each new task and must not
be edited during task execution.

## Stages

1. `01_intake_route` — understand the task and choose the pipeline.
2. `02_execute` — produce the work.
3. `03_review` — verify the work.
4. `04_deliver_archive` — hand off and archive the complete task directory.

## Routing rule

Use the default four-stage pipeline for most mid-sized tasks. Add custom stages only
when a distinct requirement needs its own inputs, outputs, checkpoint, or verification
standard. Custom stages are created from `templates/CONTEXT_template.md` inside the
task directory and are listed in the task's `pipeline.md`.

## Context budget rule

Keep `STATUS.md` files and stage contracts small. Logs live in `ROOT_LOG.md` and
`task/LOG.md` and are not read during session start. Each stage contract must name
the files it needs under `Inputs` or `Handoff`; read only those files. A stage may
request another file only after recording why in `task/LOG.md`. The workflow routes
attention through the task; it does not require the whole codebase to be loaded into
context.

## Lightweight routing

Use `01_intake_route → 02_execute → 04_deliver_archive` for low-risk, clearly bounded
tasks when execution includes a sufficient self-check and there are no material
claims, calculations, or independent review requirements. Record the skipped Review
stage and the reason in `pipeline.md`.

## User-input rule

At intake, identify decisions that could materially affect scope, priorities, risk,
deliverables, or irreversible actions. Ask the user before proceeding unless the
answer is obvious from the request or existing instructions. Record the decision and
the reason no question was needed when the answer is obvious.

## Versioning rule

Each task records `default-workflow-v1` in its manifest. Future changes create a new
workflow version; they do not silently change the meaning of an existing task.
