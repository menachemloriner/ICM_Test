# 01_intake

## Task
Full teardown and rebuild of `startup-opportunity-discovery.md`, a 10-candidate startup
opportunity research report (located at
`C:\Users\menac\OneDrive\Desktop\ICM_Test\startup-opportunity-discovery\startup-opportunity-discovery.md`).

## Constraints
- Source file is READ-ONLY for this task. Never overwrite it.
- Output is a new file: `startup-opportunity-discovery-v2.md`, saved to
  `C:\Users\menac\OneDrive\Desktop\ICM_Test\startup-opportunity-discovery\`.
- "Destroy" = both reasoning/evidence rigor AND structure/clarity. Full teardown, not a
  light edit pass.

## Success criteria
The rebuild is done when:
1. Every claim in the critique has a specific location/quote from the source document
   backing the objection (no vague "this feels weak" complaints).
2. The rebuilt document fixes every substantiated issue from the critique — not just the
   easy ones.
3. The rebuild does not silently drop the document's actual discipline (kill rules,
   source A/B evidence tiers, the "verify + pilot ≠ validated" distinction) — those are
   good bones. The rebuild should sharpen them, not erase them.
4. Any claim, number, or citation carried into the rebuild is either verified against the
   original source material referenced in the doc, or explicitly flagged as unverified —
   never silently upgraded in confidence.
5. Max can read the rebuild and see clearly what changed and why (a changelog/summary of
   fixes, not just a diffed document with no explanation).

## Pipeline decided
Custom 5-stage: 01_intake → 02_critique → 03_rebuild → 04_review → 05_deliver.
No stages skipped.

## Status
Complete.
