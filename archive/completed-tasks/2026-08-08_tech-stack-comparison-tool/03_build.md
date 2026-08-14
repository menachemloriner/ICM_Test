# Stage 03 — Build

## Outputs / exit criteria met
- Single HTML artifact with:
  ✓ All 5 stacks displayed with accurate data
  ✓ 6 dimensions scored 1-5 per stack
  ✓ At least one interactive feature (sorting by dimension, filtering by difficulty)
  ✓ Visual design: color-coded scores (green=5, yellow=3, red=1), progress bars or filled dots
  ✓ Loads and runs error-free
  ✓ Self-explanatory UX (tooltips or headers explain each dimension)

## Assumptions / Decisions (resolved this session)
- **Vanilla HTML/JS, not React.** Intake asked for "single HTML file, no build step" — vanilla JS guarantees that with zero dependency risk. Same interactivity, simpler to open and share.
- **Default sort: Learning Curve, ascending (easiest first).** Matches the "help people deciding what to learn next" framing from intake.
- **Badges included**, one per stack tied to its standout dimension rather than just "beginner/performance": Most In-Demand (React), Easiest to Learn (Python), Cloud-Native Performance (Go), Peak Performance (Rust), Fastest Runtime (Bun).

## Notes (session 3 — build complete)
- Built as a single self-contained HTML file (`tech-stack-comparison.html`), no external JS dependencies (Google Fonts CDN only).
- Design direction: dark "dev-tool spec sheet" aesthetic — terminal-style card headers, JetBrains Mono for data/labels, Space Grotesk for display type, equalizer-style segmented bars instead of plain progress bars (ties to the "stack" subject matter).
- Interactive features: sort by any of the 6 dimensions (click chip), filter by difficulty level (Beginner/Intermediate/Advanced, derived from Learning Curve score), hover tooltips on each dimension label explaining what it measures.
- Color-coded scores as required: red (1–2) → yellow (3) → green (4–5), independent of each stack's identity accent color so scanning stays readable.
- JS syntax validated (parses cleanly with Node).
- Open question flagged for review: `color-mix()` CSS function (used for badge backgrounds) needs a reasonably current browser (Chrome 111+/Safari 16.2+/Firefox 113+).
