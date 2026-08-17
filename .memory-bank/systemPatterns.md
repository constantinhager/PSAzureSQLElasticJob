---
status: current
last-verified: 2026-08-17
owner: active-agent
source: repository evidence
---

# System patterns

## Architecture

Proposed (not yet implemented): a Sampler-scaffolded PowerShell module whose
public cmdlets wrap Azure SQL Elastic Jobs management (via `Az.Sql`/ARM REST)
behind approved-verb, `Az`-style names, e.g. `New-AzSqlElasticJobAgent`,
`Get-AzSqlElasticJob`, `Set-AzSqlElasticJobStep`,
`Remove-AzSqlElasticJobTargetGroup` (exact cmdlet names: To confirm). A private
helper ensures the Job Agent's prerequisite logical SQL Server and job
database exist (create-if-missing) before any Elastic Job operation runs.

## Decisions

### Decision 1: Use the canonical Memory Bank base

- Choice: Keep durable project context in .memory-bank.
- Rationale: Preserve evidence-backed context across sessions.

### Decision 2: Initial scope and technology stack

- Choice: See `decisions/0001-initial-scope-and-stack.md`.
- Rationale: Confirmed directly with the user via clarifying questions before
  any code was written, to avoid guessing architecture.
