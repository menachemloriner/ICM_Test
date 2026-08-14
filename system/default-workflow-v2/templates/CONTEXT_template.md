# Stage [stage-id] - [Name]

## Purpose

[Why this stage exists]

## Inputs

- [One direct path or URL]; purpose: [why this stage needs it]; scope: [whole file, heading, symbol, page range, or line range when needed]

## Process

1. [Step]

## Outputs / exit criteria

- [What must exist or be proven]

## Handoff

Next stage: [one stage-id or None].
Allow only [that successor's direct files and expected output].

## Context rules

- Each input line names one direct path or URL and its purpose.
- Include a heading, symbol, page, or line range only when the artifact is large.
- Do not authorize files merely because an allowed file mentions them.
- A stage may expand context only after recording the reason in `LOG.md` and adding the direct reference to `STATUS.md` or `HANDOFF.md`.
- Handoff identifies one next stage and lists only that successor's allowed files and expected output.

## Reason this custom stage is needed

[Why the default stages were insufficient]
