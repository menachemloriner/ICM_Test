# Identity

You are helping Max Loriner.

## Rules

- Write in plain, clear language.
- Follow the task's user-input checkpoint; do not make material assumptions silently.
- When you are unsure, say so.

## Workspace protocol

This folder uses a versioned, task-local workflow. The reusable default workflow
lives in `system/default-workflow-v2/`. Every new task gets its own directory
under `tasks/`, receives a working copy of the default stage contracts and
templates, and records a `meta/WORKFLOW_MANIFEST.md` snapshot. Never edit the
default workflow while working on a task.

The root `STATUS.md` is only a pointer to the active task. The task's own
`STATUS.md` contains the current stage, pipeline, next action, active material
decisions, unresolved questions, and latest stage exit.

The root status file also contains a small machine-readable YAML block between
`machine-state:start` and `machine-state:end`. Tools use that block to find the
active task and stage without parsing the prose. Humans can still read the rest
of the file normally.

### Session start

1. Read root `STATUS.md`.
2. Read the active task's `STATUS.md`.
3. Read the active stage contract in that task's `stages/` directory.
4. Read exactly the files listed in that contract's `Inputs` and `Handoff` sections. Do not read logs, other stage contracts, archive material, or any other directory at session start.
5. Perform the work defined by the stage.
6. Before ending, append a dated entry to the task `LOG.md` and update the task `STATUS.md` machine-state, current stage, next action, material decisions, and latest stage exit, or record what remains open.

### Context minimization

The active stage contract is the context boundary. Every allowed input must name
one direct path or URL and its purpose, with a scope when needed. A referenced
file does not expand access transitively to files named inside it. If a file
outside the allowed set is needed, record the reason in `LOG.md` before opening
it and add the direct reference to `STATUS.md` or `HANDOFF.md`.

`STATUS.md` holds active material decisions and unresolved questions. `LOG.md`
holds dated history and exploratory detail; it is not current authority.

### Starting a task

1. Create a unique directory such as `tasks/YYYY-MM-DD_short-task-slug/`.
2. Use `tools/new-task.ps1` when available. It creates the directory, copies the v2 stages and templates, initializes `TASK.md`, `pipeline.md`, compact `STATUS.md`, and `LOG.md`, creates `work/` and `deliverables/`, and writes the workflow manifest.
3. Fill in `TASK.md` with the objective, constraints, success criteria, direct scoped inputs, and required deliverables.
4. Start at `01_intake_plan`. That stage performs the user-input checkpoint, chooses the stage plan, and records the review decision. Planning does not select a model or provider.
5. If a custom stage is necessary, create it only inside the task directory from `templates/CONTEXT_template.md` and record its distinct requirement in `pipeline.md`.

Use `tools/copy-task-assets.ps1` to copy source files, folders, or finished
project directories into the active task's `work/` or `deliverables/` folder.

### Default pipeline

The default workflow has four generalized stages:

1. `01_intake_plan` - define the task, stage plan, and review decision.
2. `02_execute` - perform the research, analysis, writing, building, or other work.
3. `03_review` - verify the result when review is required.
4. `04_deliver_archive` - hand off, verify structural closeout, and archive the complete task directory.

The normal path is:

`01_intake_plan -> 02_execute -> 03_review -> 04_deliver_archive`

For a low-risk, clearly bounded task, intake may select:

`01_intake_plan -> 02_execute -> 04_deliver_archive`

Only skip review when execution includes a recorded self-check and the pipeline
contains an explicit condition for reopening execution. Archive closeout is never
skipped.

### Custom stages

The only default extension mechanism is a task-local custom stage. A custom stage
must have a distinct input, output, checkpoint, or proof requirement that the
default stages cannot safely handle. It remains local to the task until repeated
use demonstrates a reason to promote it into a future workflow version.

`HANDOFF.md` is optional and one-successor only. Create it only when a real
transfer to another stage, session, or worker needs instructions not already
provided by `STATUS.md`. It may narrow the next action but cannot override
`TASK.md` or `pipeline.md`.

### Closing out a task

The deliver-and-archive stage always performs these steps:

1. Finalize or hand off the deliverable when formal handoff is needed.
2. Verify every required deliverable listed in `TASK.md` exists and that the review decision was satisfied.
3. Confirm `meta/WORKFLOW_MANIFEST.md` exists.
4. Invoke `tools/archive-task.ps1` for structural checks, the archive record, the archive move, the `INDEX.md` update, the root status reset, and the root log closeout.

Archive checks verify declared paths and task-state structure only. They do not
substitute for stage evidence or substantive review. The task-local stage copies
and workflow manifest preserve the workflow snapshot in the durable archive.

The default workflow remains untouched and ready for the next task. Existing v1
workflows and historical task directories are legacy records and are not rewritten.

### Durable archive templates

Templates for durable material live in `system/templates/`:

- `decision_template.md` for recorded decisions.
- `note_template.md` for durable notes.
- `project_template.md` for ongoing projects.

Task workflow templates live in `system/default-workflow-v2/templates/`.

## Archive protocol

`archive/` holds durable material:

- `archive/notes/` - atomic notes and observations.
- `archive/projects/` - ongoing multi-session efforts.
- `archive/decisions/` - decisions and their reasoning.
- `archive/completed-tasks/` - complete archived task directories.

`INDEX.md` is the front door to the archive. Use dates for log and archive
entries. Do not invent dates for historical events; preserve the original date
when known.

## Weekly review

1. Confirm the root `STATUS.md` points to the correct active task.
2. Check that every completed task has been moved into the archive.
3. Confirm each archived task's declared deliverables exist.
4. Add missing archive entries to `INDEX.md`.
5. Review `REFERENCES.md` and remove stale material.
