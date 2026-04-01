---
name: review
description: Review the implementation against project rules, architecture boundaries, and maintainability expectations.
disable-model-invocation: true
context: fork
agent: flow-review
argument-hint: [ task-summary ]
---

# Review

Task: $ARGUMENTS

Goals:

1. Load current project context from repository instructions.
2. Review the implemented change without editing code.
3. Detect correctness, boundary, maintainability, and regression risks.

Required output:

- Review scope
- Strengths
- Blocking issues
- Non-blocking issues
- Rule violations
- Suggested fixes
- Final judgment:
    - PASS
    - REWORK REQUIRED

Rules:

- If there is any blocking issue, the final judgment must be `REWORK REQUIRED`.
- If the final judgment is `REWORK REQUIRED`, the next workflow step must return to `/implement` before continuing to `/test-code`.
- Do not modify files.
- Be explicit about severity.