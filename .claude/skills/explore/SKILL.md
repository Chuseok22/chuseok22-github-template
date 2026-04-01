---
name: explore
description: Explore the current project for a task before planning. Read project rules, map relevant files, existing patterns, constraints, and unknowns.
disable-model-invocation: true
context: fork
agent: flow-explore
argument-hint: [ task-summary ]
---

# Explore

Task: $ARGUMENTS

Goals:

1. Load current project context from the repository instructions.
2. Identify the minimum relevant files and modules.
3. Find existing implementation patterns that should be reused.
4. Summarize constraints, risks, and unknowns.

Required output:

- Objective
- Relevant files
- Current behavior
- Existing patterns to follow
- Constraints from project rules
- Unknowns / open questions
- Planning handoff

Planning handoff format:

- Problem statement
- Relevant file paths
- Reusable patterns
- Constraints that planning must obey
- Open questions that remain unresolved

Do not modify files.
Do not produce implementation code.