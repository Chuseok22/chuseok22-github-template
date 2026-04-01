---
name: project-context-loader
description: Shared protocol for loading project-specific context from the repository before performing any flow stage.
user-invocable: false
---

# Project context loading protocol

Before doing any actual work, always perform these steps in order:

1. Read the project root `CLAUDE.md`.
2. List all files under `.claude/rules/`.
3. Always read:
    - `.claude/rules/00-project-overview.md`
    - `.claude/rules/10-architecture-and-boundaries.md`
4. For implementation or review work, also read:
    - `.claude/rules/20-team-conventions.md`
5. For test writing or test execution work, also read:
    - `.claude/rules/30-testing-and-verification.md`
6. If reporting or delivery guidance is needed, also read:
    - `.claude/rules/40-delivery-and-review.md`

Working rules:

- Treat the root `CLAUDE.md` and `.claude/rules/*.md` files as the source of truth for current-project behavior.
- Do not assume backend, web, or app structure unless the project rules say so.
- Reuse existing project patterns before proposing new ones.
- When summarizing findings, mention the exact file paths used as evidence.
- If required information is missing, explicitly state what is missing before making assumptions.