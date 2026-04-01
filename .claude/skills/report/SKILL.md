---
name: report
description: Produce the final task report after review and test-result are complete.
disable-model-invocation: true
context: fork
agent: flow-report
argument-hint: [ task-summary ]
---

# Report

Task: $ARGUMENTS

Goals:

1. Load current project context from repository instructions.
2. Produce a concise but complete final report.
3. Reflect actual implementation, review findings, and test results.

Required output:

- Goal
- What changed
- Changed files
- Review summary
- Test result summary
- Risks / follow-up
- Ready / Not ready judgment

Additional rule:

- If `TODO.md` exists in the project and the completed work changes the remaining task state, update `TODO.md` accordingly and mention that update in the report.

Do not invent success criteria that were not verified.