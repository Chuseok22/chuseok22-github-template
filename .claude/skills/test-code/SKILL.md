---
name: test-code
description: Write or update test code for the implemented change according to project-specific testing rules.
disable-model-invocation: true
context: fork
agent: flow-test-code
argument-hint: [ task-summary ]
---

# Test Code

Task: $ARGUMENTS

Goals:

1. Load current project context from repository instructions.
2. Add or update tests that match the project's testing strategy.
3. Cover the implemented behavior with focused tests.

Required output:

- Added or changed test files
- Covered scenarios
- Uncovered scenarios
- Assumptions or limitations

Rules:

- This stage is for writing or updating test code.
- Do not treat verification as complete in this stage.
- Final execution results belong to `/test-result`.
- Only run minimal local feedback checks if needed to complete the test code itself, and clearly label them as local feedback rather than final verification.