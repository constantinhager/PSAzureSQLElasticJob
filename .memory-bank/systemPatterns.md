---
status: current
last-verified: 2026-08-17
owner: active-agent
source: repository evidence
---

# System patterns

## Architecture

A Sampler-built PowerShell module. Public cmdlets use the `SqlElasticJob*` noun
family so they never collide with the `Az.Sql` `AzSqlElasticJob*` cmdlets they
wrap. Three private helpers carry the cross-cutting behaviour:

- `Assert-AzContext` - fails fast with one actionable message when the caller is
  not signed in, instead of letting an Az cmdlet fail obscurely later.
- `Get-AzResourceIfPresent` - runs a lookup and returns `$null` for a genuinely
  absent resource.
- `Test-AzResourceNotFoundError` - the single place that decides whether a
  failure means "absent" or something else.

Public commands follow a consistent shape: assert context, look up current
state, then create/update/remove only when needed, under `ShouldProcess`.

## Decisions

### Decision 1: Use the canonical Memory Bank base

- Choice: Keep durable project context in .memory-bank.
- Rationale: Preserve evidence-backed context across sessions.

### Decision 2: Initial scope and technology stack

- Choice: See `decisions/0001-initial-scope-and-stack.md`.
- Rationale: Confirmed directly with the user via clarifying questions before
  any code was written, to avoid guessing architecture.

### Decision 3: Wrap Az.Sql rather than reimplement the Elastic Jobs API

- Choice: See `decisions/0002-wrap-az-sql-and-fail-safe-lookups.md`.
- Rationale: `Az.Sql` already exposes the whole object model; the gap this
  module fills is idempotent provisioning and non-throwing lookups.
