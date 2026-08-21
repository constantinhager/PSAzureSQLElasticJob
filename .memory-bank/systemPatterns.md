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
Optional parameters are forwarded through `Add-OptionalParameter`, which
preserves the difference between "not supplied" and "supplied as false".

Diagnostics go through `Write-PSFMessage`, and domain failures in public commands
go through `Stop-PSFFunction` with a caller-controlled `-EnableException` that
defaults to `$true`. The two private helpers deliberately still throw.

Logging convention: every Azure mutation is bracketed by an intent message and a
completion message at `Verbose`; lookups trace at `VeryVerbose`. Each message
carries a resource tag (`agent`, `job`, `step`, `credential`, `targetgroup`,
`target`, `server`, `database`, `environment`, `context`) and an operation tag
(`create`, `update`, `remove`, `execution`, `lookup`, `idempotent`, `strict`), so
`Get-PSFMessage -Tag` can slice the log either way.

Every `Remove-*` command is a no-op when the resource is absent unless
`-Strict` is supplied, and supports `-PassThru`.

Provisioning mutations use `-ErrorAction Stop` and wrap Azure failures in a
PSFramework error log plus `Stop-PSFFunction`. Each catch returns immediately
so a non-exception caller does not continue to dependent steps or receive false
`Created*` state.

`New-SqlElasticJobEnvironment` emits an `Output`-level PSFramework completion
summary after all resources are available. It names a fully reused environment
and otherwise lists the components created in that invocation.

Ordinary lifecycle, mutation and idempotency messages use the PSFramework
`Output` level so callers see progress without `-Verbose`. Keep detailed lookup
diagnostics at `VeryVerbose`.

When a lookup confirms that a resource is absent, report a concise
provisioning-oriented status rather than Azure's raw not-found exception text.

Composite public commands validate Azure context at their boundary, then use
private helpers and direct Az cmdlets for nested lookups. Do not call another
public command when it would repeat the same context assertion.

Each exported function's comment-based help begins its `.LINK` list with the
matching version-controlled source URL. PlatyPS uses the first link as the
external MAML `Online Version` target. Keep `Generate_MAML_from_built_module`
in the shared Sampler `build` workflow so both normal builds and `pack` create
and package the MAML help file.

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

### Decision 4: Testable optional-parameter forwarding

- Choice: See `decisions/0003-testable-optional-parameter-forwarding.md`.
- Rationale: Pester does not populate `$PSBoundParameters` inside mocks, so the
  forwarding logic had to move into a directly testable private function.

### Decision 5: Resource lookups fail closed

- Choice: See `decisions/0004-fail-closed-resource-lookup.md`.
- Rationale: Discarding the error stream made an unreadable resource look absent,
  defeating the classifier decision 0002 relies on.

### Decision 6: Adopt PSFramework

- Choice: See `decisions/0005-adopt-psframework.md`.
- Rationale: Requested by the user; `-EnableException` defaults to `$true` here
  because these commands provision infrastructure and must not fail quietly.

### Decision 7: Centralize CI permissions

- Choice: Declare GitHub Actions permissions at the workflow level and do not
  repeat them on the deploy job.
- Rationale: Job-level permissions replace rather than merge with global
  permissions. Sampler release tasks receive GitHub Actions' automatic token
  through their required `GitHubToken` environment variable. `contents: write`
  creates releases and `pull-requests: write` creates changelog pull requests;
  a missing personal access token can no longer make the tasks skip silently.

### Decision 8: Opt-in Azure subscription integration tests

- Choice: Keep real-Azure tests under `tests/Integration`, tag them
  `Integration`, and exclude that tag from the default Sampler test workflow.
- Rationale: The tests create and remove uniquely named Elastic Job resources
  but require a pre-existing resource group, logical SQL server and job
  database. An explicit tagged run prevents normal local and CI tests from
  requiring Azure credentials or incurring Azure changes.
