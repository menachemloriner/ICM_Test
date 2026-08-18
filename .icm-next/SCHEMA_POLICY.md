# ICM Next schema policy

This Phase 1 store is single-machine and local-only. ledger.jsonl is the task
authority; generated files may be recreated. Schema changes require a new schema
version, a migration note, and compatibility tests. Git checkpoints are optional.
Artifact changes after closure require an explicit reopen and fresh review.