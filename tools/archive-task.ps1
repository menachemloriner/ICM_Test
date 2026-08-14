[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)] [string]$TaskPath,
    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$resolvedTask = (Resolve-Path -LiteralPath $TaskPath).Path
$taskName = Split-Path -Leaf $resolvedTask
$archivePath = Join-Path $WorkspaceRoot "archive\completed-tasks\$taskName"
$taskFile = Join-Path $resolvedTask 'TASK.md'
$statusFile = Join-Path $resolvedTask 'STATUS.md'
$pipelineFile = Join-Path $resolvedTask 'pipeline.md'
$manifestFile = Join-Path $resolvedTask 'meta\WORKFLOW_MANIFEST.md'
$rootStatusPath = Join-Path $WorkspaceRoot 'STATUS.md'
$indexPath = Join-Path $WorkspaceRoot 'INDEX.md'

foreach ($required in @($taskFile, $statusFile, $pipelineFile, $manifestFile)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Task is missing required file: $required" }
}
if (Test-Path -LiteralPath $archivePath) { throw "Archive target already exists: $archivePath" }
foreach ($required in @($rootStatusPath, $indexPath)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Workspace is missing required file: $required" }
}

$taskLines = Get-Content -LiteralPath $taskFile -Encoding UTF8
$statusText = Get-Content -Raw -LiteralPath $statusFile -Encoding UTF8
$pipelineText = Get-Content -Raw -LiteralPath $pipelineFile -Encoding UTF8
$manifestText = Get-Content -Raw -LiteralPath $manifestFile -Encoding UTF8

function Get-BulletValue {
    param([string]$Text, [string]$Label)
    $pattern = '(?m)^-\s*' + [regex]::Escape($Label) + ':[ \t]*(?<value>[^\r\n]+)\r?$'
    $match = [regex]::Match($Text, $pattern)
    if (-not $match.Success) { return $null }
    return $match.Groups['value'].Value.Trim()
}

function Test-Placeholder {
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    return $Value.Trim() -match '^(None|TBD|TODO|Pending|Pending intake decision|\[.*\]|\.\.\.)\.?$'
}

$manifestMatch = [regex]::Match($manifestText, '(?m)^Workflow:[ \t]*(?<workflow>[^\r\n]+)\r?$')
if (-not $manifestMatch.Success -or [string]::IsNullOrWhiteSpace($manifestMatch.Groups['workflow'].Value)) {
    throw 'Workflow manifest has no workflow version.'
}
$workflowVersion = $manifestMatch.Groups['workflow'].Value.Trim()

$taskStageMatch = [regex]::Match($statusText, '(?m)^## Current stage\s*\r?\n(?<stage>[^\r\n]+)')
if (-not $taskStageMatch.Success) { throw 'Task STATUS.md has no current stage.' }
$taskStage = $taskStageMatch.Groups['stage'].Value.Trim()
if ($taskStage -ne '04_deliver_archive') { throw "Task current stage must be 04_deliver_archive, found: $taskStage" }

$latestExitMatch = [regex]::Match($statusText, '(?ms)^## Latest Stage Exit\s*(?<section>.*?)(?=^## |\z)')
if (-not $latestExitMatch.Success) { throw 'Task STATUS.md has no Latest Stage Exit section.' }
$latestExit = $latestExitMatch.Groups['section'].Value
$completedStage = Get-BulletValue -Text $latestExit -Label 'Completed stage'
$outputs = Get-BulletValue -Text $latestExit -Label 'Outputs'
$checks = Get-BulletValue -Text $latestExit -Label 'Checks and result'
$completedStage = if ($null -eq $completedStage) { $null } else { $completedStage.TrimEnd('.') }
if ($completedStage -ne '04_deliver_archive') { throw 'Latest Stage Exit is not completed for 04_deliver_archive.' }
if (Test-Placeholder $outputs) { throw 'Latest Stage Exit Outputs is incomplete.' }
if (Test-Placeholder $checks) { throw 'Latest Stage Exit Checks and result is incomplete.' }

$reviewSectionMatch = [regex]::Match($pipelineText, '(?ms)^## Review Decision\s*(?<section>.*?)(?=^## |\z)')
if (-not $reviewSectionMatch.Success) { throw 'pipeline.md has no Review Decision section.' }
$reviewSection = $reviewSectionMatch.Groups['section'].Value
$reviewDecision = Get-BulletValue -Text $reviewSection -Label 'Review'
$reviewReason = Get-BulletValue -Text $reviewSection -Label 'Reason'
$selfCheck = Get-BulletValue -Text $reviewSection -Label 'Self-check when skipped'
$reopenCondition = Get-BulletValue -Text $reviewSection -Label 'Reopen execution when'
if ($reviewDecision -notin @('required', 'skipped')) { throw "pipeline.md has no completed review decision: $reviewDecision" }
if (Test-Placeholder $reviewReason) { throw 'pipeline.md has no completed review reason.' }
if (Test-Placeholder $reopenCondition) { throw 'pipeline.md has no completed reopen condition.' }
if ($reviewDecision -eq 'skipped') {
    if (Test-Placeholder $selfCheck) { throw 'pipeline.md skips review without a recorded self-check.' }
} else {
    $reviewEvidence = ($latestExit -match '(?i)03_review') -and ($latestExit -match '(?i)(complete|completed|pass|passed|verified|review)')
    if (-not $reviewEvidence) { throw 'Required review has no completed 03_review exit or equivalent review evidence.' }
}

$taskTitle = $taskName
foreach ($line in $taskLines) {
    if ($line -match '^#\s+(.+)$') {
        $taskTitle = $Matches[1].Trim()
        break
    }
}
$inDeliverables = $false
$requiredDeliverables = @()
foreach ($line in $taskLines) {
    if ($line -match '^## Required deliverables') { $inDeliverables = $true; continue }
    if ($inDeliverables -and $line -match '^## ') { $inDeliverables = $false; continue }
    if (-not $inDeliverables -or [string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -notmatch '^-\s+path:\s*(?<path>[^;]+);\s*description:\s*(?<description>[^;]+);\s*validation:\s*(?<validation>.+)$') {
        throw "Required deliverable does not use path/description/validation syntax: $line"
    }
    $requiredDeliverables += [pscustomobject]@{
        Path = $Matches['path'].Trim()
        Description = $Matches['description'].Trim()
        Validation = $Matches['validation'].Trim()
    }
}
if ($requiredDeliverables.Count -eq 0) { throw 'TASK.md declares no required deliverables.' }
$foundDeliverables = foreach ($deliverable in $requiredDeliverables) {
    if (Test-Placeholder $deliverable.Path) { throw 'TASK.md contains a placeholder deliverable path.' }
    $candidate = if ([IO.Path]::IsPathRooted($deliverable.Path)) { $deliverable.Path } else { Join-Path $resolvedTask $deliverable.Path }
    if (-not (Test-Path -LiteralPath $candidate)) { throw "Required deliverable is missing: $candidate" }
    $deliverable.Path
}

$index = Get-Content -Raw -LiteralPath $indexPath -Encoding UTF8
if ($index -notmatch '(?m)^## Completed tasks\s*$') { throw 'INDEX.md has no Completed tasks section.' }
$rootStatus = Get-Content -Raw -LiteralPath $rootStatusPath -Encoding UTF8

if ($PSCmdlet.ShouldProcess($archivePath, "Archive task $resolvedTask")) {
    $now = Get-Date
    $date = $now.ToString('yyyy-MM-dd')
    $archiveNoteDirectory = Join-Path $resolvedTask 'meta'
    $archiveNotePath = Join-Path $archiveNoteDirectory 'ARCHIVE.md'
    New-Item -ItemType Directory -Path $archiveNoteDirectory -Force | Out-Null
    $deliverableLines = if ($foundDeliverables) { ($foundDeliverables | ForEach-Object { "- $_" }) -join "`r`n" } else { '- None.' }
    $archiveNote = @"
# Archive record

Archived timestamp: $($now.ToString('o'))
Final status: Complete
Workflow: $workflowVersion
Manifest: meta/WORKFLOW_MANIFEST.md

## Declared deliverables found

$deliverableLines

The script verified structural requirements and declared file presence only; it
did not verify substantive quality.
"@
    Set-Content -LiteralPath $archiveNotePath -Value $archiveNote -Encoding UTF8

    New-Item -ItemType Directory -Path (Split-Path -Parent $archivePath) -Force | Out-Null
    Move-Item -LiteralPath $resolvedTask -Destination $archivePath

    $indexNewline = if ($index -match "`r`n") { "`r`n" } else { "`n" }
    $indexSeparator = [char]0x2014
    $index = [regex]::Replace($index, '(?m)(^## Completed tasks\s*\r?\n)', ('$1' + "- [$date] $taskTitle $indexSeparator archive/completed-tasks/$taskName/$indexNewline"), 1)
    Set-Content -LiteralPath $indexPath -Value $index -Encoding UTF8

    $rootStatus = [regex]::Replace($rootStatus, '(?ms)(<!-- machine-state:start -->\r?\n```yaml\r?\n).*?(\r?\n```\r?\n<!-- machine-state:end -->)', ('$1' + "active_task: null`r`nworkflow: $workflowVersion`r`nstage: null" + '$2'))
    $rootStatus = [regex]::Replace($rootStatus, '(?ms)(## Active task\r?\n).*?(?=\r?\n## Default workflow)', '$1' + 'None. The workspace is ready for a new task.')
    Set-Content -LiteralPath $rootStatusPath -Value $rootStatus -Encoding UTF8

    $rootLogPath = Join-Path $WorkspaceRoot 'ROOT_LOG.md'
    if (-not (Test-Path -LiteralPath $rootLogPath)) {
        $rootLogHeader = "# Root log`r`n`r`n[newest first " + [char]0x2014 + " new entries use YYYY-MM-DD]`r`n"
        Set-Content -LiteralPath $rootLogPath -Value $rootLogHeader -Encoding UTF8
    }
    $rootLog = Get-Content -Raw -LiteralPath $rootLogPath -Encoding UTF8
    $rootLogNewline = if ($rootLog -match "`r`n") { "`r`n" } else { "`n" }
    $rootLog = [regex]::Replace($rootLog, '(?m)(^\[newest first[^\r\n]*\r?\n)', ('$1' + "- [$date] Archived '$taskTitle' at archive/completed-tasks/$taskName/. Structural requirements and declared file presence checked; workspace is ready for a new task.$rootLogNewline"), 1)
    Set-Content -LiteralPath $rootLogPath -Value $rootLog -Encoding UTF8
    Write-Output "Archived $archivePath"
}
