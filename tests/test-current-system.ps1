[CmdletBinding()]
param(
    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testRoot = Join-Path $tempBase ('icm-current-system-' + [guid]::NewGuid().ToString())
$assertions = [Collections.Generic.List[string]]::new()

function Assert-That {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "Assertion failed: $Message" }
    $assertions.Add($Message)
}

function Set-ArchivableTask {
    param(
        [string]$TaskPath,
        [string]$Title,
        [string]$DeliverablePath,
        [bool]$CreateDeliverable
    )
    $taskFile = @"
# $Title

## Objective
Exercise structural archive behavior.

## Required deliverables
- path: $DeliverablePath; description: test proof; validation: file exists
"@
    $pipeline = @"
# Stage Plan

## Review Decision

- Review: skipped
- Reason: The test checks archive structure only.
- Self-check when skipped: Deliverable presence is checked by the helper.
- Reopen execution when: The deliverable is missing.
"@
    $status = @"
# Task status

## Current stage

04_deliver_archive

## Latest Stage Exit

- Completed stage: 04_deliver_archive.
- Outputs: $DeliverablePath
- Checks and result: Declared self-check recorded.
- Outstanding issues: None.
- Inputs allowed for next stage: None.
"@
    Set-Content -LiteralPath (Join-Path $TaskPath 'TASK.md') -Value $taskFile -Encoding utf8
    Set-Content -LiteralPath (Join-Path $TaskPath 'pipeline.md') -Value $pipeline -Encoding utf8
    Set-Content -LiteralPath (Join-Path $TaskPath 'STATUS.md') -Value $status -Encoding utf8
    if ($CreateDeliverable) {
        $fullDeliverable = Join-Path $TaskPath $DeliverablePath
        New-Item -ItemType Directory -Path (Split-Path -Parent $fullDeliverable) -Force | Out-Null
        Set-Content -LiteralPath $fullDeliverable -Value 'test artifact' -Encoding utf8
    }
}

function Invoke-Validator {
    param([string]$Root)
    $hostPath = (Get-Process -Id $PID).Path
    & $hostPath -NoProfile -File (Join-Path $Root 'tools\validate-workspace.ps1') -WorkspaceRoot $Root -Quiet | Out-Null
    return $LASTEXITCODE
}

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    foreach ($entry in Get-ChildItem -LiteralPath $WorkspaceRoot -Force) {
        if ($entry.Name -ne '.git') { Copy-Item -LiteralPath $entry.FullName -Destination $testRoot -Recurse -Force }
    }

    $date = (Get-Date).ToString('yyyy-MM-dd')
    $newTask = Join-Path $testRoot 'tools\new-task.ps1'
    & $newTask -TaskName 'First competing task' -WorkspaceRoot $testRoot | Out-Null
    & $newTask -TaskName 'Second competing task' -WorkspaceRoot $testRoot | Out-Null
    $first = Join-Path $testRoot "tasks\${date}_first-competing-task"
    $second = Join-Path $testRoot "tasks\${date}_second-competing-task"
    Assert-That (Test-Path -LiteralPath $first) 'A first task can be created.'
    Assert-That (Test-Path -LiteralPath $second) 'A second task can be created while the first is still active.'
    $rootStatus = Get-Content -Raw -LiteralPath (Join-Path $testRoot 'STATUS.md') -Encoding utf8
    Assert-That ($rootStatus -match [regex]::Escape("active_task: tasks\${date}_second-competing-task")) 'The second task silently replaces the root active-task pointer.'

    Set-ArchivableTask -TaskPath $first -Title 'First competing task' -DeliverablePath 'deliverables\first.txt' -CreateDeliverable $true
    & (Join-Path $testRoot 'tools\archive-task.ps1') -TaskPath $first -WorkspaceRoot $testRoot | Out-Null
    Assert-That (Test-Path -LiteralPath (Join-Path $testRoot "archive\completed-tasks\${date}_first-competing-task\meta\ARCHIVE.md")) 'An inactive task can be archived.'
    Assert-That (Test-Path -LiteralPath $second) 'The newer task remains on disk after the inactive task is archived.'
    $rootStatusAfterArchive = Get-Content -Raw -LiteralPath (Join-Path $testRoot 'STATUS.md') -Encoding utf8
    Assert-That ($rootStatusAfterArchive -match 'active_task: null') 'Archiving the inactive task clears the active pointer and strands the newer task.'

    & $newTask -TaskName 'Missing deliverable task' -WorkspaceRoot $testRoot | Out-Null
    $missing = Join-Path $testRoot "tasks\${date}_missing-deliverable-task"
    Set-ArchivableTask -TaskPath $missing -Title 'Missing deliverable task' -DeliverablePath 'deliverables\missing.txt' -CreateDeliverable $false
    $missingRejected = $false
    try { & (Join-Path $testRoot 'tools\archive-task.ps1') -TaskPath $missing -WorkspaceRoot $testRoot | Out-Null }
    catch { $missingRejected = $_.Exception.Message -match 'Required deliverable is missing' }
    Assert-That $missingRejected 'The archive helper rejects a declared file that is absent.'

    & $newTask -TaskName 'Manifest drift task' -WorkspaceRoot $testRoot | Out-Null
    Add-Content -LiteralPath (Join-Path $testRoot 'system\default-workflow-v2\WORKFLOW.md') -Value "`nTest source mutation after task creation." -Encoding utf8
    Assert-That ((Invoke-Validator -Root $testRoot) -eq 0) 'Workspace validation ignores drift from the task workflow manifest source hashes.'

    $brokenStatus = Get-Content -Raw -LiteralPath (Join-Path $testRoot 'STATUS.md') -Encoding utf8
    $brokenStatus = $brokenStatus -replace 'active_task: tasks\\[^\r\n]+', 'active_task: tasks\\missing-after-interruption'
    $brokenStatus = $brokenStatus -replace 'stage: 01_intake_plan', 'stage: 01_intake_plan'
    Set-Content -LiteralPath (Join-Path $testRoot 'STATUS.md') -Value $brokenStatus -Encoding utf8
    Assert-That ((Invoke-Validator -Root $testRoot) -ne 0) 'Interrupted state with a missing active directory is detected, but not repaired.'

    [pscustomobject]@{
        Passed = $true
        Assertions = @($assertions)
        Evidence = @(
            'Competing task creation overwrote the root pointer.',
            'Inactive-task archive reset the pointer and stranded a newer task.',
            'Missing deliverables were rejected structurally.',
            'Workflow manifest hash drift was not validated.',
            'Interrupted state was detected but has no recovery command.'
        )
    }
}
finally {
    if ((Test-Path -LiteralPath $testRoot) -and $testRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
