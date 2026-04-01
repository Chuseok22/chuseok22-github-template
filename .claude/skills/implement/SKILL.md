---
name: implement
description: Implement the planned change according to project rules and existing patterns.
disable-model-invocation: true
context: fork
agent: flow-implement
argument-hint: [ task-summary ]
---

# Implement

Task: $ARGUMENTS

Goals:

1. Load current project context from repository instructions.
2. Implement the requested change using existing project patterns.
3. Keep changes minimal, explicit, and maintainable.

Required output:

- Changed files
- What was implemented
- Notable decisions
- Follow-up items if any

Do not skip project rules.
Do not invent patterns when repository patterns already exist.