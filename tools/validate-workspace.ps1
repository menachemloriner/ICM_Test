[CmdletBinding()]
param(
    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$errors = [System.Collections.Generic.List[string]]::new()
$rootStatusPath = Join-Path $WorkspaceRoot 'STATUS.md'
$defaultRoot = Join-Path $WorkspaceRoot 'system\default-workflow-v2'

if (-not (Test-Path -LiteralPath $rootStatusPath)) { $errors.Add('Missing root STATUS.md.') }
if (-not (Test-Path -LiteralPath $defaultRoot)) { $errors.Add('Missing system/default-workflow-v2.') }

$stageNames = @('01_intake_plan','02_execute','03_review','04_deliver_archive')
foreach ($stage in $stageNames) {
    if (-not (Test-Path -LiteralPath (Join-Path $defaultRoot "stages\$stage\CONTEXT.md"))) {
        $errors.Add("Missing default stage contract: $stage.")
    }
}

$activeTask = $null
if (Test-Path -LiteralPath $rootStatusPath) {
    $rootStatus = Get-Content -Raw -LiteralPath $rootStatusPath -Encoding UTF8
    $match = [regex]::Match($rootStatus, '(?ms)<!-- machine-state:start -->\s*```yaml\s*active_task:\s*(?<task>[^\r\n]+)\s*\r?\nworkflow:\s*(?<workflow>[^\r\n]+)\s*\r?\nstage:\s*(?<stage>[^\r\n]+)')
    if (-not $match.Success) {
        $errors.Add('STATUS.md has no valid machine-state block.')
    } else {
        $activeValue = $match.Groups['task'].Value.Trim()
        $rootStage = $match.Groups['stage'].Value.Trim()
        if ($activeValue -ne 'null') { $activeTask = Join-Path $WorkspaceRoot $activeValue }
        if ($match.Groups['workflow'].Value.Trim() -ne 'default-workflow-v2') { $errors.Add('STATUS.md references an unknown workflow.') }
        if ($activeTask) {
            if (-not (Test-Path -LiteralPath $activeTask)) { $errors.Add("Active task directory is missing: $activeTask") }
            else {
                foreach ($required in @('TASK.md','pipeline.md','STATUS.md','LOG.md','stages','meta\WORKFLOW_MANIFEST.md')) {
                    if (-not (Test-Path -LiteralPath (Join-Path $activeTask $required))) { $errors.Add("Active task is missing $required.") }
                }
                $manifestPath = Join-Path $activeTask 'meta\WORKFLOW_MANIFEST.md'
                if (Test-Path -LiteralPath $manifestPath) {
                    $manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8
                    if ([string]::IsNullOrWhiteSpace($manifest) -or $manifest -notmatch '(?m)^Workflow:\s*default-workflow-v2\s*$') {
                        $errors.Add('Active task workflow manifest is missing or does not declare default-workflow-v2.')
                    }
                }
                $taskStatusPath = Join-Path $activeTask 'STATUS.md'
                if (Test-Path -LiteralPath $taskStatusPath) {
                    $taskStatus = Get-Content -Raw -LiteralPath $taskStatusPath -Encoding UTF8
                    $taskMachineMatch = [regex]::Match($taskStatus, '(?ms)<!-- machine-state:start -->\s*```yaml\s*task:\s*[^\r\n]+\s*\r?\ncurrent_stage:\s*(?<stage>[^\r\n]+)')
                    $taskStageMatch = [regex]::Match($taskStatus, '(?m)^## Current stage\s*\r?\n(?<stage>[^\r\n]+)')
                    if (-not $taskStageMatch.Success) { $errors.Add('Active task STATUS.md has no current stage.') }
                    else {
                        $taskStage = $taskStageMatch.Groups['stage'].Value.Trim()
                        if ($rootStage -ne $taskStage) { $errors.Add("Root STATUS.md stage '$rootStage' does not match active task stage '$taskStage'.") }
                        if (-not $taskMachineMatch.Success -or $taskMachineMatch.Groups['stage'].Value.Trim() -ne $taskStage) { $errors.Add('Active task STATUS.md machine-state and visible current stage do not match.') }
                        if (-not (Test-Path -LiteralPath (Join-Path $activeTask "stages\$taskStage\CONTEXT.md"))) { $errors.Add("Current stage contract is missing: $taskStage") }
                    }
                    $latestExitMatch = [regex]::Match($taskStatus, '(?ms)^## Latest Stage Exit\s*(?<section>.*?)(?=^## |\z)')
                    if (-not $latestExitMatch.Success) { $errors.Add('Active task STATUS.md has no valid Latest Stage Exit section.') }
                    else {
                        foreach ($label in @('Completed stage','Outputs','Checks and result','Outstanding issues','Inputs allowed for next stage')) {
                            $pattern = '(?m)^-\s*' + [regex]::Escape($label) + ':[ \t]*[^\r\n]+\r?$'
                            if ($latestExitMatch.Groups['section'].Value -notmatch $pattern) { $errors.Add("Active task STATUS.md Latest Stage Exit is missing $label.") }
                        }
                    }
                }
            }
        }
    }
}

$result = [pscustomobject]@{ Valid = ($errors.Count -eq 0); ActiveTask = $activeTask; Errors = $errors }
if (-not $Quiet) {
    if ($result.Valid) { Write-Output 'Workspace valid.' }
    else { $errors | ForEach-Object { Write-Error $_ } }
}
if (-not $result.Valid) { exit 1 }
return $result
