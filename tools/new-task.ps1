[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TaskName,

    [string]$WorkspaceRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$now = Get-Date
$date = $now.ToString('yyyy-MM-dd')
$slug = $TaskName.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
$slug = $slug.Trim('-')
if ([string]::IsNullOrWhiteSpace($slug)) {
    throw 'TaskName must contain at least one letter or number.'
}

$taskId = "${date}_${slug}"
$taskPath = Join-Path $WorkspaceRoot "tasks\$taskId"
$relativeTaskPath = "tasks\$taskId"
$defaultRoot = Join-Path $WorkspaceRoot 'system\default-workflow-v2'
$rootStatusPath = Join-Path $WorkspaceRoot 'STATUS.md'

if (-not (Test-Path -LiteralPath $defaultRoot)) {
    throw "Default workflow not found: $defaultRoot"
}
if (Test-Path -LiteralPath $taskPath) {
    throw "Task directory already exists: $taskPath"
}

if ($PSCmdlet.ShouldProcess($taskPath, 'Create task from default-workflow-v2')) {
    New-Item -ItemType Directory -Path $taskPath | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $taskPath 'work') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $taskPath 'deliverables') | Out-Null
    Copy-Item -LiteralPath (Join-Path $defaultRoot 'stages') -Destination (Join-Path $taskPath 'stages') -Recurse
    New-Item -ItemType Directory -Path (Join-Path $taskPath 'templates') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $taskPath 'meta') | Out-Null
    Copy-Item -LiteralPath (Join-Path $defaultRoot 'templates\CONTEXT_template.md') -Destination (Join-Path $taskPath 'templates\CONTEXT_template.md')
    Copy-Item -LiteralPath (Join-Path $defaultRoot 'templates\TASK_template.md') -Destination (Join-Path $taskPath 'TASK.md')
    Copy-Item -LiteralPath (Join-Path $defaultRoot 'templates\STATUS_template.md') -Destination (Join-Path $taskPath 'STATUS.md')
    Copy-Item -LiteralPath (Join-Path $defaultRoot 'templates\pipeline_template.md') -Destination (Join-Path $taskPath 'pipeline.md')

    $taskLogPath = Join-Path $taskPath 'LOG.md'
    $taskLog = @"
# Task log

[Newest first. Use YYYY-MM-DD.]
- [$date] Task created. Next: 01_intake_plan.
"@
    Set-Content -LiteralPath $taskLogPath -Value $taskLog -Encoding UTF8

    $taskFile = Get-Content -Raw -LiteralPath (Join-Path $taskPath 'TASK.md') -Encoding UTF8
    $taskFile = $taskFile.Replace('YYYY-MM-DD', $date)
    $taskFile = $taskFile.Replace('# Task', "# $TaskName")
    Set-Content -LiteralPath (Join-Path $taskPath 'TASK.md') -Value $taskFile -Encoding UTF8

    $statusFile = Get-Content -Raw -LiteralPath (Join-Path $taskPath 'STATUS.md') -Encoding UTF8
    $statusFile = $statusFile.Replace('[Task name and directory]', "$TaskName ($relativeTaskPath)")
    $statusFile = $statusFile.Replace('YYYY-MM-DD', $date)
    Set-Content -LiteralPath (Join-Path $taskPath 'STATUS.md') -Value $statusFile -Encoding UTF8

    $pipelineFile = Get-Content -Raw -LiteralPath (Join-Path $taskPath 'pipeline.md') -Encoding UTF8
    $pipelineFile = $pipelineFile.Replace('- Review: required | skipped', '- Review: pending intake decision')
    $pipelineFile = $pipelineFile.Replace('- Reason:', '- Reason: Pending intake decision.')
    $pipelineFile = $pipelineFile.Replace('- Self-check when skipped:', '- Self-check when skipped: Pending intake decision.')
    $pipelineFile = $pipelineFile.Replace('- Reopen execution when:', '- Reopen execution when: Pending intake decision.')
    Set-Content -LiteralPath (Join-Path $taskPath 'pipeline.md') -Value $pipelineFile -Encoding UTF8

    $manifestSources = @(
        'WORKFLOW.md',
        'stages\01_intake_plan\CONTEXT.md',
        'stages\02_execute\CONTEXT.md',
        'stages\03_review\CONTEXT.md',
        'stages\04_deliver_archive\CONTEXT.md',
        'templates\CONTEXT_template.md',
        'templates\TASK_template.md',
        'templates\STATUS_template.md',
        'templates\pipeline_template.md'
    )
    $manifestEntries = foreach ($sourceFile in $manifestSources) {
        $sourcePath = Join-Path $defaultRoot $sourceFile
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Default workflow source is missing: $sourcePath"
        }
        $hash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
        $manifestPath = $sourceFile -replace '\\', '/'
        "- $manifestPath | SHA-256: $hash"
    }
    $manifestLines = @(
        '# Workflow manifest',
        'Workflow: default-workflow-v2',
        'Source: system/default-workflow-v2',
        "Created: $($now.ToString('o'))",
        '## Source hashes'
    )
    $manifestLines += $manifestEntries
    $manifest = $manifestLines -join "`r`n"
    Set-Content -LiteralPath (Join-Path $taskPath 'meta\WORKFLOW_MANIFEST.md') -Value $manifest -Encoding UTF8

    $rootStatus = Get-Content -Raw -LiteralPath $rootStatusPath -Encoding UTF8
    $rootStatus = [regex]::Replace($rootStatus, '(?ms)(<!-- machine-state:start -->\r?\n```yaml\r?\n).*?(\r?\n```\r?\n<!-- machine-state:end -->)', ('$1' + "active_task: $relativeTaskPath`r`nworkflow: default-workflow-v2`r`nstage: 01_intake_plan" + '$2'))
    $rootStatus = [regex]::Replace($rootStatus, '(?ms)(## Active task\r?\n).*?(?=\r?\n## Default workflow)', ('$1' + $relativeTaskPath))
    Set-Content -LiteralPath $rootStatusPath -Value $rootStatus -Encoding UTF8

    $rootLogPath = Join-Path $WorkspaceRoot 'ROOT_LOG.md'
    if (-not (Test-Path -LiteralPath $rootLogPath)) {
        $rootLogHeader = "# Root log`r`n`r`n[newest first " + [char]0x2014 + " new entries use YYYY-MM-DD]`r`n"
        Set-Content -LiteralPath $rootLogPath -Value $rootLogHeader -Encoding UTF8
    }
    $rootLog = Get-Content -Raw -LiteralPath $rootLogPath -Encoding UTF8
    $rootLogNewline = if ($rootLog -match "`r`n") { "`r`n" } else { "`n" }
    $rootLog = [regex]::Replace($rootLog, '(?m)(^\[newest first[^\r\n]*\r?\n)', ('$1' + "- [$date] Created task '$TaskName'. Next: 01_intake_plan.$rootLogNewline"), 1)
    Set-Content -LiteralPath $rootLogPath -Value $rootLog -Encoding UTF8

    Write-Output "Created $taskPath"
}
