[CmdletBinding()]
param(
    [string]$ToolPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'tools\icm-next.ps1')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ToolPath = (Resolve-Path -LiteralPath $ToolPath).Path
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$testRoot = Join-Path $tempBase ('icm-next-test-' + [guid]::NewGuid().ToString())
$assertions = [Collections.Generic.List[string]]::new()

function Assert-That {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "Assertion failed: $Message" }
    $assertions.Add($Message)
}

function Invoke-Next {
    param([string[]]$Invocation)
    $command = $Invocation[0]
    $parameters = @{}
    for ($index = 1; $index -lt $Invocation.Count; $index += 2) {
        if ($Invocation[$index] -notmatch '^-') { throw "Expected a named parameter, found '$($Invocation[$index])'." }
        $parameters[$Invocation[$index].TrimStart('-')] = $Invocation[$index + 1]
    }
    return & $ToolPath $command @parameters
}

function Transition-Task {
    param([string]$Task, [string]$From, [string]$To)
    Invoke-Next -Invocation @('transition', '-Root', $testRoot, '-TaskId', $Task, '-ExpectedFrom', $From, '-To', $To) | Out-Null
}

try {
    Invoke-Next -Invocation @('init', '-Root', $testRoot) | Out-Null
    Assert-That (Test-Path -LiteralPath (Join-Path $testRoot '.icm-next\config.json')) 'Initialization writes the approved single-machine local-only configuration.'
    Invoke-Next -Invocation @('new-task', '-Root', $testRoot, '-TaskId', 'alpha', '-Title', 'Alpha report', '-Objective', 'Produce a verified report.', '-Criteria', 'report exists') | Out-Null
    Invoke-Next -Invocation @('new-task', '-Root', $testRoot, '-TaskId', 'beta', '-Title', 'Dependent review', '-Objective', 'Review Alpha after it closes.', '-DependsOn', 'alpha') | Out-Null
    $brief = Join-Path $testRoot 'tasks\alpha\brief.md'
    Set-Content -LiteralPath $brief -Value 'Use the current evidence only.' -Encoding utf8
    $contextPayload = @{ uri = 'tasks/alpha/brief.md'; purpose = 'task brief'; scope = 'whole file' } | ConvertTo-Json -Compress
    Invoke-Next -Invocation @('record', '-Root', $testRoot, '-TaskId', 'alpha', '-Type', 'context.linked', '-PayloadJson', $contextPayload) | Out-Null

    Transition-Task -Task 'alpha' -From 'queued' -To 'active'
    Transition-Task -Task 'beta' -From 'queued' -To 'active'
    $blocked = Invoke-Next -Invocation @('verify', '-Root', $testRoot)
    Assert-That (-not $blocked.Valid) 'A dependent task cannot progress while its dependency is open.'
    Assert-That (($blocked.Errors -join "`n") -match 'dependencies remain open') 'Dependency failure identifies the blocking task state.'

    $artifactRelative = 'tasks/alpha/deliverables/report.md'
    $artifactPayload = @{ path = $artifactRelative; validation = 'SHA-256 matches the observed file' } | ConvertTo-Json -Compress
    Invoke-Next -Invocation @('record', '-Root', $testRoot, '-TaskId', 'alpha', '-Type', 'artifact.declared', '-PayloadJson', $artifactPayload) | Out-Null
    $artifact = Join-Path $testRoot $artifactRelative
    Set-Content -LiteralPath $artifact -Value 'Verified report version one.' -Encoding utf8
    Invoke-Next -Invocation @('observe', '-Root', $testRoot, '-TaskId', 'alpha', '-ArtifactPath', $artifactRelative) | Out-Null
    $checkPayload = @{ criterion = 'report exists'; result = 'pass'; evidence = $artifactRelative } | ConvertTo-Json -Compress
    Invoke-Next -Invocation @('record', '-Root', $testRoot, '-TaskId', 'alpha', '-Type', 'check.recorded', '-PayloadJson', $checkPayload) | Out-Null
    Transition-Task -Task 'alpha' -From 'active' -To 'waiting_review'
    Transition-Task -Task 'alpha' -From 'waiting_review' -To 'ready_to_close'
    Transition-Task -Task 'alpha' -From 'ready_to_close' -To 'closed'
    $verified = Invoke-Next -Invocation @('verify', '-Root', $testRoot)
    Assert-That $verified.Valid 'An independently observed artifact and passing criterion allow a task to close.'

    $compiled = Invoke-Next -Invocation @('compile', '-Root', $testRoot, '-TaskId', 'alpha')
    Assert-That ($compiled.Compiled -and $compiled.Valid) 'The compiler produces a valid task context from the event ledger.'
    $contextFile = Join-Path $testRoot '.icm-next\generated\contexts\alpha.md'
    Assert-That (Test-Path -LiteralPath $contextFile) 'The generated context file exists.'
    Remove-Item -LiteralPath $contextFile -Force
    Invoke-Next -Invocation @('compile', '-Root', $testRoot, '-TaskId', 'alpha') | Out-Null
    Assert-That (Test-Path -LiteralPath $contextFile) 'A deleted context view is recoverable from the ledger.'

    Set-Content -LiteralPath $artifact -Value 'Changed after review.' -Encoding utf8
    $staleArtifact = Invoke-Next -Invocation @('verify', '-Root', $testRoot)
    Assert-That (-not $staleArtifact.Valid) 'A changed artifact invalidates the closed-task evidence.'
    Assert-That (($staleArtifact.Errors -join "`n") -match 'artifact hash mismatch') 'Artifact drift is reported with a concrete failure.'
    $closedObservationBlocked = $false
    try { Invoke-Next -Invocation @('observe', '-Root', $testRoot, '-TaskId', 'alpha', '-ArtifactPath', $artifactRelative) | Out-Null }
    catch { $closedObservationBlocked = $_.Exception.Message -match 'Reopen it before observing' }
    Assert-That $closedObservationBlocked 'A changed closed artifact cannot be re-observed without an explicit reopen.'
    Invoke-Next -Invocation @('reopen', '-Root', $testRoot, '-TaskId', 'alpha', '-Reason', 'Artifact changed after delivery.') | Out-Null
    Invoke-Next -Invocation @('observe', '-Root', $testRoot, '-TaskId', 'alpha', '-ArtifactPath', $artifactRelative) | Out-Null
    Invoke-Next -Invocation @('record', '-Root', $testRoot, '-TaskId', 'alpha', '-Type', 'check.recorded', '-PayloadJson', $checkPayload) | Out-Null
    Transition-Task -Task 'alpha' -From 'active' -To 'waiting_review'
    Transition-Task -Task 'alpha' -From 'waiting_review' -To 'ready_to_close'
    Transition-Task -Task 'alpha' -From 'ready_to_close' -To 'closed'
    Assert-That ((Invoke-Next -Invocation @('verify', '-Root', $testRoot)).Valid) 'Reopen, fresh observation, and fresh review are required before re-close.'
    $snapshot = Invoke-Next -Invocation @('snapshot', '-Root', $testRoot, '-TaskId', 'alpha')
    Assert-That ($snapshot.Snapshotted -and (Test-Path -LiteralPath $snapshot.Path)) 'A verified closed task receives a non-destructive archive snapshot.'

    $conflictDetected = $false
    try {
        Invoke-Next -Invocation @('record', '-Root', $testRoot, '-TaskId', 'alpha', '-Type', 'decision.recorded', '-PayloadJson', '{"decision":"stale write"}', '-ExpectedSequence', '0') | Out-Null
    }
    catch { $conflictDetected = $_.Exception.Message -match 'Concurrent update detected' }
    Assert-That $conflictDetected 'An optimistic sequence check rejects a stale writer.'

    $ledger = Join-Path $testRoot '.icm-next\ledger.jsonl'
    $backup = Get-Content -Raw -LiteralPath $ledger -Encoding utf8
    $tampered = $backup -replace 'Alpha report', 'Alpha altered'
    Set-Content -LiteralPath $ledger -Value $tampered -Encoding utf8
    $tamperResult = Invoke-Next -Invocation @('verify', '-Root', $testRoot)
    Assert-That (-not $tamperResult.Valid) 'Ledger content edits are detected by the hash chain.'
    Assert-That (($tamperResult.Errors -join "`n") -match 'Ledger hash mismatch') 'Ledger verification identifies the tampered sequence.'
    Set-Content -LiteralPath $ledger -Value $backup -Encoding utf8

    Invoke-Next -Invocation @('new-task', '-Root', $testRoot, '-TaskId', 'missing', '-Title', 'Missing artifact', '-Objective', 'Demonstrate closeout refusal.', '-Criteria', 'artifact exists') | Out-Null
    $missingPayload = @{ path = 'tasks/missing/deliverables/absent.md'; validation = 'must be observed' } | ConvertTo-Json -Compress
    Invoke-Next -Invocation @('record', '-Root', $testRoot, '-TaskId', 'missing', '-Type', 'artifact.declared', '-PayloadJson', $missingPayload) | Out-Null
    Transition-Task -Task 'missing' -From 'queued' -To 'active'
    Transition-Task -Task 'missing' -From 'active' -To 'ready_to_close'
    $missingCloseBlocked = $false
    try { Transition-Task -Task 'missing' -From 'ready_to_close' -To 'closed' }
    catch { $missingCloseBlocked = $_.Exception.Message -match 'has not been observed' }
    Assert-That $missingCloseBlocked 'A task cannot be represented as complete without an observed declared artifact.'

    Invoke-Next -Invocation @('new-task', '-Root', $testRoot, '-TaskId', 'sensitive', '-Title', 'External message', '-Objective', 'Prepare an externally visible response.', '-Criteria', 'message exists', '-ApprovalKind', 'external_communication') | Out-Null
    $sensitiveRelative = 'tasks/sensitive/deliverables/message.md'
    Invoke-Next -Invocation @('record', '-Root', $testRoot, '-TaskId', 'sensitive', '-Type', 'artifact.declared', '-PayloadJson', (@{ path = $sensitiveRelative; validation = 'reviewed outbound message' } | ConvertTo-Json -Compress)) | Out-Null
    Set-Content -LiteralPath (Join-Path $testRoot $sensitiveRelative) -Value 'Approved external message.' -Encoding utf8
    Invoke-Next -Invocation @('observe', '-Root', $testRoot, '-TaskId', 'sensitive', '-ArtifactPath', $sensitiveRelative) | Out-Null
    Invoke-Next -Invocation @('record', '-Root', $testRoot, '-TaskId', 'sensitive', '-Type', 'check.recorded', '-PayloadJson', (@{ criterion = 'message exists'; result = 'pass'; evidence = $sensitiveRelative } | ConvertTo-Json -Compress)) | Out-Null
    Transition-Task -Task 'sensitive' -From 'queued' -To 'active'
    Transition-Task -Task 'sensitive' -From 'active' -To 'ready_to_close'
    $approvalBlocked = $false
    try { Transition-Task -Task 'sensitive' -From 'ready_to_close' -To 'closed' }
    catch { $approvalBlocked = $_.Exception.Message -match 'Approval.*required' }
    Assert-That $approvalBlocked 'External communication cannot close without explicit human approval.'
    Invoke-Next -Invocation @('approve', '-Root', $testRoot, '-TaskId', 'sensitive', '-ApprovalKind', 'external_communication', '-Approver', 'Max Loriner', '-Note', 'Reviewed for release.') | Out-Null
    Transition-Task -Task 'sensitive' -From 'ready_to_close' -To 'closed'
    Assert-That ((Invoke-Next -Invocation @('verify', '-Root', $testRoot)).Valid) 'A recorded human approval satisfies the sensitive-task close gate.'

    $legacyDirectory = Join-Path $testRoot 'archive\completed-tasks\2026-01-01_legacy-fixture'
    New-Item -ItemType Directory -Path $legacyDirectory -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $legacyDirectory 'TASK.md') -Value "# Legacy fixture`n`n## Required deliverables`n- path: deliverables/absent.md; description: expected file; validation: exists" -Encoding utf8
    Set-Content -LiteralPath (Join-Path $legacyDirectory 'STATUS.md') -Value "## Current stage`n04_deliver_archive" -Encoding utf8
    Set-Content -LiteralPath (Join-Path $legacyDirectory 'pipeline.md') -Value 'Active stage: 03_review' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $legacyDirectory '04_review.md') -Value "Final artifact: final.html`nExternal deliverable reference: https://example.test/source.pdf" -Encoding utf8
    $legacyBefore = Get-Content -Raw -LiteralPath (Join-Path $legacyDirectory 'TASK.md') -Encoding utf8
    $legacyInventory = Invoke-Next -Invocation @('inventory-legacy', '-Root', $testRoot)
    Assert-That ($legacyInventory.Records -eq 1) 'Legacy inventory finds an archived record without modifying it.'
    $legacyJson = Get-Content -Raw -LiteralPath (Join-Path $testRoot '.icm-next\generated\legacy-inventory.json') -Encoding utf8 | ConvertFrom-Json
    Assert-That ($legacyJson.records[0].evidence_status -eq 'legacy-claim-unverified') 'Legacy inventory flags absent evidence without changing its historical meaning.'
    Assert-That (($legacyJson.records[0].review_mentions_missing_artifacts -contains 'final.html') -and -not ($legacyJson.records[0].review_mentions_missing_artifacts -contains 'source.pdf')) 'Legacy inventory distinguishes local artifact claims from external source URLs.'
    Invoke-Next -Invocation @('import-legacy', '-Root', $testRoot) | Out-Null
    Assert-That ((Get-Content -Raw -LiteralPath (Join-Path $legacyDirectory 'TASK.md') -Encoding utf8) -eq $legacyBefore) 'Legacy import preserves source bytes.'
    Assert-That ((Invoke-Next -Invocation @('verify', '-Root', $testRoot)).Valid) 'Imported legacy records participate in verification through a recorded fingerprint.'

    Remove-Item -LiteralPath (Join-Path $testRoot '.icm-next\generated\dashboard.md') -Force
    $recovery = Invoke-Next -Invocation @('recover', '-Root', $testRoot)
    Assert-That ($recovery.Recovered -and (Test-Path -LiteralPath (Join-Path $testRoot '.icm-next\generated\dashboard.md'))) 'Recovery regenerates dashboard and context views from authoritative events.'

    [pscustomobject]@{
        Passed = $true
        Assertions = @($assertions)
        Evidence = @(
            'Two independent task records coexist without a single active-task pointer.',
            'Dependency gates, optimistic concurrency, and artifact drift are verified.',
            'Generated context is recoverable from the append-only ledger.',
            'Closed tasks require observed artifacts, passing acceptance checks, and configured human approvals.',
            'Artifact changes require explicit reopen and fresh review before re-close.',
            'Legacy records are inventoried and fingerprinted without rewriting their source bytes.',
            'The hash chain detects ordinary ledger tampering; it is not presented as a cryptographic access-control system.'
        )
    }
}
finally {
    if ((Test-Path -LiteralPath $testRoot) -and $testRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
