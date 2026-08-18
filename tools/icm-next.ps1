[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('init', 'new-task', 'transition', 'record', 'observe', 'reopen', 'approve', 'compile', 'dashboard', 'recover', 'snapshot', 'inventory-legacy', 'import-legacy', 'verify')]
    [string]$Command,

    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [string]$TaskId,
    [string]$Title,
    [string]$Objective,
    [string[]]$Criteria = @(),
    [string[]]$DependsOn = @(),
    [string[]]$ApprovalKind = @(),
    [string]$Type,
    [string]$PayloadJson = '{}',
    [string]$ArtifactPath,
    [string]$To,
    [string]$ExpectedFrom,
    [string]$Reason,
    [string]$Approver,
    [string]$Note,
    [string]$Actor = 'human-or-agent',
    [int]$ExpectedSequence = -1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Get-StorePath { Join-Path $Root '.icm-next' }
function Get-LedgerPath { Join-Path (Get-StorePath) 'ledger.jsonl' }
function Get-GeneratedPath { Join-Path (Get-StorePath) 'generated' }
function Get-ArchivePath { Join-Path (Get-StorePath) 'archives' }
function Get-ConfigPath { Join-Path (Get-StorePath) 'config.json' }
function Get-SchemaPolicyPath { Join-Path (Get-StorePath) 'SCHEMA_POLICY.md' }

function Get-ApprovalKinds {
    return @('external_communication', 'production_deployment', 'financial', 'legal', 'destructive_change')
}

function Get-StringArray {
    param($Value)
    return @($Value | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { [string]$_ })
}

function Write-JsonFile {
    param([string]$Path, $Value)
    Write-Utf8NoBom -Path $Path -Text ($Value | ConvertTo-Json -Depth 30)
}

function Initialize-Store {
    [IO.Directory]::CreateDirectory($Root) | Out-Null
    [IO.Directory]::CreateDirectory((Get-StorePath)) | Out-Null
    [IO.Directory]::CreateDirectory((Get-GeneratedPath)) | Out-Null
    [IO.Directory]::CreateDirectory((Join-Path (Get-GeneratedPath) 'contexts')) | Out-Null
    [IO.Directory]::CreateDirectory((Get-ArchivePath)) | Out-Null
    $ledger = Get-LedgerPath
    if (-not (Test-Path -LiteralPath $ledger)) {
        Write-Utf8NoBom -Path $ledger -Text ''
    }
    if (-not (Test-Path -LiteralPath (Get-ConfigPath))) {
        Write-JsonFile -Path (Get-ConfigPath) -Value ([ordered]@{
            schema = 'icm-next-config/v1'
            mode = 'single_machine_trusted'
            external_storage = 'disabled'
            artifact_change_policy = 'reopen_and_review'
            git_checkpoints = 'recommended_not_required'
            schema_owner = 'workspace_owner'
            approval_kinds = @(Get-ApprovalKinds)
        })
    }
    if (-not (Test-Path -LiteralPath (Get-SchemaPolicyPath))) {
        Write-Utf8NoBom -Path (Get-SchemaPolicyPath) -Text @"
# ICM Next schema policy

This Phase 1 store is single-machine and local-only. `ledger.jsonl` is the task
authority; generated files may be recreated. Schema changes require a new schema
version, a migration note, and compatibility tests. Git checkpoints are optional.
Artifact changes after closure require an explicit reopen and fresh review.
"@
    }
}

function Test-TaskId {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -notmatch '^[a-z0-9][a-z0-9-]{1,80}$') {
        throw 'TaskId must use lowercase letters, digits, and hyphens (2-81 characters).'
    }
}

function Get-Sha256 {
    param([string]$Text)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-EventBodyJson {
    param($Event)
    $body = [ordered]@{
        schema = $Event.schema
        event_id = $Event.event_id
        sequence = [int]$Event.sequence
        timestamp = $Event.timestamp
        actor = $Event.actor
        task_id = $Event.task_id
        type = $Event.type
        payload_json = $Event.payload_json
        previous_hash = $Event.previous_hash
    }
    return ($body | ConvertTo-Json -Compress -Depth 20)
}

function Get-LedgerEvents {
    $ledger = Get-LedgerPath
    if (-not (Test-Path -LiteralPath $ledger)) { return @() }
    $events = @()
    foreach ($line in Get-Content -LiteralPath $ledger -Encoding UTF8) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            try { $events += ($line | ConvertFrom-Json -DateKind String -ErrorAction Stop) }
            catch { throw "Ledger contains invalid JSON: $($_.Exception.Message)" }
        }
    }
    return $events
}

function Get-Payload {
    param($Event)
    try { return ($Event.payload_json | ConvertFrom-Json -ErrorAction Stop) }
    catch { throw "Event $($Event.event_id) has invalid payload JSON: $($_.Exception.Message)" }
}

function Get-PropertyValue {
    param($Object, [string]$Name)
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-LedgerIntegrity {
    $errors = [Collections.Generic.List[string]]::new()
    $expectedSequence = 1
    $previousHash = 'GENESIS'
    foreach ($event in Get-LedgerEvents) {
        if ([int]$event.sequence -ne $expectedSequence) {
            $errors.Add("Ledger sequence expected $expectedSequence but found $($event.sequence).")
        }
        if ($event.previous_hash -ne $previousHash) {
            $errors.Add("Ledger previous hash mismatch at sequence $($event.sequence).")
        }
        $actualHash = Get-Sha256 -Text (Get-EventBodyJson -Event $event)
        if ($event.hash -ne $actualHash) {
            $errors.Add("Ledger hash mismatch at sequence $($event.sequence).")
        }
        $previousHash = $event.hash
        $expectedSequence++
    }
    return [pscustomobject]@{
        Valid = ($errors.Count -eq 0)
        Errors = @($errors)
        HeadHash = $previousHash
        LastSequence = $expectedSequence - 1
    }
}

function Acquire-LedgerLock {
    $lockPath = (Get-LedgerPath) + '.lock'
    $deadline = [DateTime]::UtcNow.AddSeconds(8)
    while ($true) {
        try {
            $stream = [IO.File]::Open($lockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
            return [pscustomobject]@{ Stream = $stream; Path = $lockPath }
        }
        catch [IO.IOException] {
            if ([DateTime]::UtcNow -ge $deadline) { throw "Timed out waiting for ledger lock: $lockPath" }
            Start-Sleep -Milliseconds 100
        }
    }
}

function Add-LedgerEvent {
    param(
        [string]$EventTaskId,
        [string]$EventType,
        [string]$EventPayloadJson,
        [string]$EventActor,
        [int]$EventExpectedSequence = -1
    )
    Initialize-Store
    try { $null = $EventPayloadJson | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "PayloadJson must be valid JSON: $($_.Exception.Message)" }

    $lock = Acquire-LedgerLock
    try {
        $integrity = Test-LedgerIntegrity
        if (-not $integrity.Valid) { throw "Cannot append to an invalid ledger: $($integrity.Errors -join ' ')" }
        if ($EventType -in @('task.created', 'legacy.imported') -and (Get-LedgerEvents | Where-Object { $_.task_id -eq $EventTaskId -and $_.type -in @('task.created', 'legacy.imported') })) {
            throw "Task already exists: $EventTaskId"
        }
        if ($EventExpectedSequence -ge 0 -and $EventExpectedSequence -ne $integrity.LastSequence) {
            throw "Concurrent update detected. Expected ledger sequence $EventExpectedSequence; current sequence is $($integrity.LastSequence). Recompile context and retry."
        }
        $event = [ordered]@{
            schema = 'icm-next-event/v1'
            event_id = [guid]::NewGuid().ToString()
            sequence = $integrity.LastSequence + 1
            timestamp = [DateTime]::UtcNow.ToString('o')
            actor = $EventActor
            task_id = $EventTaskId
            type = $EventType
            payload_json = $EventPayloadJson
            previous_hash = $integrity.HeadHash
        }
        $event.hash = Get-Sha256 -Text (Get-EventBodyJson -Event ([pscustomobject]$event))
        $json = $event | ConvertTo-Json -Compress -Depth 20
        [IO.File]::AppendAllText((Get-LedgerPath), $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        return [pscustomobject]$event
    }
    finally {
        $lock.Stream.Dispose()
        if (Test-Path -LiteralPath $lock.Path) { Remove-Item -LiteralPath $lock.Path -Force }
    }
}

function Resolve-WorkspacePath {
    param([string]$InputPath)
    $candidate = if ([IO.Path]::IsPathRooted($InputPath)) { [IO.Path]::GetFullPath($InputPath) } else { [IO.Path]::GetFullPath((Join-Path $Root $InputPath)) }
    $rootPrefix = $Root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path must stay inside the ICM Next root: $InputPath"
    }
    return $candidate
}

function Get-RelativeWorkspacePath {
    param([string]$FullPath)
    return $FullPath.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/'
}

function Get-DirectoryFingerprint {
    param([string]$DirectoryPath)
    $directory = Resolve-WorkspacePath -InputPath $DirectoryPath
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { throw "Legacy directory is missing: $DirectoryPath" }
    $lines = foreach ($file in Get-ChildItem -LiteralPath $directory -File -Recurse | Sort-Object FullName) {
        $relative = $file.FullName.Substring($directory.Length).TrimStart('\', '/') -replace '\\', '/'
        "$relative|$((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant())"
    }
    return Get-Sha256 -Text ($lines -join "`n")
}

function New-TaskEvent {
    Test-TaskId -Value $TaskId
    if ([string]::IsNullOrWhiteSpace($Title) -or [string]::IsNullOrWhiteSpace($Objective)) {
        throw 'new-task requires Title and Objective.'
    }
    $requestedApprovalKinds = Get-StringArray -Value $ApprovalKind
    foreach ($kind in $requestedApprovalKinds) {
        if ($kind -notin (Get-ApprovalKinds)) { throw "Unsupported approval kind: $kind" }
    }
    [IO.Directory]::CreateDirectory((Join-Path $Root "tasks\$TaskId\work")) | Out-Null
    [IO.Directory]::CreateDirectory((Join-Path $Root "tasks\$TaskId\deliverables")) | Out-Null
    $payload = [ordered]@{
        title = $Title
        objective = $Objective
        criteria = @($Criteria)
        depends_on = @($DependsOn)
        approval_kinds = @($requestedApprovalKinds)
    } | ConvertTo-Json -Compress -Depth 10
    return Add-LedgerEvent -EventTaskId $TaskId -EventType 'task.created' -EventPayloadJson $payload -EventActor $Actor -EventExpectedSequence $ExpectedSequence
}

function Get-AllowedTransitions {
    return @{
        queued = @('active', 'cancelled')
        active = @('waiting_review', 'ready_to_close', 'blocked', 'cancelled')
        waiting_review = @('active', 'ready_to_close', 'blocked', 'cancelled')
        ready_to_close = @('active', 'blocked', 'closed', 'cancelled')
        blocked = @('active', 'cancelled')
        closed = @()
        cancelled = @()
        legacy = @()
    }
}

function New-CompiledState {
    $integrity = Test-LedgerIntegrity
    $errors = [Collections.Generic.List[string]]::new()
    foreach ($error in $integrity.Errors) { $errors.Add($error) }
    $tasks = @{}
    $allowed = Get-AllowedTransitions

    foreach ($event in Get-LedgerEvents) {
        $payload = Get-Payload -Event $event
        if ($event.type -eq 'task.created') {
            if ($tasks.ContainsKey($event.task_id)) { $errors.Add("Task '$($event.task_id)' was created more than once."); continue }
            $titleValue = [string](Get-PropertyValue -Object $payload -Name 'title')
            $objectiveValue = [string](Get-PropertyValue -Object $payload -Name 'objective')
            if ([string]::IsNullOrWhiteSpace($titleValue) -or [string]::IsNullOrWhiteSpace($objectiveValue)) {
                $errors.Add("Task '$($event.task_id)' has an incomplete creation event.")
            }
            $tasks[$event.task_id] = [pscustomobject]@{
                id = $event.task_id
                title = $titleValue
                objective = $objectiveValue
                state = 'queued'
                depends_on = @(Get-StringArray -Value (Get-PropertyValue -Object $payload -Name 'depends_on'))
                criteria = @(Get-StringArray -Value (Get-PropertyValue -Object $payload -Name 'criteria'))
                approval_kinds = @(Get-StringArray -Value (Get-PropertyValue -Object $payload -Name 'approval_kinds'))
                approvals = [Collections.Generic.List[object]]::new()
                reopened_sequence = 0
                closed_sequence = 0
                contexts = [Collections.Generic.List[object]]::new()
                artifacts = @{}
                checks = @{}
                decisions = [Collections.Generic.List[object]]::new()
                handoff = $null
                last_sequence = [int]$event.sequence
            }
            continue
        }
        if ($event.type -eq 'legacy.imported') {
            if ($tasks.ContainsKey($event.task_id)) { $errors.Add("Legacy task '$($event.task_id)' was imported more than once."); continue }
            $legacyPath = [string](Get-PropertyValue -Object $payload -Name 'legacy_path')
            $tasks[$event.task_id] = [pscustomobject]@{
                id = $event.task_id
                title = [string](Get-PropertyValue -Object $payload -Name 'title')
                objective = 'Imported legacy record; original bytes and meaning are preserved.'
                state = 'legacy'
                depends_on = @()
                criteria = @()
                approval_kinds = @()
                approvals = [Collections.Generic.List[object]]::new()
                reopened_sequence = 0
                closed_sequence = 0
                contexts = [Collections.Generic.List[object]]::new()
                artifacts = @{}
                checks = @{}
                decisions = [Collections.Generic.List[object]]::new()
                handoff = $null
                last_sequence = [int]$event.sequence
                legacy = $true
                legacy_path = $legacyPath
                legacy_fingerprint = [string](Get-PropertyValue -Object $payload -Name 'fingerprint')
                legacy_evidence_status = [string](Get-PropertyValue -Object $payload -Name 'evidence_status')
            }
            continue
        }
        if (-not $tasks.ContainsKey($event.task_id)) { $errors.Add("Event $($event.sequence) refers to unknown task '$($event.task_id)'."); continue }
        $task = $tasks[$event.task_id]
        $task.last_sequence = [int]$event.sequence
        switch ($event.type) {
            'task.transitioned' {
                $from = [string](Get-PropertyValue -Object $payload -Name 'from')
                $to = [string](Get-PropertyValue -Object $payload -Name 'to')
                if ($from -ne $task.state) { $errors.Add("Task '$($task.id)' transition at sequence $($event.sequence) expected from '$($task.state)', not '$from'.") }
                elseif (-not $allowed.ContainsKey($to) -or $allowed[$task.state] -notcontains $to) { $errors.Add("Task '$($task.id)' has invalid transition '$($task.state)' -> '$to'.") }
                else {
                    $task.state = $to
                    if ($to -eq 'closed') { $task.closed_sequence = [int]$event.sequence }
                }
            }
            'task.reopened' {
                if ($task.state -ne 'closed') { $errors.Add("Task '$($task.id)' can be reopened only from closed, not '$($task.state)'.") }
                else {
                    $task.state = 'active'
                    $task.reopened_sequence = [int]$event.sequence
                }
            }
            'approval.granted' {
                $kind = [string](Get-PropertyValue -Object $payload -Name 'kind')
                if ($kind -notin $task.approval_kinds) { $errors.Add("Task '$($task.id)' received unexpected approval kind '$kind'.") }
                else { $task.approvals.Add([pscustomobject]@{ kind = $kind; sequence = [int]$event.sequence; approver = [string](Get-PropertyValue -Object $payload -Name 'approver'); note = [string](Get-PropertyValue -Object $payload -Name 'note') }) }
            }
            'context.linked' { $task.contexts.Add($payload) }
            'artifact.declared' {
                $path = [string](Get-PropertyValue -Object $payload -Name 'path')
                if ([string]::IsNullOrWhiteSpace($path)) { $errors.Add("Task '$($task.id)' declared an artifact without a path.") }
                else { $task.artifacts[$path] = [pscustomobject]@{ path = $path; validation = [string](Get-PropertyValue -Object $payload -Name 'validation'); observed_hash = $null; observed_sequence = $null } }
            }
            'artifact.observed' {
                $path = [string](Get-PropertyValue -Object $payload -Name 'path')
                if (-not $task.artifacts.ContainsKey($path)) { $errors.Add("Task '$($task.id)' observed undeclared artifact '$path'.") }
                else {
                    $task.artifacts[$path].observed_hash = [string](Get-PropertyValue -Object $payload -Name 'sha256')
                    $task.artifacts[$path].observed_sequence = [int]$event.sequence
                }
            }
            'check.recorded' {
                $criterion = [string](Get-PropertyValue -Object $payload -Name 'criterion')
                if ([string]::IsNullOrWhiteSpace($criterion)) { $errors.Add("Task '$($task.id)' recorded a check without a criterion.") }
                else { $task.checks[$criterion] = [pscustomobject]@{ payload = $payload; sequence = [int]$event.sequence } }
            }
            'decision.recorded' { $task.decisions.Add($payload) }
            'handoff.recorded' { $task.handoff = $payload }
            default { $errors.Add("Task '$($task.id)' has unsupported event type '$($event.type)'.") }
        }
    }

    foreach ($task in $tasks.Values) {
        if ($null -ne $task.PSObject.Properties['legacy']) {
            $task | Add-Member -NotePropertyName blocked_by -NotePropertyValue @()
            try {
                if ((Get-DirectoryFingerprint -DirectoryPath $task.legacy_path) -ne $task.legacy_fingerprint) {
                    $errors.Add("Imported legacy task '$($task.id)' no longer matches its recorded source fingerprint.")
                }
            }
            catch { $errors.Add($_.Exception.Message) }
            continue
        }
        $blockedBy = [Collections.Generic.List[string]]::new()
        foreach ($dependency in $task.depends_on) {
            if ([string]::IsNullOrWhiteSpace([string]$dependency)) { continue }
            if (-not $tasks.ContainsKey([string]$dependency)) { $errors.Add("Task '$($task.id)' depends on missing task '$dependency'."); $blockedBy.Add([string]$dependency) }
            elseif ($tasks[[string]$dependency].state -ne 'closed') { $blockedBy.Add([string]$dependency) }
        }
        $task | Add-Member -NotePropertyName blocked_by -NotePropertyValue @($blockedBy)
        if ($blockedBy.Count -gt 0 -and $task.state -in @('active', 'waiting_review', 'ready_to_close', 'closed')) {
            $errors.Add("Task '$($task.id)' is '$($task.state)' while dependencies remain open: $($blockedBy -join ', ').")
        }
        foreach ($link in $task.contexts) {
            $uri = [string](Get-PropertyValue -Object $link -Name 'uri')
            if (-not [string]::IsNullOrWhiteSpace($uri) -and $uri -notmatch '^[a-z][a-z0-9+.-]*://') {
                try { if (-not (Test-Path -LiteralPath (Resolve-WorkspacePath -InputPath $uri))) { $errors.Add("Task '$($task.id)' references missing context '$uri'.") } }
                catch { $errors.Add($_.Exception.Message) }
            }
        }
        if ($task.state -eq 'closed') {
            foreach ($artifact in $task.artifacts.Values) {
                if ([string]::IsNullOrWhiteSpace($artifact.observed_hash)) { $errors.Add("Closed task '$($task.id)' has no observation for declared artifact '$($artifact.path)'."); continue }
                if ([int]$artifact.observed_sequence -le [int]$task.reopened_sequence) { $errors.Add("Closed task '$($task.id)' needs a fresh artifact observation after reopen: '$($artifact.path)'."); continue }
                try {
                    $file = Resolve-WorkspacePath -InputPath $artifact.path
                    if (-not (Test-Path -LiteralPath $file)) { $errors.Add("Closed task '$($task.id)' is missing artifact '$($artifact.path)'.") }
                    elseif ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $artifact.observed_hash) { $errors.Add("Closed task '$($task.id)' artifact hash mismatch: '$($artifact.path)'.") }
                }
                catch { $errors.Add($_.Exception.Message) }
            }
            foreach ($criterion in $task.criteria) {
                if ([string]::IsNullOrWhiteSpace([string]$criterion)) { continue }
                $check = $task.checks[[string]$criterion]
                if ($null -eq $check -or [string](Get-PropertyValue -Object $check.payload -Name 'result') -ne 'pass' -or [int]$check.sequence -le [int]$task.reopened_sequence) {
                    $errors.Add("Closed task '$($task.id)' lacks a fresh passing check for '$criterion'.")
                }
            }
            foreach ($kind in $task.approval_kinds) {
                $currentApproval = @($task.approvals | Where-Object { $_.kind -eq $kind -and [int]$_.sequence -gt [int]$task.reopened_sequence })
                if ($currentApproval.Count -eq 0) { $errors.Add("Closed task '$($task.id)' lacks a current human approval for '$kind'.") }
            }
        }
    }

    $taskList = @($tasks.Values | Sort-Object id)
    return [pscustomobject]@{
        schema = 'icm-next-state/v1'
        generated_at = [DateTime]::UtcNow.ToString('o')
        ledger_head_hash = $integrity.HeadHash
        ledger_sequence = $integrity.LastSequence
        tasks = $taskList
        errors = @($errors)
    }
}

function Write-CompiledContext {
    param($Task, $State)
    $contextLines = [Collections.Generic.List[string]]::new()
    $contextLines.Add('# Generated task context')
    $contextLines.Add('')
    $contextLines.Add("Task: $($Task.id) — $($Task.title)")
    $contextLines.Add("State: $($Task.state)")
    $contextLines.Add("Ledger sequence: $($Task.last_sequence)")
    $contextLines.Add('')
    $contextLines.Add('## Objective')
    $contextLines.Add($Task.objective)
    $contextLines.Add('')
    $contextLines.Add('## Dependency gates')
    if ($Task.blocked_by.Count -eq 0) { $contextLines.Add('- None.') } else { foreach ($dependency in $Task.blocked_by) { $contextLines.Add("- Waiting for: $dependency") } }
    $contextLines.Add('')
    $contextLines.Add('## Direct context')
    if ($Task.contexts.Count -eq 0) { $contextLines.Add('- None recorded.') }
    else { foreach ($item in $Task.contexts) { $contextLines.Add("- $([string](Get-PropertyValue -Object $item -Name 'uri')) | purpose: $([string](Get-PropertyValue -Object $item -Name 'purpose')) | scope: $([string](Get-PropertyValue -Object $item -Name 'scope'))") } }
    $contextLines.Add('')
    $contextLines.Add('## Artifacts and evidence')
    if ($Task.artifacts.Count -eq 0) { $contextLines.Add('- None declared.') }
    else { foreach ($item in ($Task.artifacts.Values | Sort-Object path)) { $contextLines.Add("- $($item.path) | observed: $([bool](-not [string]::IsNullOrWhiteSpace($item.observed_hash))) | validation: $($item.validation)") } }
    $contextLines.Add('')
    $contextLines.Add('## Acceptance checks')
    if ($Task.criteria.Count -eq 0) { $contextLines.Add('- None declared.') }
    else { foreach ($criterion in $Task.criteria) { $check = $Task.checks[[string]$criterion]; $result = if ($null -eq $check) { 'unrecorded' } else { [string](Get-PropertyValue -Object $check.payload -Name 'result') }; $contextLines.Add("- ${criterion}: $result") } }
    if ($Task.approval_kinds.Count -gt 0) {
        $contextLines.Add(''); $contextLines.Add('## Human approval gates')
        foreach ($kind in $Task.approval_kinds) {
            $approved = @($Task.approvals | Where-Object { $_.kind -eq $kind -and [int]$_.sequence -gt [int]$Task.reopened_sequence }).Count -gt 0
            $contextLines.Add("- ${kind}: $(if ($approved) { 'approved' } else { 'required' })")
        }
    }
    if ($null -ne $Task.handoff) { $contextLines.Add(''); $contextLines.Add('## Latest handoff'); $contextLines.Add(($Task.handoff | ConvertTo-Json -Compress -Depth 10)) }
    $contextLines.Add(''); $contextLines.Add('## Operating rule'); $contextLines.Add('Treat this generated view as a convenience. The append-only ledger is authoritative; recompile after any update or conflict.')
    Write-Utf8NoBom -Path (Join-Path (Join-Path (Get-GeneratedPath) 'contexts') "$($Task.id).md") -Text ($contextLines -join [Environment]::NewLine)
}

function Get-TaskFromState {
    param($State, [string]$RequestedTaskId)
    Test-TaskId -Value $RequestedTaskId
    $task = @($State.tasks | Where-Object { $_.id -eq $RequestedTaskId })
    if ($task.Count -ne 1) { throw "Task not found: $RequestedTaskId" }
    return $task[0]
}

function Test-CloseReadiness {
    param($Task)
    $problems = [Collections.Generic.List[string]]::new()
    if ($Task.state -ne 'ready_to_close') { $problems.Add("Task '$($Task.id)' must be ready_to_close before closing.") }
    if ($Task.blocked_by.Count -gt 0) { $problems.Add("Task '$($Task.id)' has unresolved dependencies: $($Task.blocked_by -join ', ').") }
    foreach ($artifact in $Task.artifacts.Values) {
        if ([string]::IsNullOrWhiteSpace($artifact.observed_hash)) { $problems.Add("Artifact '$($artifact.path)' has not been observed."); continue }
        if ([int]$artifact.observed_sequence -le [int]$Task.reopened_sequence) { $problems.Add("Artifact '$($artifact.path)' needs a fresh observation after reopen."); continue }
        try {
            $file = Resolve-WorkspacePath -InputPath $artifact.path
            if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { $problems.Add("Artifact '$($artifact.path)' is missing.") }
            elseif ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $artifact.observed_hash) { $problems.Add("Artifact '$($artifact.path)' changed after observation.") }
        }
        catch { $problems.Add($_.Exception.Message) }
    }
    foreach ($criterion in $Task.criteria) {
        $check = $Task.checks[[string]$criterion]
        if ($null -eq $check -or [string](Get-PropertyValue -Object $check.payload -Name 'result') -ne 'pass' -or [int]$check.sequence -le [int]$Task.reopened_sequence) {
            $problems.Add("Criterion '$criterion' lacks a fresh passing check.")
        }
    }
    foreach ($kind in $Task.approval_kinds) {
        if (@($Task.approvals | Where-Object { $_.kind -eq $kind -and [int]$_.sequence -gt [int]$Task.reopened_sequence }).Count -eq 0) {
            $problems.Add("Approval '$kind' is required before close.")
        }
    }
    return @($problems)
}

function Invoke-TaskTransition {
    Test-TaskId -Value $TaskId
    if ([string]::IsNullOrWhiteSpace($To)) { throw 'transition requires To.' }
    $state = New-CompiledState
    $task = Get-TaskFromState -State $state -RequestedTaskId $TaskId
    if ($task.PSObject.Properties['legacy']) { throw 'Imported legacy tasks are read-only.' }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedFrom) -and $task.state -ne $ExpectedFrom) { throw "Expected task '$TaskId' to be '$ExpectedFrom', found '$($task.state)'." }
    $allowed = Get-AllowedTransitions
    if (-not $allowed.ContainsKey($task.state) -or $To -notin $allowed[$task.state]) { throw "Invalid transition '$($task.state)' -> '$To'." }
    if ($To -eq 'closed') {
        $problems = @(Test-CloseReadiness -Task $task)
        if ($problems.Count -gt 0) { throw "Close blocked: $($problems -join ' ')" }
    }
    $payload = [ordered]@{ from = $task.state; to = $To; reason = $Reason } | ConvertTo-Json -Compress
    return Add-LedgerEvent -EventTaskId $TaskId -EventType 'task.transitioned' -EventPayloadJson $payload -EventActor $Actor -EventExpectedSequence $ExpectedSequence
}

function Invoke-TaskReopen {
    Test-TaskId -Value $TaskId
    if ([string]::IsNullOrWhiteSpace($Reason)) { throw 'reopen requires a non-empty Reason.' }
    $task = Get-TaskFromState -State (New-CompiledState) -RequestedTaskId $TaskId
    if ($task.state -ne 'closed') { throw "Only closed tasks can reopen; '$TaskId' is '$($task.state)'." }
    $payload = [ordered]@{ reason = $Reason; prior_close_sequence = $task.closed_sequence } | ConvertTo-Json -Compress
    return Add-LedgerEvent -EventTaskId $TaskId -EventType 'task.reopened' -EventPayloadJson $payload -EventActor $Actor -EventExpectedSequence $ExpectedSequence
}

function Invoke-Approval {
    Test-TaskId -Value $TaskId
    $kinds = @(Get-StringArray -Value $ApprovalKind)
    if ($kinds.Count -ne 1) { throw 'approve requires exactly one ApprovalKind.' }
    if ([string]::IsNullOrWhiteSpace($Approver)) { throw 'approve requires Approver.' }
    $task = Get-TaskFromState -State (New-CompiledState) -RequestedTaskId $TaskId
    if ($kinds[0] -notin $task.approval_kinds) { throw "Task '$TaskId' does not require approval '$($kinds[0])'." }
    $payload = [ordered]@{ kind = $kinds[0]; approver = $Approver; note = $Note } | ConvertTo-Json -Compress
    return Add-LedgerEvent -EventTaskId $TaskId -EventType 'approval.granted' -EventPayloadJson $payload -EventActor "human:$Approver" -EventExpectedSequence $ExpectedSequence
}

function Write-Dashboard {
    param($State)
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('# ICM Next dashboard')
    $lines.Add('')
    $lines.Add("Generated: $($State.generated_at)")
    $lines.Add("Ledger sequence: $($State.ledger_sequence)")
    $lines.Add("Ledger head: $($State.ledger_head_hash)")
    $lines.Add('')
    $lines.Add('| Task | State | Dependency gates | Approval gates |')
    $lines.Add('|---|---|---|---|')
    foreach ($task in ($State.tasks | Sort-Object id)) {
        $dependencies = if ($task.blocked_by.Count -eq 0) { 'none' } else { $task.blocked_by -join ', ' }
        $approvals = if ($task.approval_kinds.Count -eq 0) { 'none' } else {
            (@($task.approval_kinds | ForEach-Object {
                $kind = $_
                if (@($task.approvals | Where-Object { $_.kind -eq $kind -and [int]$_.sequence -gt [int]$task.reopened_sequence }).Count -gt 0) { "${kind}: approved" } else { "${kind}: required" }
            }) -join '; ')
        }
        $lines.Add("| $($task.id) | $($task.state) | $dependencies | $approvals |")
    }
    $lines.Add('')
    $lines.Add('## Verification')
    if ($State.errors.Count -eq 0) { $lines.Add('No verification errors.') }
    else { foreach ($error in $State.errors) { $lines.Add("- $error") } }
    Write-Utf8NoBom -Path (Join-Path (Get-GeneratedPath) 'dashboard.md') -Text ($lines -join [Environment]::NewLine)
}

function Write-GeneratedViews {
    param([string]$OnlyTaskId)
    Initialize-Store
    $state = New-CompiledState
    Write-JsonFile -Path (Join-Path (Get-GeneratedPath) 'state.json') -Value $state
    $selected = if ([string]::IsNullOrWhiteSpace($OnlyTaskId)) { @($state.tasks) } else { @((Get-TaskFromState -State $state -RequestedTaskId $OnlyTaskId)) }
    foreach ($task in $selected) { Write-CompiledContext -Task $task -State $state }
    Write-Dashboard -State $state
    return [pscustomobject]@{ State = $state; Tasks = @($selected.id) }
}

function Invoke-Recovery {
    $views = Write-GeneratedViews -OnlyTaskId $TaskId
    $lines = @(
        '# ICM Next recovery report',
        '',
        "Recovered: $([DateTime]::UtcNow.ToString('o'))",
        "Ledger sequence: $($views.State.ledger_sequence)",
        "Ledger head: $($views.State.ledger_head_hash)",
        "Recompiled tasks: $($views.Tasks -join ', ')",
        '',
        'Generated views were recreated from the ledger. No legacy archive or event was modified.'
    )
    if ($views.State.errors.Count -gt 0) {
        $lines += ''; $lines += '## Verification issues'; $lines += ($views.State.errors | ForEach-Object { "- $_" })
    }
    Write-Utf8NoBom -Path (Join-Path (Get-GeneratedPath) 'RECOVERY.md') -Text ($lines -join [Environment]::NewLine)
    return [pscustomobject]@{ Recovered = $true; Tasks = $views.Tasks; Valid = ($views.State.errors.Count -eq 0); Errors = $views.State.errors }
}

function New-ArchiveSnapshot {
    Test-TaskId -Value $TaskId
    $views = Write-GeneratedViews -OnlyTaskId $TaskId
    $task = Get-TaskFromState -State $views.State -RequestedTaskId $TaskId
    if ($task.state -ne 'closed') { throw "Only closed tasks can be snapshotted; '$TaskId' is '$($task.state)'." }
    if ($views.State.errors.Count -gt 0) { throw "Snapshot blocked by verification errors: $($views.State.errors -join ' ')" }
    $head = $views.State.ledger_head_hash.Substring(0, 12)
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
    $snapshotDirectory = Join-Path (Get-ArchivePath) "$stamp-$TaskId-$head"
    if (Test-Path -LiteralPath $snapshotDirectory) { throw "Snapshot already exists: $snapshotDirectory" }
    [IO.Directory]::CreateDirectory($snapshotDirectory) | Out-Null
    $manifest = [ordered]@{
        schema = 'icm-next-snapshot/v1'
        created_at = [DateTime]::UtcNow.ToString('o')
        task_id = $TaskId
        ledger_sequence = $views.State.ledger_sequence
        ledger_head_hash = $views.State.ledger_head_hash
        task = $task
        note = 'Generated export. The ledger remains authoritative.'
    }
    Write-JsonFile -Path (Join-Path $snapshotDirectory 'snapshot.json') -Value $manifest
    Copy-Item -LiteralPath (Join-Path (Join-Path (Get-GeneratedPath) 'contexts') "$TaskId.md") -Destination (Join-Path $snapshotDirectory 'context.md')
    Write-Utf8NoBom -Path (Join-Path $snapshotDirectory 'README.md') -Text "# ICM Next snapshot`n`nTask: $TaskId`nLedger head: $($views.State.ledger_head_hash)`n`nThis is an export; it does not replace the ledger."
    return [pscustomobject]@{ Snapshotted = $true; TaskId = $TaskId; Path = $snapshotDirectory; LedgerHead = $views.State.ledger_head_hash }
}

function ConvertTo-LegacyTaskId {
    param([string]$Name)
    $slug = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')
    if ($slug.Length -gt 68) { $slug = $slug.Substring(0, 68).TrimEnd('-') }
    return "legacy-$slug"
}

function Get-LegacyDeliverablePaths {
    param([string]$Directory)
    $taskFile = Join-Path $Directory 'TASK.md'
    if (-not (Test-Path -LiteralPath $taskFile)) { return @() }
    $text = Get-Content -Raw -LiteralPath $taskFile -Encoding UTF8
    $paths = [Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches($text, '(?m)^-\s*path:\s*(?<path>[^;\r\n]+);')) { $paths.Add($match.Groups['path'].Value.Trim().Trim('`')) }
    foreach ($match in [regex]::Matches($text, '(?m)^-\s*`(?<path>[^`]+\.(?:md|html|pdf|docx|xlsx|csv|json))`')) { $paths.Add($match.Groups['path'].Value.Trim()) }
    return @($paths | Select-Object -Unique)
}

function Get-LegacyMentionedMissingPaths {
    param([string]$Directory)
    $missing = [Collections.Generic.List[string]]::new()
    foreach ($stageRecord in Get-ChildItem -LiteralPath $Directory -File -Recurse -Filter '*.md') {
        $text = Get-Content -Raw -LiteralPath $stageRecord.FullName -Encoding UTF8
        foreach ($line in ($text -split "`r?`n")) {
            if ($line -notmatch '(?i)\b(artifact|deliverable|built|output|final)\b') { continue }
            if ($line -match 'https?://') { continue }
            foreach ($match in [regex]::Matches($line, '(?<![A-Za-z0-9_-])(?<path>[A-Za-z0-9_.-]+\.(?:html|pdf|docx|xlsx|csv|json))(?![A-Za-z0-9_-])')) {
                $candidate = $match.Groups['path'].Value
                if (-not (Test-Path -LiteralPath (Join-Path $Directory $candidate))) { $missing.Add($candidate) }
            }
        }
    }
    return @($missing | Select-Object -Unique)
}

function Get-LegacyInventoryData {
    $completed = Join-Path $Root 'archive\completed-tasks'
    $records = [Collections.Generic.List[object]]::new()
    if (Test-Path -LiteralPath $completed) {
        foreach ($directory in Get-ChildItem -LiteralPath $completed -Directory | Sort-Object Name) {
            $relative = Get-RelativeWorkspacePath -FullPath $directory.FullName
            $statusPath = Join-Path $directory.FullName 'STATUS.md'
            $pipelinePath = Join-Path $directory.FullName 'pipeline.md'
            $statusText = if (Test-Path -LiteralPath $statusPath) { Get-Content -Raw -LiteralPath $statusPath -Encoding UTF8 } else { '' }
            $pipelineText = if (Test-Path -LiteralPath $pipelinePath) { Get-Content -Raw -LiteralPath $pipelinePath -Encoding UTF8 } else { '' }
            $statusStage = if ($statusText -match '(?ms)^## Current stage\s*\r?\n(?<stage>[^\r\n]+)') { $Matches['stage'].Trim() } else { $null }
            $pipelineStage = if ($pipelineText -match '(?im)^Active stage:\s*(?<stage>[^\r\n(]+)') { $Matches['stage'].Trim() } else { $null }
            $declared = @(Get-LegacyDeliverablePaths -Directory $directory.FullName)
            $missingDeclared = @($declared | Where-Object { -not (Test-Path -LiteralPath (Join-Path $directory.FullName $_)) })
            $mentionedMissing = @(Get-LegacyMentionedMissingPaths -Directory $directory.FullName)
            $title = $directory.Name
            $taskPath = Join-Path $directory.FullName 'TASK.md'
            if (Test-Path -LiteralPath $taskPath) {
                $taskText = Get-Content -Raw -LiteralPath $taskPath -Encoding UTF8
                if ($taskText -match '(?m)^#\s+(.+)$') { $title = $Matches[1].Trim() }
            }
            $records.Add([pscustomobject]@{
                import_task_id = ConvertTo-LegacyTaskId -Name $directory.Name
                title = $title
                legacy_path = $relative
                fingerprint = Get-DirectoryFingerprint -DirectoryPath $relative
                workflow_manifest_exists = Test-Path -LiteralPath (Join-Path $directory.FullName 'meta\WORKFLOW_MANIFEST.md')
                archive_record_exists = Test-Path -LiteralPath (Join-Path $directory.FullName 'meta\ARCHIVE.md')
                status_stage = $statusStage
                pipeline_stage = $pipelineStage
                stage_disagreement = ($null -ne $statusStage -and $null -ne $pipelineStage -and $statusStage -ne $pipelineStage)
                declared_deliverables = $declared
                missing_declared_deliverables = $missingDeclared
                review_mentions_missing_artifacts = $mentionedMissing
                evidence_status = if ($missingDeclared.Count -gt 0 -or $mentionedMissing.Count -gt 0 -or -not (Test-Path -LiteralPath (Join-Path $directory.FullName 'meta\WORKFLOW_MANIFEST.md'))) { 'legacy-claim-unverified' } else { 'unknown' }
            })
        }
    }
    return [pscustomobject]@{ schema = 'icm-next-legacy-inventory/v1'; generated_at = [DateTime]::UtcNow.ToString('o'); records = @($records) }
}

function Write-LegacyInventory {
    $inventory = Get-LegacyInventoryData
    Write-JsonFile -Path (Join-Path (Get-GeneratedPath) 'legacy-inventory.json') -Value $inventory
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('# Legacy archive inventory')
    $lines.Add('')
    $lines.Add('Legacy records are not rewritten. `legacy-claim-unverified` means evidence is absent or inconsistent, not that the original task failed.')
    $lines.Add('')
    $lines.Add('| Archive | Evidence status | Missing declared | Stage-mentioned missing | Stage disagreement |')
    $lines.Add('|---|---|---|---|---|')
    foreach ($record in $inventory.records) {
        $lines.Add("| $($record.legacy_path) | $($record.evidence_status) | $($record.missing_declared_deliverables -join ', ') | $($record.review_mentions_missing_artifacts -join ', ') | $($record.stage_disagreement) |")
    }
    Write-Utf8NoBom -Path (Join-Path (Get-GeneratedPath) 'legacy-inventory.md') -Text ($lines -join [Environment]::NewLine)
    return $inventory
}

function Import-LegacyRecords {
    $inventory = Write-LegacyInventory
    $imported = [Collections.Generic.List[string]]::new()
    $skipped = [Collections.Generic.List[string]]::new()
    foreach ($record in $inventory.records) {
        $existing = Get-LedgerEvents | Where-Object { $_.task_id -eq $record.import_task_id -and $_.type -eq 'legacy.imported' }
        if ($existing) { $skipped.Add($record.import_task_id); continue }
        $payload = [ordered]@{
            title = $record.title
            legacy_path = $record.legacy_path
            fingerprint = $record.fingerprint
            evidence_status = $record.evidence_status
            source_schema = 'legacy-filesystem'
        } | ConvertTo-Json -Compress -Depth 20
        Add-LedgerEvent -EventTaskId $record.import_task_id -EventType 'legacy.imported' -EventPayloadJson $payload -EventActor $Actor -EventExpectedSequence -1 | Out-Null
        $imported.Add($record.import_task_id)
    }
    return [pscustomobject]@{ Imported = @($imported); Skipped = @($skipped); InventoryPath = (Join-Path (Get-GeneratedPath) 'legacy-inventory.md') }
}

switch ($Command) {
    'init' {
        Initialize-Store
        [pscustomobject]@{ Initialized = $true; Store = (Get-StorePath); Ledger = (Get-LedgerPath); Config = (Get-ConfigPath); Policy = (Get-SchemaPolicyPath) }
    }
    'new-task' {
        Initialize-Store
        New-TaskEvent
    }
    'transition' {
        Initialize-Store
        Invoke-TaskTransition
    }
    'record' {
        Test-TaskId -Value $TaskId
        if ([string]::IsNullOrWhiteSpace($Type)) { throw 'record requires Type.' }
        if ($Type -in @('task.created', 'task.transitioned', 'task.reopened', 'artifact.observed', 'approval.granted', 'legacy.imported')) { throw "Use the dedicated command for $Type." }
        Add-LedgerEvent -EventTaskId $TaskId -EventType $Type -EventPayloadJson $PayloadJson -EventActor $Actor -EventExpectedSequence $ExpectedSequence
    }
    'observe' {
        Test-TaskId -Value $TaskId
        if ([string]::IsNullOrWhiteSpace($ArtifactPath)) { throw 'observe requires ArtifactPath.' }
        $task = Get-TaskFromState -State (New-CompiledState) -RequestedTaskId $TaskId
        if ($task.state -eq 'closed') { throw "Task '$TaskId' is closed. Reopen it before observing an artifact change." }
        if ($task.PSObject.Properties['legacy']) { throw 'Imported legacy tasks are read-only.' }
        $file = Resolve-WorkspacePath -InputPath $ArtifactPath
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Artifact does not exist: $ArtifactPath" }
        $payload = [ordered]@{ path = (Get-RelativeWorkspacePath -FullPath $file); sha256 = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() } | ConvertTo-Json -Compress
        Add-LedgerEvent -EventTaskId $TaskId -EventType 'artifact.observed' -EventPayloadJson $payload -EventActor $Actor -EventExpectedSequence $ExpectedSequence
    }
    'reopen' {
        Initialize-Store
        Invoke-TaskReopen
    }
    'approve' {
        Initialize-Store
        Invoke-Approval
    }
    'compile' {
        $views = Write-GeneratedViews -OnlyTaskId $TaskId
        [pscustomobject]@{ Compiled = $true; Tasks = $views.Tasks; Valid = ($views.State.errors.Count -eq 0); Errors = $views.State.errors }
    }
    'dashboard' {
        $views = Write-GeneratedViews -OnlyTaskId $null
        [pscustomobject]@{ Generated = $true; Path = (Join-Path (Get-GeneratedPath) 'dashboard.md'); Valid = ($views.State.errors.Count -eq 0); Errors = $views.State.errors }
    }
    'recover' {
        Invoke-Recovery
    }
    'snapshot' {
        New-ArchiveSnapshot
    }
    'inventory-legacy' {
        Initialize-Store
        $inventory = Write-LegacyInventory
        [pscustomobject]@{ Generated = $true; Records = $inventory.records.Count; Path = (Join-Path (Get-GeneratedPath) 'legacy-inventory.md') }
    }
    'import-legacy' {
        Initialize-Store
        Import-LegacyRecords
    }
    'verify' {
        Initialize-Store
        $state = New-CompiledState
        [pscustomobject]@{ Valid = ($state.errors.Count -eq 0); LedgerSequence = $state.ledger_sequence; Errors = $state.errors }
        if ($state.errors.Count -gt 0) { exit 1 }
    }
}
