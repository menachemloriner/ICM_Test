# ICM Next Phase 1 operating guide

Phase 1 is an opt-in, local-only pilot. It adds a model-neutral event ledger
alongside the existing v2 filesystem workflow; it does not alter v1/v2 task files
or rewrite archived records.

## Operating defaults

- One trusted Windows machine; no external storage or orchestration service.
- The ledger is authoritative. Dashboard, state, context, recovery reports, and
  snapshots are generated views.
- Git checkpoints are recommended at meaningful milestones but are not required.
- Changing a closed artifact requires explicit reopen, fresh observation, and
  fresh acceptance checks before it can close again.
- `external_communication`, `production_deployment`, `financial`, `legal`, and
  `destructive_change` require named human approval before close.

## Initialize the pilot

Run this once from a workspace root:

```powershell
./tools/icm-next.ps1 init
```

It creates `.icm-next/` with `config.json`, `SCHEMA_POLICY.md`, the ledger, and
generated/archives directories. It does not modify `STATUS.md`, `tasks/`, or
`archive/`.

## Create and progress a normal task

```powershell
./tools/icm-next.ps1 new-task -TaskId research -Title "Research" -Objective "Produce a sourced report" -Criteria "report exists"
./tools/icm-next.ps1 transition -TaskId research -ExpectedFrom queued -To active
./tools/icm-next.ps1 record -TaskId research -Type artifact.declared -PayloadJson '{"path":"tasks/research/deliverables/report.md","validation":"reviewed report"}'
./tools/icm-next.ps1 observe -TaskId research -ArtifactPath tasks/research/deliverables/report.md
./tools/icm-next.ps1 record -TaskId research -Type check.recorded -PayloadJson '{"criterion":"report exists","result":"pass","evidence":"tasks/research/deliverables/report.md"}'
./tools/icm-next.ps1 transition -TaskId research -ExpectedFrom active -To waiting_review
./tools/icm-next.ps1 transition -TaskId research -ExpectedFrom waiting_review -To ready_to_close
./tools/icm-next.ps1 transition -TaskId research -ExpectedFrom ready_to_close -To closed
./tools/icm-next.ps1 snapshot -TaskId research
```

`transition` validates state changes. In particular, `closed` is rejected unless
all declared artifacts have current observations and all acceptance checks pass.

## Use an approval gate

Create sensitive work with one or more approval kinds:

```powershell
./tools/icm-next.ps1 new-task -TaskId announcement -Title "Customer announcement" -Objective "Prepare outbound announcement" -Criteria "message approved" -ApprovalKind external_communication
```

Before closure, a human records approval:

```powershell
./tools/icm-next.ps1 approve -TaskId announcement -ApprovalKind external_communication -Approver "Max Loriner" -Note "Reviewed for release"
```

## Reopen after a delivered artifact changes

Do not re-observe a closed artifact directly. The tool rejects it. Reopen first,
then observe and re-check the changed work:

```powershell
./tools/icm-next.ps1 reopen -TaskId research -Reason "Source correction changed report"
./tools/icm-next.ps1 observe -TaskId research -ArtifactPath tasks/research/deliverables/report.md
```

Repeat review checks and normal transitions to close. Approval gates also require
fresh approval after a reopen.

## Resume and inspect work

```powershell
./tools/icm-next.ps1 compile -TaskId research
./tools/icm-next.ps1 dashboard
./tools/icm-next.ps1 verify
./tools/icm-next.ps1 recover
```

`recover` recreates generated views and writes `.icm-next/generated/RECOVERY.md`.
It never edits legacy archive files or ledger history.

## Inventory and import legacy archives

```powershell
./tools/icm-next.ps1 inventory-legacy
./tools/icm-next.ps1 import-legacy
```

Inventory writes a human-readable and JSON report under `.icm-next/generated/`.
It labels absent or inconsistent evidence `legacy-claim-unverified`; that is not a
retroactive failure judgment. Import records archive path and directory fingerprint
as a read-only `legacy.imported` record. It does not copy, move, edit, or silently
reclassify historical work.

## Pilot rules

1. Use `transition`, `observe`, `reopen`, and `approve` rather than writing their
   corresponding event types through `record`.
2. Treat `.icm-next/generated/` as disposable output. Keep the ledger and task
   artifacts under normal workspace backup/Git policy.
3. Do not enable external storage, workflow orchestration, semantic retrieval, or
   multi-machine writes during Phase 1.
4. Review the dashboard and run `verify` before each snapshot and Git checkpoint.
5. Keep the current v2 workflow available during the pilot; do not bulk-convert
   historical records.
