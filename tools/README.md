# Workflow helpers

`new-task.ps1` creates a task-local working directory from the current default
workflow, initializes the task files, creates a `meta/WORKFLOW_MANIFEST.md`
snapshot for `default-workflow-v2`, and updates the root active-task pointer.

`copy-task-assets.ps1` copies files, folders, or finished project directories into
the active task without manually repeating copy commands.

`validate-workspace.ps1` checks the machine-readable active-task pointer, the
`default-workflow-v2` stages, and the active task scaffolding.

`archive-task.ps1` verifies declared deliverable paths and task-state structure,
then moves a completed task as one self-contained directory into the archive. It
does not substitute for substantive review; those checks and evidence belong in
the task's `STATUS.md`, review record, or declared work product.

The helper uses the current date and refuses to overwrite an existing task directory.
