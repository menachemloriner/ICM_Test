# 02_critique

## Purpose
Full teardown of `startup-opportunity-discovery.md`. Find every place the reasoning,
evidence, or structure is weaker than the document's own stated standards. This stage
produces the diagnosis only — no rewriting yet.

## Inputs
- `C:\Users\menac\OneDrive\Desktop\ICM_Test\startup-opportunity-discovery\startup-opportunity-discovery.md` (read fresh from disk, don't rely on any earlier
  in-chat summary of it)
- The document's own decision rule and evidence tiers (source A / source B, the three
  numeric kill gates) — the audit standard is the document's own stated rules, applied
  consistently, not an external rubric.

## Process
For each of the following, cite the specific row, quote, or section:
1. **Evidence rigor** — Does every "Verify + pilot" row actually clear the document's own
   three gates (100+ searches/month, nonzero CPC, buyer-specific pain receipt, sellable as
   bounded paid service)? Flag any row where the stated evidence doesn't actually support
   the gate it's claimed to clear.
2. **Citation quality** — Spot-check citation-to-claim mapping. Does the linked source
   actually say what's attributed to it, or is it adjacent/inferred? (The doc's own "Asana
   citation failure" section shows this exact failure mode happened before — check whether
   it happened again elsewhere.)
3. **Internal consistency** — Does the doc contradict its own rules anywhere (e.g. calling
   something "first wave" without the evidence that first-wave status requires; treating a
   broad/mixed-intent query as passing when the doc says that shouldn't happen)?
4. **Structural/clarity issues** — Redundancy, buried lede, sections that repeat the same
   point, places a reader has to hold too much in their head at once, unclear ranking logic.
5. **Missing self-awareness** — Places where the document should flag its own uncertainty
   per its stated standard, but doesn't.

## Outputs
A critique document (in this file, appended below) listing every substantiated issue,
each with: location in source doc, the specific problem, and severity (fatal to the row's
ranking / weakens confidence / cosmetic). No fixes yet — that's 03_rebuild.

## Status
Complete — see findings below.

---

## Critique findings

**Scope note:** This pass audits the document's own internal reasoning, evidence-tier
logic, and structure — checking whether it plays by its own stated rules. It does not
re-run independent demand verification for all 10 candidates; the document itself
correctly identifies that as future work. Re-litigating primary research here would just
produce report v3's problem inside report v2.

### FATAL — breaks the document's own stated rule

**1. "All ten pass the first numeric screen" is false by the document's own rule 3.**
Row 6 uses "construction management" (27,100/mo), which the row's own text admits is
"a broad, mixed-intent proxy, so it does not pass on volume alone" — and its kill
condition says to test whether the screen fails on a narrower query. That narrower query
hasn't been run. So gate 1 hasn't actually been cleared for Row 6, yet the summary line
still counts it among all ten that pass. This is the exact overclaiming pattern the
document criticizes the "previous report" for.

### WEAKENS CONFIDENCE

**2. Job-description-as-demand-signal inference (Row 1).** The AP coordinator posting
shows the role exists in-house; it doesn't show appetite to outsource it. Should be named
as an inference, not given the same weight as a direct pain complaint.

**3. A citation flagged as proving nothing is still listed as evidence (Row 1).** The G2
QuickBooks citation is annotated "no unquoted review count is used" — i.e. the doc admits
it doesn't support a specific claim, yet keeps it in the evidence column.

**4. Single-anecdote sourcing, no sample-size caveat.** Rows 2, 5, 7, 8, 9 lean on one or
two Reddit threads as "source B," given the same "independent signal" framing as stronger
multi-source rows, with no distinction drawn.

**5. Same evidence reused across two "distinct" candidates.** The r/manufacturing
maintenance thread backs both Row 2 (BOM/reorder) and Row 5 (equipment maintenance),
undercutting the "not one idea repeated ten times" argument in practice.

**6. Unusually high CPC figures (e.g. $133.23, $144.51) aren't sanity-checked**, despite
the doc itself flagging seodata.dev as brokered/cached/triage-only. (Not independently
re-verified in this pass — that's flagged as future work in the doc itself.)

### CLARITY / STRUCTURE

**7. Ranking logic between tiers is unstated** — the 1-10 order implies finer precision
than the three-tier (first wave/narrow/exploratory) system actually supports.

**8. "The Asana citation failure" section is a discontinuity** — a meta-note about a prior
draft's citation error, not a startup candidate, dropped mid-document with no other row
given this kind of individual audit.

**9. "The next ten tests" and "Evidence ledger for the next run" overlap heavily** — both
are effectively the same to-do list at different granularity, with no cross-reference.

**10. Pilot pricing bands have no stated basis** — presented with the same confident
specificity as sourced search-volume figures but are unsourced estimates.

## What this critique deliberately does NOT flag
The core discipline — three-gate kill rule, source A/B distinction, "verify+pilot not equal
validated demand," the state-count table — is sound and self-aware. Keep and sharpen it.
