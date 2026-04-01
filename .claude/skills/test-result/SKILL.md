---
name: test-result
description: Run project-defined validation commands and analyze the results after implementation and test-code are complete.
disable-model-invocation: true
context: fork
agent: flow-test-result
argument-hint: [ task-summary ]
---

# Test Result

Task: $ARGUMENTS

Goals:

1. Load current project context from repository instructions.
2. Execute the validation commands defined by the project.
3. Summarize pass/fail status and analyze failures clearly.

Required output:

- Executed commands
- PASS / FAIL summary
- Key logs or error summaries
- Likely failure causes
- Recommended next actions

Do not modify implementation unless the task explicitly asks for a fix loop.