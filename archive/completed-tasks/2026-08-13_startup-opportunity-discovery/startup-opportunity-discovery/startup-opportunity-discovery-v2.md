# Startup opportunity discovery — ten tests, with one explicit gate hold

Rebuilt 13 August 2026 from the original report and the stage 2 critique.

**Editing boundary:** The original report, `C:\Users\menac\OneDrive\Desktop\ICM_Test\startup-opportunity-discovery\startup-opportunity-discovery.md`, is preserved unchanged. This file is a separate rebuilt draft; all edits belong here, not in the original.

The original report contained two useful leads—accounts-payable exception handling and small-manufacturer inventory planning—but treated a brokered keyword screen as if it were demand validation. This rebuild narrows the claim and makes the gate state visible.

This document answers: **which buyer/workflow problems deserve an independent verification pass and a bounded paid concierge test?** It does not claim that ten markets are validated, that any keyword volume is accurate, or that software should be built.

## Decision rule

“Verify + pilot” means spend the next research and sales effort on a bounded service. It does not mean validated demand, product-market fit, or permission to build software.

A candidate is eligible for the **clear** Verify + pilot set only when all three gates are satisfied:

1. A first-pass US keyword screen is at least 100 monthly searches and has nonzero CPC.
2. A separate source shows a recurring workflow, cost, deadline, compliance exposure, or revenue risk for a specific buyer.
3. The job can first be sold as a bounded, paid service using the buyer’s existing files and tools.

The first-pass screen is a triage instrument. The seodata.dev site says it routes requests to multiple providers, caches results, and displays data through the Google Ads API ([provider description](https://www.seodata.dev/)). That makes it useful for a dated screen, not a primary measurement of a market. Before any candidate is called validated, collect a second observation date, raw responses, an independent demand source, and paid behavior.

The numeric kill rules are applied before ranking:

- below 100 US searches/month: kill;
- $0 CPC on a commercial query: kill unless a buyer is already paying for the concierge version; and
- a broad or mixed-intent query does not clear the screen by volume alone. It must be replaced or supplemented by a buyer-specific, narrow query.

## Gate summary

| Gate state | Count | Meaning |
|---|---:|---|
| **Clear Verify + pilot** | 8 | The listed screen clears the numeric gate and a source-B workflow receipt is present, subject to independent reproduction. |
| **Verify, source-B confirmation required** | 1 | The numeric screen is usable, but the strongest pain receipt is anecdotal or not sufficiently buyer-specific. |
| **Conditional / gate hold** | 1 | The listed query is a broad proxy and does not clear gate 1 until a narrower query is tested. |
| **Validated demand** | 0 | No candidate has independent demand, a second observation, raw responses, and paid behavior. |

The list stays at ten because the purpose of this stage is to preserve useful tests while making uncertainty impossible to miss. The two held rows must not be presented as having passed the first numeric screen.

## Ranked candidates

The ranking is a test-priority ranking, not a market-size ranking. It uses four criteria: (1) whether the numeric gate is clear, (2) how directly source B describes a costly workflow for the intended buyer, (3) how bounded the first paid service can be, and (4) how quickly a repeat cycle can be observed. “First wave” therefore means the shortest path from a credible receipt to a paid test; “narrow” means the workflow may be valuable but the buyer pool or access requirements are specialized; “exploratory” means the test is cheap enough to run but the evidence can still kill it quickly.

| Rank | Gate state | Opportunity and buyer | First-pass screen | Independent signal and limitation | Paid pilot and kill condition |
|---:|---|---|---|---|---|
| 1 | **Clear — first wave** | **AP exception desk** for bookkeeping firms handling small-business bills | “accounts payable automation”: 2,400/month, $133.23 CPC; page updated 12 Jun 2026 ([screen](https://www.seodata.dev/keyword/accounts-payable-automation)) | An accounts-payable coordinator job specification lists PO matching, supplier queries, reconciliation, and advanced Excel work ([job specification](https://www.rezoomo.com/contentFiles/jobs/88812/attachments/7674095666286983406_Accounts_Payable_Coordinator_Job_Description.pdf)). This is a workflow receipt, not proof that small bookkeeping firms have the same volume or will pay. | Sell a one-week invoice/PO exception cleanup for $250–$500, with a before/after error ledger. The planning band assumes roughly 3–6 hours of bounded delivery plus review at a $75–$100/hour target floor; it is not a market-price claim. Kill if ten firms will not take the call, five will not pay, or the work is not recurring or financially material. |
| 2 | **Clear — first wave** | **BOM and reorder pack** for small manufacturers with spreadsheet-based production planning | “inventory management”: 14,800/month, $54.99 CPC; page updated 2 Jun 2026 ([screen](https://www.seodata.dev/keyword/inventory-management)) | A supply-chain discussion describes building stock and production plans in a spreadsheet ([planning thread](https://www.reddit.com/r/supplychain/comments/1ryydzk/excel_based_mrp_template/)). This is one anecdotal observation, not prevalence or willingness-to-pay evidence; a second manufacturer-specific receipt is required. | Pick one subvertical and sell a paid BOM normalization plus reorder review for $400–$1,000. The band assumes about 5–10 hours of cleanup and review at a $75–$100/hour target floor. Kill if the input data cannot be cleaned in a fixed scope, five makers will not pay, or the result is a one-off spreadsheet with no repeat cycle. |
| 3 | **Clear — narrow** | **Provider credentialing renewal desk** for independent medical groups and behavioral-health practices | “CAQH software”: 260/month, $83.24 CPC; page updated 4 May 2026 ([screen](https://www.seodata.dev/keyword/caqh-software)) | CAQH describes a credentialing workflow built around provider data and primary-source verification ([CAQH brochure](https://www.caqh.org/hubfs/Credentialing%20Suite%20Brochure_2024.pdf)). Operator discussions mention payer portals, CAQH updates, expiration dates, and spreadsheet backlogs ([credentialing discussion](https://www.reddit.com/r/healthcare/comments/1rtihc6/were_our_credentialing_team_rarely_has_downtime/), [multi-state discussion](https://www.reddit.com/r/HealthInformatics/comments/1rneume/struggling_with_behavioral_health_credentialing/)). These discussions are anecdotal and require direct confirmation with the target practice. | Start with a human-run renewal and missing-document audit for five providers, priced per provider or payer packet. The fee should cover document intake, exception mapping, and a review pass; do not price regulated attestations as if the service can own them. Kill if the buyer will not grant source-document access, if the work requires regulated attestations the service cannot safely own, or if five practices will not pay for a bounded audit. |
| 4 | **Clear — narrow** | **Post-award grant reporting pack** for nonprofits with several active funders | “grant management programs”: 1,900/month, $47.83 CPC; page updated 20 May 2026 ([screen](https://www.seodata.dev/keyword/grant-management-programs)) | Smartsheet templates organize grant status, expenses, reporting deadlines, and compliance documentation ([template library](https://www.smartsheet.com/content/grant-tracking-templates)). Nonprofit discussions describe paper attendance, spreadsheet reformatting, separate grant tabs, and difficulty tying programs to expenses and reports ([reporting discussion](https://www.reddit.com/r/nonprofittech/comments/1rw9ezb/looking_for_feedback_attendance_tracking_grant/), [expense/reporting discussion](https://www.reddit.com/r/nonprofittech/comments/1r9job6/how_do_you_guys_actually_tie_grants_programs_expenses_reporting/)). The discussions are anecdotal; the reporting deadline must be verified with each prospect. | Sell one reporting-cycle closeout: reconcile source files, map evidence to the funder template, and deliver an audit-ready packet. The planning band assumes 4–8 hours for one bounded reporting cycle at a $75–$100/hour target floor. Kill if the buyer cannot name a report due within 60 days, if source data is too discretionary to standardize, or if five nonprofits will not pay. |
| 5 | **Verify — source-B confirmation required** | **Equipment maintenance evidence file** for small plants, warehouses, churches, and facilities teams | “equipment maintenance software”: 590/month, $144.51 CPC; page updated 1 Jun 2026 ([screen](https://www.seodata.dev/keyword/equipment-maintenance-software)) | A maintenance-log template makes the required fields explicit—asset, service history, parts, cost, technician, and next due date ([template](https://www.assetos.io/blog/equipment-maintenance-log-template)). The original operator discussion used for another row is not counted here as independent evidence. A fresh operator receipt is required before treating this as a clear Verify + pilot candidate. | Convert existing logs, attach photos/invoices, calculate next-due dates, and run a monthly exception report for $300–$750. The band assumes 3–7 hours of intake, cleanup, and review. Kill if the buyer has too few assets to feel the risk, if the log is already accurate and reviewed, or if five operators will not pay for the first audit. |
| 6 | **Conditional — gate hold** | **Construction change-order evidence pack** for specialty contractors | “construction management”: 27,100/month, $15.93 CPC; page updated 14 May 2026 ([screen](https://www.seodata.dev/keyword/construction-management)). This is a broad, mixed-intent proxy and **does not clear gate 1**. Test the narrower “construction contract software” query and a specialty-contractor variant before counting this as numerically qualified. | A public construction audit found change-order records decentralized, difficult to retrieve, and inconsistently documented ([audit report](https://inspectorsgeneral.org/wp-content/uploads/2026/02/Audit-of-Construction-Contract-Change-Orders-Report.pdf)). Procore frames unrecorded work as work that can go unpaid ([specialty-contractor analysis](https://www.procore.com/advantage/specialty-contractors-losing-work-revenue)). Those sources support the workflow hypothesis, not the demand screen or willingness to pay. | Review one active job’s RFIs, photos, time, materials, and approvals; produce a signed change-order packet and margin-recovery ledger. The planning band assumes 3–6 hours for one live job. Kill immediately if the narrower query is below 100/month or $0 CPC, if no contractor can show a live disputed or at-risk change, or if the customer will not pay for recovery work. |
| 7 | **Clear — exploratory** | **Used-vehicle reconditioning and aging desk** for independent auto dealers | “auto dealer inventory management software”: 880/month, $55 CPC; page updated 13 May 2026 ([screen](https://www.seodata.dev/keyword/auto-dealer-inventory-management-software)) | NADA’s dealer planning calendar calls out aging inventory, used-vehicle costs, reconditioning, and monthly reconciliation ([NADA planning calendar](https://www.nada.org/media/3054/download?inline=)). Cox Automotive describes sourcing and reconditioning-cost estimation as persistent dealer pain ([industry report](https://www.autoremarketing.com/ar/technology/cox-automotive-leans-into-ai-tools-to-improve-inventory-management/)). These are industry-level receipts; the dealer’s actual stage data and economics still need confirmation. | Run a 30-day VIN-level aging and reconditioning review: where each unit is stuck, cost to date, next owner, and expected frontline date. The band assumes 4–8 hours for one inventory export and review. Kill if the dealer already has clean stage data, if recovered gross cannot cover the fee, or if five rooftops will not share a live inventory export. |
| 8 | **Clear — exploratory** | **Contract renewal and notice-window audit** for small businesses with vendor, lease, and SaaS contracts | “renewal management”: 320/month, $4.07 CPC; page updated 7 Jul 2026; related “renewal management software” is 110/month at $75.34 ([screen](https://www.seodata.dev/keyword/renewal-management)) | Renewal templates include end dates, cancellation notice, annual value, owner, and auto-renewal flags ([Renewal Pilot template](https://renewalpilot.io/resources/renewal-tracker-template)). Small-business discussions describe missed windows, spreadsheet/calendar workarounds, and surprise auto-renewals ([discussion 1](https://www.reddit.com/r/smallbusiness/comments/1tcnf1p/contracts_tracking_for_sme/), [discussion 2](https://www.reddit.com/r/FPandA/comments/1q6qjy3/is_missing_saas_renewal_actually_a_problem/)). The discussions are anecdotal; one financially meaningful deadline must be found in each pilot. | Ingest a contract folder, extract notice deadlines and commercial obligations, then deliver a 90-day action list for a fixed fee. The band assumes 2–5 hours for a defined contract set at a $75–$100/hour target floor. Kill if fewer than 20 contracts are in scope, no renewal decision is financially meaningful, or the buyer will not pay to avoid one concrete deadline. |
| 9 | **Clear — exploratory** | **Childcare attendance and subsidy reconciliation** for independent centers and home-daycare operators | “attendance management software”: 210/month, $31.03 CPC; page updated 10 May 2026 ([screen](https://www.seodata.dev/keyword/attendance-management-software)) | Playground documents reconciliation of attendance, subsidy payments, and audit trails across state portals ([subsidy workflow](https://www.tryplayground.com/solutions/subsidy)). KinderSystems describes daily attendance, changing policies, and weekly payment reconciliation ([KinderTrack](https://kindersystems.com/products/kindertrack/)). A current operator discussion describes attendance, billing, parent updates, and compliance paperwork split across tools ([operator discussion](https://www.reddit.com/r/Enginehire/comments/1vdqgtl/why_day_care_center_management_software_is/)). The operator discussion is anecdotal and state-specific rules may make the service non-portable. | Reconcile one month of sign-in/out records against subsidy submissions and parent billing, then deliver the exception list. The band assumes 3–6 hours for one month and one state workflow. Kill if the center has no subsidy or attendance-based billing exposure, if state rules make the service unrepeatable, or if five centers will not pay. |
| 10 | **Clear — exploratory** | **HVAC quote-to-cash closeout** for solo and small-crew service companies | “field service management”: 1,600/month, $84.66 CPC; page updated 11 May 2026; related “field service management software” is 6,600/month at $141.22 ([screen](https://www.seodata.dev/keyword/field-service-management)) | A trade-software review describes paper tickets, missing job details, delayed invoices, service history, and maintenance-plan follow-up as the point where small HVAC operations outgrow manual systems ([trade review](https://www.techradar.com/pro/how-to-pick-hvac-field-service-management-software)). HVAC paperwork templates show the quote, proposal, service-report, invoice, and follow-up chain ([paperwork system](https://hvactemplateshop.com/)). These are workflow receipts, not evidence that the target shops will buy this service. | Take ten recently completed jobs and rebuild the path from quote to signed report to invoice; charge $250–$600 for the closeout sprint. The band assumes 3–6 hours for ten jobs. Kill if the owner already closes jobs same day, recovered billing does not cover the fee, or five shops will not pay for a second cycle. |

## Why the list is not ten copies of one idea

The candidates share a delivery pattern—import messy files, find exceptions, and return a clean action list—but they are not interchangeable markets. The buyer, source documents, economic consequence, sales channel, and repeat interval differ.

| Workflow shape | Candidates | Distinguishing pilot output |
|---|---|---|
| Reconcile money or entitlement | AP exceptions; credentialing; childcare subsidy | A corrected financial or eligibility record that can be compared with a source document or payer response. |
| Plan scarce physical capacity | Manufacturing BOM/reorder; auto-dealer reconditioning; equipment maintenance | A prioritized physical-world queue with a cost of delay. |
| Prove and recover value | Construction change orders; grant reporting | Evidence assembled against an external approval, payment, or compliance requirement. |
| Control time-bound obligations | Contract renewals | A notice-window and owner ledger tied to contracts, not a generic task board. |
| Close field work into cash | HVAC quote-to-cash | A completed, billable job packet and an exception list for missing revenue. |

## What the evidence proves—and what it does not

The evidence stack is deliberately asymmetric:

- The seodata.dev page is **source A: a dated demand screen**. It is brokered, cached, and sometimes broad or mixed-intent.
- The job specification, operator discussion, public audit, association document, template, or workflow page is **source B: a workflow receipt**. It is not a willingness-to-pay survey, prevalence estimate, or substitute for a buyer interview.
- A second demand observation is missing for every row. Google Trends can help establish relative movement, but Google describes its data as normalized and aggregated rather than a monthly-volume count ([Google Trends documentation](https://developers.google.com/search/docs/monitor-debug/trends-start)).
- The CPC figures are sanity-check inputs, not prices or proof of commercial intent. The unusually high values ($133.23 and $144.51) must be reproduced through a second observation and provider lineage before they influence prioritization.

The correct state is therefore:

| State | Meaning | Current count |
|---|---|---:|
| **Clear Verify + pilot** | Eligible for independent demand checking and a paid concierge test | 8 |
| **Verify, source-B confirmation required** | Worth a cheap test, but the workflow receipt is too weak or indirect to call clear | 1 |
| **Conditional / gate hold** | Worth testing only after the narrower query is run | 1 |
| **Validated demand** | Independent demand source, second observation date, raw responses, and paid behavior | 0 |
| **Build** | Repeatable paid workflow with acceptable acquisition, delivery, and renewal economics | 0 |

## Citation hygiene correction

The earlier Asana weakness sweep cited the wrong G2 page and reported mention counts that did not match the live pros-and-cons page. The corrected receipt is [G2 Asana pros and cons](https://www.g2.com/products/asana/reviews?qs=pros-and-cons), which was checked 12 August 2026; the observed counts were 555 for “learning curve” and 562 for “missing features.” The previously cited `/competitors/alternatives` page is not used here because it does not contain those quoted labels and values.

The procedural rule is broader than Asana: a citation is not evidence until the cited page contains the quoted label and value. In the next run, store the exact quote, page URL, observation date, and raw response for each material claim.

## Economics: the paid pilot is the measurement instrument

“100 customers × $129/month = $154.8k ARR” is arithmetic, not validation. It says nothing about acquisition cost, setup labor, support, churn, or renewal after the founder stops hand-holding.

The price bands in the table are planning bands, not observed market prices. They are derived from a target delivery floor of roughly $75–$100 per hour multiplied by the stated bounded effort, with room for a review pass. Before quoting a prospect, replace the planning band with an actual scope: files, rows/jobs/providers/contracts, turnaround, included review, and exclusions. If the scope cannot be fixed, do not sell it as a fixed-fee pilot.

Each pilot must record:

- acquisition source, sales time, and out-of-pocket acquisition cost;
- hours to ingest and clean the buyer’s files;
- hours of human delivery and support;
- the dollar, deadline, or compliance consequence found;
- price paid and whether the buyer asks for the next cycle; and
- the reason for non-renewal or refusal.

Use `CAC payback = acquisition cost / monthly gross profit per account`. Set a 12-month payback ceiling before selling. Do not use a churn assumption to make the model look complete; measure renewal after the second relevant cycle.

## Next-test protocol

Run the ten rows in three waves, but do not let the wave label hide the gate state.

1. **First wave:** AP exceptions and manufacturing BOM/reorder. Recheck each keyword on a second date, obtain a buyer-specific source-B confirmation, and approach ten target buyers per row. Do not build before five paid pilots per row.
2. **Narrow wave:** provider credentialing, grant reporting, and equipment maintenance. For maintenance, obtain a fresh operator receipt before promoting it to the clear set. Sell around a live deadline, renewal, or audit rather than a generic demo.
3. **Exploratory wave:** auto-dealer reconditioning, contract renewals, childcare subsidy reconciliation, and HVAC closeout. Construction stays on a gate hold until its narrower query is measured. Use the pilot to test whether the economic consequence supports a repeatable channel.

For every row, record the following in one evidence ledger:

- exact query, country, provider lineage, timestamp, page update date, and raw response;
- second observation and variance, not a qualitative claim that demand is “stable”;
- exact quote and label from every review, audit, template, job source, or workflow page used;
- gate result, including the numeric result in the same row as the candidate;
- buyer segment, deduplication shape, and concrete economic consequence;
- pilot scope, planning price, actual price, delivery hours, acquisition source, and renewal result; and
- a single kill / continue / promote decision with the evidence that supports it.

The universal kill rules are: the relevant narrow query is below 100/month or reaches $0 CPC; source B cannot be independently reproduced; fewer than five target buyers pay; the consequence is not financially or operationally material; or the work does not recur.
