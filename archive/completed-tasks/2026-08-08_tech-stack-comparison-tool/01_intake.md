# Stage 01 — Intake

## Task
**What we're building:**
An interactive HTML widget that compares popular tech stacks (React+Node, Python+FastAPI, Go+Gin, Rust+Actix, TypeScript+Bun) side-by-side. Users can see how each stack stacks up on learning curve, performance, community, job market, cost, and deployment ease. Goal: help people deciding what to learn next.

**What good looks like:**
- Displays 5 tech stacks with 6-7 comparison dimensions
- Interactive: can filter, sort, or toggle views (not just static table)
- Visual: uses progress bars, colors, icons — not boring text
- Shareable: single HTML file, no build step, works in browser
- Loads in <2 seconds, no console errors
- Self-explanatory to someone with zero context

**What to avoid:**
- Don't make it a boring comparison table
- Don't require external APIs or backend
- Don't overcomplicate the UX with too many options
- Don't include stacks with no real job market (toy languages)

**Constraints:**
- Single artifact (React or vanilla JS)
- Must work standalone
- Max prefers concise, dense information
- Deadline: Friday (3-4 sessions over ~1 week)

**Success criteria:**
✓ All 5 stacks included with accurate data
✓ 6-7 dimensions scored 1-5
✓ At least one interactive feature (filter/sort)
✓ Visual design is clean and engaging
✓ Artifact loads and runs with no errors
