# Ruby: incident-triage tool-registry sample

Demonstrates `Temporalio::Contrib::ToolRegistry` end-to-end: long-running `AgenticSession` activity, MCP HTTP integration, human-in-the-loop via companion workflow, and a testable activity refactor.

## What's here

| File | Purpose |
|---|---|
| `triage_types.rb` | Triage record classes. |
| `triage_activity.rb` | The activity. `TriageDeps` struct, `build_triage_registry(alert, session, deps)`, activity entrypoint. |
| `triage_workflow.rb`, `approval_workflow.rb` | Workflows. |
| `worker.rb`, `client.rb` | Worker entrypoint and demo client. |
| `test/triage_activity_test.rb` | Unit tests with `Testing::MockProvider` + fake `TriageDeps`. |

## Run

```bash
temporal server start-dev          # separate terminal

export ANTHROPIC_API_KEY=sk-ant-...
export PROM_MCP=http://localhost:7070/mcp
export K8S_MCP=http://localhost:7071/mcp

bundle install
ruby worker.rb
ruby client.rb
bundle exec rake test
```
