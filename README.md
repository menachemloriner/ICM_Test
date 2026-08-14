# ICM_Test

ICM_Test is a versioned, task-local workspace for managing AI-assisted work. It keeps active tasks, workflow contracts, durable notes, decisions, and completed task archives organized in one repository.

## How it works

Each task lives in its own directory under `tasks/` and follows the reusable workflow in `system/default-workflow-v2/`:

1. `01_intake_plan` — define the task, scope, inputs, and stage plan.
2. `02_execute` — perform the work and produce the deliverables.
3. `03_review` — verify the result when review is required.
4. `04_deliver_archive` — verify closeout and archive the complete task.

Completed tasks are moved to `archive/completed-tasks/`. The root `STATUS.md` points to the active task, while `INDEX.md` is the front door to the archive.

## Repository layout

```text
ICM_Test/
├── archive/                         # Durable notes, projects, decisions, and completed tasks
├── system/                          # Versioned reusable workflows and templates
├── tasks/                           # Active task directories
├── tools/                           # PowerShell workflow helpers
├── INDEX.md                         # Archive index
├── REFERENCES.md                    # Standing sources and reusable patterns
├── ROOT_LOG.md                      # Workspace-level history
├── STATUS.md                        # Active-task pointer and workspace status
└── WORKSPACE_PROTOCOL.md            # Operating rules and workflow protocol
```

## Starting a task

From the repository root, create a task with:

```powershell
.\tools\new-task.ps1 -Name "Short task name"
```

Then complete the task-local `TASK.md`, `pipeline.md`, and stage files. Work from the task directory and its copied workflow contracts rather than editing the reusable workflow under `system/`.

## Workflow helpers

- `tools/new-task.ps1` creates and initializes a task directory.
- `tools/copy-task-assets.ps1` copies source material into a task's `work/` or `deliverables/` directory.
- `tools/validate-workspace.ps1` checks the active-task pointer and workflow scaffolding.
- `tools/archive-task.ps1` verifies and archives a completed task, updates `INDEX.md`, and resets the root status.

## Current status

The workspace currently has no active task. See [`STATUS.md`](STATUS.md) for the machine-readable status and [`INDEX.md`](INDEX.md) for the completed-task archive.
