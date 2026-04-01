---
name: plan
description: Create a concrete implementation plan after exploration using project-specific rules and conventions.
disable-model-invocation: true
context: fork
agent: flow-plan
argument-hint: [ task-summary ]
---

# Plan

Task: $ARGUMENTS

Goals:

1. Load current project context from repository instructions.
2. Convert exploration findings into a concrete plan.
3. Define file-level responsibilities and verification strategy.

Required output:

- Goal summary
- Files to change
- Why each file changes
- Risks and edge cases
- Test strategy
- Validation commands
- Review focus points
- Rollback considerations
- Implementation handoff

Implementation handoff format:

- Exact files to edit
- Expected responsibility of each file
- Constraints that implementation must obey
- Required tests to add
- Required validations to run later

Do not modify files.
Do not produce final implementation code.