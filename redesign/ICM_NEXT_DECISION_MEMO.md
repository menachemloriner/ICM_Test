# ICM_Test: 10x redesign decision memo

Assessment date: 2026-08-18.

## Blunt conclusion

Replace the runtime control plane with an event-backed, graph-aware core. Keep
Markdown and Git as useful human artifacts, but stop treating handwritten status
files and a singleton stage pointer as authoritative state.

The existing system has the right intentions: explicit task contracts, scoped
context, substantive review, and durable archives. The implementation turns those
intentions into a manual filing system. `STATUS.md`, `pipeline.md`, `LOG.md`,
copied stage contracts, root status, and archive records are independently edited
views of the same facts. They can be structurally valid while task history,
deliverables, and recovery state disagree.

Do not add another template or mandatory stage. Build a small durable core that
records facts once, derives status and context automatically, and treats evidence
as a first-class object. The first production investment should be a local event
ledger, compiler, and evidence verifier—not a new workflow document or vector
database.

## Scope and evidence

I inspected the live root controls, both bundled workflow versions, every helper,
templates, completed-task records, and the actual referenced deliverables. I also
ran the baseline system in an isolated temporary copy, so no historical record was
changed by the tests.

The live workspace passes `tools/validate-workspace.ps1`. That is useful but not
system health: when no task is active, the validator does not inspect completed
tasks, declared artifacts, workflow hashes, archive records, or recovery
readiness.

### Strengths to retain

| Keep | Reason |
|---|---|
| Declared objective, constraints, deliverables, and checks | Converts a request into inspectable work. |
| Structural versus substantive review | File presence is not proof of quality. |
| Direct, scoped references | A guardrail against indiscriminate context loading. |
| Task-local workflow snapshot | Historic work needs its original operating semantics. |
| Readable archive exports | A human should inspect durable work without a special service. |
| Human decision checkpoint | Material decisions should create an explicit gate. |

### Forensic findings

| Live evidence | Finding | Risk |
|---|---|---|
| `tasks/README.md` says v1; root/new-task use v2. | Instructions and implementation drifted. | A worker can start from the wrong workflow. |
| `tools/status.ps1` is empty. | The stated control surface is missing. | State must be reconstructed by hand. |
| `new-task.ps1` allows another task while one is active. | It overwrites the root pointer. | The former task becomes invisible. |
| `archive-task.ps1` does not require its task to be active. | It can archive an inactive task. | A newer task can be stranded. |
| Archive expects a completed delivery exit before it performs the defining move. | Closeout is circular and handwritten. | Completion can be claimed before it occurs. |
| Manifest hashes are written but validator only checks workflow name. | Provenance is dead metadata. | Source drift goes undetected. |
| Tech-stack review says final HTML exists; the file is absent. | Archive claim outlived deliverable. | Archive completeness is a false positive. |
| Local-model report exists, but its manifest is absent and stage records disagree. | Archive is internally inconsistent. | Handoff/audit requires reconstruction. |

The two archive findings were verified against real files, not inferred from
`INDEX.md`, `ROOT_LOG.md`, or a review claim.

### Baseline scenario tests

`tests/test-current-system.ps1` runs isolated copies of the current system. It
passed nine assertions, including these observed outcomes:

| Scenario | Observed result | Verdict |
|---|---|---|
| New task creation | A first task is created successfully. | Pass |
| Competing tasks | A second task silently replaces `active_task`. | Fail |
| Inactive-task archive | The helper archives it, clears root state, and leaves a newer task unpointed. | Fail |
| Missing deliverable | The helper rejects an absent declared local file. | Pass, structural only |
| Skipped review | Free-text reason/self-check/reopen condition is accepted. | Weak evidence |
| Stale workflow sources | Post-creation workflow mutation still validates. | Fail |
| Interrupted pointer | Missing active directory is detected. | Partial pass: no repair/replay |
| Multi-session resume | Workers reconcile several manual files; historical records can disagree. | Fail |
| Reopen after archive | No lifecycle or restore command exists. | Fail |

## Assumptions to challenge

| Current assumption | Decision |
|---|---|
| Exactly one active task controls context. | **Delete.** Context belongs to a task/role; independent tasks may coexist. |
| A linear stage is primary state. | **Modify.** Use a dependency graph and optional gates; retain a simple default policy. |
| People and agents manually update status/log/pipeline. | **Delete as authority.** Generate them from typed events. |
| Stage contract is the only context boundary. | **Modify.** Keep scopes, but compile context from graph/evidence state. |
| Archive move means complete. | **Delete.** Completion is verified state; archive is an export. |
| Workflow copies preserve meaning. | **Keep and strengthen.** Record a contract version and actually validate it. |
| Chat/session is the unit of work. | **Delete.** Chats/models/frameworks are ephemeral producers; task history is durable. |

## Alternatives considered

Scores are relative to this workspace. “User effort” means ongoing effort.

| Option | User effort | Context efficiency | Reliability/recovery | Auditability | Build difficulty | Migration risk | Scale |
|---|---|---|---|---|---|---|---|
| A. Harden current v2 files | Medium | Medium | Medium | Medium | Low | Low | Low |
| B. Local event ledger + generated views + graph | Low | High | High | High | Medium | Medium | High |
| C. Central graph/event service + orchestrator | Low | High | Very high | Very high | High | High | Very high |
| D. Agent-framework-native state | Medium | Medium | Medium | Medium | Medium | Medium | Medium |

### A. Harden v2

Add ownership checks, locks, source-hash validation, recovery, and artifact
verification. This is a good short-term safety patch, but it retains duplicated
manual state and a singleton pointer. It is not a 10x redesign.

### B. Local event ledger + generated views + graph — selected

Use a small append-only, schema-validated ledger as authority. Generate dashboard,
task state, context packs, handoffs, and archive manifests from it. A task declares
dependencies, artifacts, and acceptance checks. Independent tasks can progress;
unmet dependencies block a task as data rather than as a document convention.

This has the largest reliability gain without a cloud service, specific LLM, or
framework rewrite. It also creates a clean upgrade path to a central service.

### C. Central graph/event service + orchestration

Move the same event/graph model to a shared database. Add durable orchestration
only for long-running external actions, scheduled retries, multiple workers, or
an operational SLA. This is a team-scale destination, not a local prerequisite.

### D. Agent-framework-native state

Frameworks can accelerate one application, but letting one own task truth locks
ICM to that runtime. A framework should emit ICM events, never be the only durable
task record.

## Target architecture: ICM Next

```text
human / CLI / any model / any agent framework
                  |
                  v
       schema-checked command gateway
                  |
                  v
        append-only task event ledger  <--- artifact observations + checks
                  |
          +-------+-------+
          |               |
          v               v
  state/graph compiler   evidence verifier
          |               |
          +-------+-------+
                  v
      generated context packs, dashboards,
      handoffs, archive snapshots, adapters
```

### Authority boundaries

1. **Durable authority:** task contract, events, artifact observations, check
   results, decisions, dependency links, and external-run references.
2. **Generated views:** current state, task board, context pack, archive manifest,
   and status Markdown. They may be deleted and regenerated.
3. **Human narrative:** notes/explanations linked from events; they do not silently
   override state.
4. **Ephemeral context:** chats, scratchpads, prompts, and temporary traces.
   Persist only the summary/evidence required to reproduce a decision.

### Small initial event model

- `task.created` — title, objective, acceptance criteria, dependencies.
- `task.transitioned` — state change with expected prior state.
- `context.linked` — URI/path, purpose, and permitted scope.
- `artifact.declared` / `artifact.observed` — expected artifact and observed hash.
- `check.recorded` — criterion, pass/fail, and evidence link.
- `decision.recorded` / `handoff.recorded` — decisions and successor instructions.

Each event carries schema version, event ID, timestamp, actor, task ID, sequence,
payload, prior hash, and hash. The hash chain detects ordinary editing/corruption;
it is not a substitute for authentication, signatures, or a tamper-proof audit
service.

### Graph, lifecycle, and compiled context

The default lifecycle is small:

`queued -> active -> waiting_review -> ready_to_close -> closed`

`blocked` and `cancelled` are first-class alternatives. A project policy may
compile intake/execute/review/deliver into these states, but no global stage order
is required. Reopen is a new transition with reason/evidence requirements; it
does not edit prior history into a new story.

Agents request a task and role, not “all workspace files.” The compiler emits the
objective, state, dependency gates, scoped sources, artifact freshness, acceptance
checks, policies, and concise handoff. The pack includes ledger sequence/head hash.
A writer declares the sequence it read, so a stale writer gets a conflict rather
than silently overwriting newer state.

## Model-agnostic integration strategy

No external product is mandatory. The core protocol stays portable; adapters are
added only when they solve a measured need.

| Need | Default | Optional accelerator | Explicit non-goal |
|---|---|---|---|
| Local durable state | JSONL ledger + Git checkpoint | SQLite/Postgres projection | Central platform first |
| Long-running retries | Core run-request event | Temporal adapter | Make Temporal task authority |
| Scheduled/data-heavy jobs | Core run-request event | Prefect adapter | Force every human task into a scheduler |
| Agent graphs/human interrupts | Context/event adapter | LangGraph adapter | Framework-only task history |
| OpenAI handoffs/traces | Context/event adapter | OpenAI Agents SDK adapter | Couple core state to an OpenAI run |
| Knowledge retrieval | Curated links/full-text search | Vector/graph retrieval with provenance | Embed whole archive by default |
| Collaborative audit | Git plus artifact hashes | Signed commits/external audit log | Claim JSONL is adversary-proof |

Temporal documents durable execution across failures, Prefect supports observable
flow/task runs, LangGraph offers durable agent orchestration and human-in-the-loop
controls, and the OpenAI Agents SDK offers handoffs, guardrails, and tracing.
They are useful adapters, not ICM task authority. See [Temporal](https://docs.temporal.io/),
[Prefect](https://docs.prefect.io/latest/tutorial/flows),
[LangGraph](https://langchain-ai.github.io/langgraph/index.html), and the
[OpenAI Agents SDK](https://openai.github.io/openai-agents-python/).

## Implemented vertical slice

`tools/icm-next.ps1` implements the selected core without altering v2 task files
or historical archives. It provides:

- append-only JSONL events with a short writer lock;
- sequence and expected-sequence conflict detection;
- SHA-256 event-chain verification;
- multiple task records and dependency gates;
- generated state plus compact task context;
- artifact observation with current file hash;
- closed-task checks requiring observed artifacts and passing criteria.
- named human approval gates for sensitive work;
- explicit reopen plus fresh review after changed delivered artifacts;
- generated dashboard, recovery report, and non-destructive snapshots;
- legacy inventory/import with preserved source fingerprints.

Example:

```powershell
./tools/icm-next.ps1 init
./tools/icm-next.ps1 new-task -TaskId research -Title "Research" -Objective "Produce a sourced report" -Criteria "report exists"
./tools/icm-next.ps1 compile -TaskId research
./tools/icm-next.ps1 verify
```

The prototype deliberately does not include authentication, database projection,
multi-machine locking, semantic retrieval, signed events, a GUI, or external
workflow adapters. The authority/context/evidence path must prove itself first.

### Prototype evidence

`tests/test-icm-next.ps1` passed 24 assertions on 2026-08-18.

| Risk | Result |
|---|---|
| Competing tasks | Two tasks coexist with no global active pointer. |
| Dependency conflict | A dependent task is invalid while upstream remains open. |
| Missing delivery evidence | A closed task without observed artifact is invalid. |
| Stale artifact | Editing a reviewed artifact creates a hash mismatch. |
| Stale writer | An old sequence is rejected. |
| Context loss | Deleted generated context recompiles from ledger. |
| Ledger edit | Ordinary line-content tampering fails chain verification. |
| Sensitive close | Named human approval is required for external communication. |
| Changed delivery | Reopen and fresh evidence are required before re-close. |
| Legacy migration | Inventory/import fingerprints archives without rewriting their bytes. |

## Before/after evaluation matrix

| Dimension | Current ICM | ICM Next | Measurable proof |
|---|---|---|---|
| State maintenance | Several Markdown updates. | One typed fact; views compile. | Count manual edits in pilot tasks. |
| Context | Stage lists, no freshness proof. | Scoped compiler output with ledger head. | Fixture excludes unrelated archive files. |
| Parallel work | Singleton pointer can overwrite. | Independent tasks plus graph. | Concurrent-create test. |
| Recovery | Some detection, no replay. | Regenerate views from ledger. | Delete/recompile test. |
| Delivery integrity | Presence plus prose evidence. | Hash observation plus criterion evidence. | Missing/mutated artifact tests. |
| Audit | Narrative records can conflict. | Ordered history plus evidence links. | Verifier passes. |
| Model portability | Protocol claims portability. | Provider-neutral CLI/schema adapter. | Non-chat CLI creates, compiles, verifies. |
| Scale | File scans and root pointer. | Local now; database adapter later. | 100-task/10k-event load test. |

## Migration path

### 0. Preserve and inventory

Freeze current archives as legacy evidence. Do not rewrite their status, workflow
version, prose, dates, or claims to make them look consistent. Inventory actual
artifact paths, missing paths, workflow record present/missing, and integrity
status. Label discrepancies `legacy-claim-unverified`; do not infer failure or
success where history does not prove either.

### 1. Introduce the core beside v2

Add the CLI, schemas, compiler, verifier, dashboard, and legacy importer. New
low-risk tasks run in dual-read mode: v2 materials remain readable, but the ledger
is authoritative for the pilot task. Import history as `legacy.imported` events
with original paths/timestamps and `evidence_status: unknown`; never invent an
observed hash or passed review.

### 2. Prove operational fit

Run at least ten real tasks, including two parallel tasks and one interrupted task.
Meet every acceptance test below. Add a `verify-legacy` report that creates a
human review queue rather than hiding missing evidence.

### 3. Cut over generated state

Replace handwritten root/task `STATUS.md` authority with generated views. Retire
the one-active-task invariant but retain optional focus views. Replace move-only
archiving with a sealed snapshot carrying ledger head, contract version, artifact
hashes, export path, and known limitations. Keep v1/v2 directories read-only as
legacy formats.

### 4. Add adapters only after the core holds up

Add Git, semantic retrieval, orchestration, framework, and team-service adapters
one at a time. Each emits the same core events and can be disabled without
erasing task history.

## Acceptance tests before cutover

| Test | Pass condition |
|---|---|
| Parallel creation | 20 concurrent creates yield 20 IDs, no missing events, no pointer overwrite. |
| Optimistic conflict | An old sequence is rejected with no partial event. |
| Interrupted write | Before/after append interruption never yields valid-looking partial state. |
| Resume | Delete all views; recompile same authority fields and head hash. |
| Artifact freshness | Modify closed artifact; verification fails until policy-required reopen/review/observation. |
| Missing delivery | Close is rejected without observed artifact and passed criterion. |
| Context boundary | Pack contains only scoped sources and logged retrieval results. |
| Legacy integrity | Import preserves source bytes and flags missing evidence. |
| Human gate | `approval_required` task cannot pass without linked human approval. |
| Performance | At 100 tasks/10k events, single-task compile meets a measured target (propose <2 seconds after baseline). |

## Decision memo

**Keep:** explicit contracts, scoped sources, substantive review, task-local
workflow semantics, readable archives, and human approval for material decisions.

**Remove as authority:** root `active_task`, manual current status, manual stage
advancement, archive-as-completion, and unvalidated hash metadata.

**Build first:** turn the event-core prototype into a supported CLI with atomic
append/recovery behavior, schema tests, generated views, archive snapshot, and
legacy inventory report.

**Do not build now:** another fixed stage taxonomy, mandatory vector database,
complex UI, provider-specific core, unproven automatic semantic retrieval, or a
bulk rewrite of history.

**Single highest-leverage change:** make an append-only event ledger the sole
authority and generate state/context/evidence views from it. That eliminates
manual status drift while unlocking parallel work, recovery, reliable handoffs,
and optional orchestration.

## Human decisions still needed

1. Is first production one trusted Windows machine, or multiple collaborators?
2. Which evidence needs privacy/redaction before durable or external storage?
3. Which task types require an explicit human approval gate?
4. When a delivered artifact changes, should policy reopen, require acceptance,
   or create a new task version?
5. Is Git required everywhere, and should ledger heads be committed/signed?
6. Which external actions actually need retries/schedules now?
7. Who owns event/schema compatibility policy?
