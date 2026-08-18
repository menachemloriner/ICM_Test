# ICM_Test

ICM_Test is a file-based operating system for AI-assisted work. It turns an open-ended request into a bounded, reviewable, and recoverable task with explicit context, deliverables, stage handoffs, and durable archival.

The repository is designed for work that spans multiple sessions, requires careful source or file handling, or benefits from a visible record of what was decided, produced, checked, and preserved.

## Why this system exists

AI work can become difficult to reproduce when context is scattered across chats, temporary files, and undocumented decisions. ICM_Test addresses that problem by making the work state explicit:

- Every task has a defined scope, success criteria, inputs, and deliverables.
- Each workflow stage declares what it may read, what it must produce, and what it hands forward.
- Material decisions and unresolved questions stay visible in the task status.
- Detailed history is kept in a task log instead of being mistaken for current state.
- Completed tasks are archived as complete, self-contained records.
- Workflow definitions are versioned so historical tasks do not silently change when the default workflow evolves.

## How the system works

The system uses a one-active-task model. The root `STATUS.md` points to the current task and stage. The task directory contains the working state; the root files provide workspace-level navigation and control.

The normal lifecycle is:

```text
User request
    |
    v
01_intake_plan -> 02_execute -> 03_review -> 04_deliver_archive
                                      |              |
                                      +-- reopen ----+
```

Review may be skipped for a low-risk task only when the task's `pipeline.md` records a sufficient self-check and an explicit condition for reopening execution. Archive closeout is always required.

### 1. Intake and planning: `01_intake_plan`

The request is converted into a task contract. The stage records:

- the objective and constraints in `TASK.md`;
- observable success criteria;
- required deliverables and how they will be validated;
- direct, scoped source references;
- the selected stage sequence and review decision in `pipeline.md`;
- current decisions, questions, next action, and the stage exit in `STATUS.md`;
- the intake history in `LOG.md`.

Intake is also the user-input checkpoint: questions are raised when an unresolved choice could materially change scope, risk, evidence, deliverables, or an irreversible action.

### 2. Execution: `02_execute`

Execution produces the declared work product. Work normally belongs in the task's `work/` or `deliverables/` directories, or at an explicit output path named in `TASK.md`.

The stage keeps two kinds of information separate:

- `STATUS.md` contains current material decisions, unresolved questions, outputs, checks, and the next handoff.
- `LOG.md` contains dated history and exploration.

The stage exit identifies the produced outputs, checks and results, remaining issues, and the direct inputs allowed for the next stage.

### 3. Review: `03_review`

Review checks every success criterion against evidence. Depending on the task, that can include checking deliverables, claims, calculations, citations, changed files, or other task-specific proof.

If a required check fails or the pipeline's reopen condition occurs, execution is reopened and the reason is recorded. Review evidence is substantive: it is separate from the structural checks performed later by the archive helper.

### 4. Delivery and archive: `04_deliver_archive`

Closeout verifies that:

- every declared deliverable exists;
- the review decision was satisfied, including the recorded self-check when review was skipped;
- the workflow manifest exists;
- the task is ready to become a durable record.

`tools/archive-task.ps1` then creates the archive record, moves the complete task directory to `archive/completed-tasks/`, updates `INDEX.md`, resets the root active-task pointer, and records the closeout in `ROOT_LOG.md`.

The archive helper verifies structure and file presence. It does not replace substantive review of the work itself.

## Use cases

ICM_Test is useful for:

- research and analysis where sources must stay scoped and traceable;
- writing reports, plans, comparisons, and other document deliverables;
- building or modifying small tools and prototypes with explicit review criteria;
- multi-session work where the next session needs a reliable handoff;
- human/AI or multi-agent collaboration where permissions and context boundaries matter;
- experiments and workflow tests that should remain reproducible after completion;
- maintaining durable project notes, decisions, and completed task records.

## Benefits

### Context control

Stage contracts create a context boundary. A reference named in an allowed file does not automatically authorize following every file it mentions. If additional material is needed, the reason is recorded before the context expands and the new direct reference is added to the task state.

### Recoverability

The current state, next action, decisions, outputs, and open questions are visible in `STATUS.md`. A later session can resume from the task record instead of reconstructing the work from chat history.

### Auditability

The task contract, stage exits, review evidence, logs, declared deliverables, and archive record create a trace from request to final result.

### Reproducibility

New tasks receive a copy of the versioned default workflow. `meta/WORKFLOW_MANIFEST.md` records the workflow identity and source hashes, preserving the exact workflow snapshot used by that task.

### Safer closeout

Archiving is a deliberate stage with structural checks. It reduces the chance of marking a task complete while a required deliverable, review record, or workflow snapshot is missing.

## Technical model

### Workspace-level control plane

```text
STATUS.md       -> active task, workflow version, and current stage
INDEX.md        -> index of durable archive material
ROOT_LOG.md     -> workspace-level closeout and history
REFERENCES.md   -> standing sources, preferences, and reusable patterns
WORKSPACE_PROTOCOL.md -> operating rules and context policy
```

The machine-readable block in `STATUS.md` is delimited by `machine-state:start` and `machine-state:end`. Tools use it to identify the active task and stage without parsing the entire document.

### Task directory

Each task created by `tools/new-task.ps1` has this shape:

```text
tasks/YYYY-MM-DD_task-slug/
|-- TASK.md                         # objective, constraints, criteria, inputs, deliverables
|-- pipeline.md                     # stage sequence, review decision, reopen condition
|-- STATUS.md                       # current state, decisions, handoff, latest stage exit
|-- LOG.md                          # dated task history
|-- HANDOFF.md                      # optional one-successor instructions
|-- work/                           # working material and intermediate outputs
|-- deliverables/                   # task outputs intended for handoff
|-- stages/                         # copied stage contracts for this task
|-- templates/                      # copied task-local templates
`-- meta/WORKFLOW_MANIFEST.md       # workflow version and source hashes
```

`HANDOFF.md` is optional and one-successor only. It narrows the next action; it cannot override `TASK.md` or `pipeline.md`.

### Versioned workflows

The reusable workflow lives in `system/default-workflow-v2/`. New tasks copy its stage contracts and templates, then record the workflow snapshot in their manifest. Existing v1 tasks and historical archives remain unchanged when v2 evolves.

## Repository layout

```text
ICM_Test/
|-- archive/                         # durable notes, projects, decisions, completed tasks
|-- system/                          # versioned reusable workflows and templates
|-- tasks/                           # active task directories
|-- tools/                           # PowerShell workflow helpers
|-- INDEX.md                         # archive index
|-- REFERENCES.md                    # standing sources and reusable patterns
|-- ROOT_LOG.md                      # workspace-level history
|-- STATUS.md                        # active-task pointer and workspace status
|-- WORKSPACE_PROTOCOL.md            # operating rules and context protocol
`-- README.md                        # this guide
```

## Getting started

Run these commands from the repository root in PowerShell.

### Create a task

```powershell
.\tools\new-task.ps1 "Research a topic"
```

The command creates a dated task directory, copies the v2 stage contracts and templates, initializes `TASK.md`, `pipeline.md`, `STATUS.md`, and `LOG.md`, creates `work/` and `deliverables/`, writes `meta/WORKFLOW_MANIFEST.md`, and updates the root active-task pointer.

### Copy source material into a task

```powershell
.\tools\copy-task-assets.ps1 `
    -TaskPath .\tasks\2026-08-14_research-a-topic `
    -Source .\source.md `
    -Destination work
```

Use `-Destination inputs`, `work`, or `deliverables` as appropriate. The helper does not overwrite an existing target unless `-Force` is supplied.

### Validate workspace structure

```powershell
.\tools\validate-workspace.ps1
```

Validation checks the root machine-state block, the v2 workflow stages, active-task scaffolding, the task manifest, stage alignment, and required status fields. It is a structural check, not a substitute for substantive review.

### Archive a completed task

After the task reaches `04_deliver_archive` and its status and pipeline records are complete:

```powershell
.\tools\archive-task.ps1 `
    -TaskPath .\tasks\2026-08-14_research-a-topic
```

The helper refuses incomplete or ambiguous task state and preserves the task as a self-contained archive record.

## Key rules

1. Start each task under `tasks/` and use the task-local workflow snapshot.
2. Keep the root `STATUS.md` as a pointer; keep task-specific state in the task directory.
3. Read only the direct inputs allowed by the current stage contract.
4. Record material decisions and unresolved questions in `STATUS.md`.
5. Record detailed history in `LOG.md`.
6. Produce work in declared output locations.
7. Verify the deliverable itself, not just its metadata or archive record.
8. Archive the complete task directory; do not represent skipped or unused stages as completed work.

## Current repository status

The workspace currently has no active task. See [`STATUS.md`](STATUS.md) for the machine-readable status and [`INDEX.md`](INDEX.md) for the completed-task archive.

## ICM Next Phase 1 pilot

`tools/icm-next.ps1` is an opt-in, local-only event-ledger pilot. It runs beside
the v2 filesystem workflow and does not modify legacy tasks or archives. It adds
generated state/context, dependency checks, artifact observations, human approval
gates, recovery, archive snapshots, and legacy inventory/import. Start with:

```powershell
.\tools\icm-next.ps1 init
```

See [`redesign/PHASE_1_OPERATING_GUIDE.md`](redesign/PHASE_1_OPERATING_GUIDE.md)
for commands and pilot boundaries.

## Related documentation

- [`WORKSPACE_PROTOCOL.md`](WORKSPACE_PROTOCOL.md) - full operating rules and context policy
- [`STATUS.md`](STATUS.md) - current workspace state
- [`system/default-workflow-v2/WORKFLOW.md`](system/default-workflow-v2/WORKFLOW.md) - reusable workflow definition
- [`tools/README.md`](tools/README.md) - helper overview
- [`redesign/PHASE_1_OPERATING_GUIDE.md`](redesign/PHASE_1_OPERATING_GUIDE.md) - ICM Next pilot guide
- [`INDEX.md`](INDEX.md) - archive index
