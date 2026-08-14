---
workflow: default-workflow-v1
created: 2026-08-13
status: active
---
# Local Model Compatibility for ICM

## Objective
Produce a practical reference report on which AI models/tools can act as a session
driver for the ICM filesystem workflow (read WORKSPACE_PROTOCOL.md, follow a stage
contract, read/write files responsibly), covering both hosted models already
confirmed (ChatGPT, Gemini, Grok) and local/self-hosted options (Ollama, LM Studio,
open-source agent CLIs like Goose, Continue, Cline, Aider, OpenHands). This is also
a live test of mid-task model handoff — the task is deliberately sized to span more
than one session/stage so it can be picked up by a different model partway through.

## Constraints and assumptions
- [x] Scope is "can this thing read WORKSPACE_PROTOCOL.md + a stage CONTEXT.md and
      operate on real files on Max's machine" — not a general LLM capability review.
- [x] Local options must be evaluated specifically for MCP filesystem-server
      compatibility (or an equivalent file read/write tool), since that's the
      actual mechanism ICM depends on.
- [x] Cost/privacy tradeoffs (local = private + free to run, hosted = easier setup)
      should be named explicitly, not just capability.
- [ ] Hardware assumptions (Max's machine specs) not yet gathered — flag as an open
      question if it materially changes local-model recommendations.

## Success criteria
1. Report covers at least: 2 hosted options with concrete setup steps for pointing
   them at the existing filesystem MCP config, and 3+ local/self-hosted options.
2. Each option is rated on: MCP/file-tool support, setup difficulty, and whether it
   reliably reads instructions before acting (flagged as "untested" if not verified).
3. A comparison table exists that Max can scan in under a minute.
4. A clear "start here" recommendation for the first local option to actually trial.
5. Every claim about a specific tool's capabilities is sourced (not asserted from
   possibly-stale training knowledge) given how fast this space moves.

## Required deliverables
- `deliverables/local-model-compatibility-report.md`

## Inputs and references
- Prior conversation in this task's session log (MCP donated to Linux Foundation Jan
  2026; ChatGPT, Gemini, Grok, Copilot already confirmed MCP-capable)
- Web research on current local-model + MCP tooling

## User-input checkpoint
- Material decisions identified: task scope (hosted vs. local coverage), how deep to
  go on setup instructions vs. just comparison.
- User input required: No, for initial scope — already discussed in chat immediately
  prior to task creation.
- Reason no input was required: Max explicitly asked to build this out live, right
  after discussing the hosted-model landscape, and asked for a "decent sized" task —
  scope above reflects that directly.
