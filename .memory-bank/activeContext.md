---
status: current
last-verified: 2026-08-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

`New-SqlElasticJobEnvironment` now fails fast when Azure cannot create its
server, database or agent. Each provisioning step emits a PSFramework progress
message, converts non-terminating Azure errors to terminating failures, and
never returns misleading `Created*` state after failure. The full Sampler suite
passes with 344 tests. It also emits an `Output`-level completion summary that
states whether it reused the environment or which components it created.
All ordinary PSFramework lifecycle and existence messages now use `Output`;
the deeper resource lookup diagnostics remain `VeryVerbose`.
Confirmed absent-resource lookups now emit a concise provisioning-oriented
status instead of the raw Azure ARM error text.
`Test-SqlElasticJobEnvironment` validates Azure context once and performs its
agent lookup internally, avoiding a duplicate context status from the public
agent getter.

`New-SqlElasticJobEnvironment` can now also assign an existing user-assigned
managed identity to the Elastic Job agent via `-UseUserAssignedManagedIdentity`
and `-UserAssignedIdentityId`. It follows the same idempotent, `ShouldProcess`,
fail-on-`-ErrorAction Stop` pattern as the server/database/agent steps: a new
agent is created with the identity in one call; an existing agent is checked
via `$agent.Identity.UserAssignedIdentities` and only updated through
`Set-AzSqlElasticJobAgent` when the identity is missing. `Az.Sql` exposes
`-IdentityType`/`-UserAssignedIdentityId` on both `New-`/`Set-AzSqlElasticJobAgent`
(agent has no `PrimaryUserAssignedIdentityId`, unlike the server cmdlets). The
output object gained an `AssignedIdentity` boolean and the completion summary
lists `identity` among created resources.

A new public command, `New-SqlElasticJobUserAssignedIdentity`, wraps
`Az.ManagedServiceIdentity`'s `Get-`/`New-AzUserAssignedIdentity` with the same
idempotent create-if-missing shape as `New-SqlElasticJobAgent`/`New-SqlElasticJobCredential`
(simple pattern: no try/catch around the mutation, `-EnableException` only
guards the missing-`-Location` validation). `New-SqlElasticJobEnvironment`
gained `-CreateUserAssignedManagedIdentity` and `-UserAssignedIdentityName`; when
both are set together with `-UseUserAssignedManagedIdentity` it calls
`New-SqlElasticJobUserAssignedIdentity -Confirm:$false -ErrorAction Stop`
(wrapped in try/catch, following the composite command's stricter fail-fast
convention) before the agent step and uses the resulting `.Id` as
`$UserAssignedIdentityId`. `-Confirm:$false` suppresses the nested command's own
confirmation prompt while still letting `$WhatIfPreference` propagate
correctly, since `-WhatIf` is inherited through nested `ShouldProcess` calls in
the same runspace.

Az.ManagedServiceIdentity 2.0.0 was added as a `RequiredModules` dependency
(manifest + `RequiredModules.psd1`) to support this.

A live run against a real subscription surfaced two bugs, both now fixed:
1. A prior edit made `-ServerAdministratorCredential` `[Parameter(Mandatory)]`.
   Since most calls (idempotent re-runs, identity-only runs) never need it,
   PowerShell prompted interactively for a credential on every invocation
   without one - including under Pester, hanging the test run. Reverted to
   `[Parameter()]`; it stays validated internally (`$PSBoundParameters.ContainsKey`)
   only when the server does not yet exist.
2. `New-AzUserAssignedIdentity` (`Az.ManagedServiceIdentity` 2.0.0) reported an
   ARM error ("subscription not registered for Microsoft.ManagedIdentity") but
   still returned an object with an empty `.Id`, and the ambient inherited
   `$ErrorActionPreference = 'Stop'` did not turn that into a terminating
   error. `New-SqlElasticJobUserAssignedIdentity` now passes `-ErrorAction Stop`
   directly on that call *and* explicitly checks `[string]::IsNullOrEmpty($identity.Id)`
   after it returns, failing via `Stop-PSFFunction` either way.
   `New-SqlElasticJobEnvironment` also re-validates `$identity.Id` before using
   it, so an empty ID can never reach `New-AzSqlElasticJobAgent`. Lesson: do not
   trust an inherited `-ErrorAction Stop`/`$ErrorActionPreference` alone for
   generated Az cmdlets that process responses asynchronously - set it
   explicitly on the call and validate the returned object's identifying
   property.

Follow-up UX/reliability round based on that same live run:
- The user wants to be *prompted* for `-ServerAdministratorCredential` when it
  is forgotten, not just get a clear error (better than the earlier mandatory
  parameter, which prompted unconditionally and broke automation/tests). Fixed
  by calling `Get-Credential` only inside the "server missing" branch, storing
  the result in a plain local variable first and only assigning it to the
  `[ValidateNotNull()]` parameter variable when non-null - assigning `$null`
  directly to a validated parameter variable throws PowerShell's own generic
  "cannot be validated" error instead of the intended message, since
  `Validate*` attributes are enforced on every assignment to that variable,
  not just initial parameter binding.
- `New-SqlElasticJobUserAssignedIdentity` now calls a new private helper,
  `Assert-AzResourceProviderRegistered -ProviderNamespace 'Microsoft.ManagedIdentity'`,
  before creating the identity. It checks `Get-AzResourceProvider`'s
  `RegistrationState`, calls `Register-AzResourceProvider` and polls (default
  300s timeout / 10s interval, both mockable via parameters) until
  `Registered`, throwing directly (private-helper convention) otherwise. Added
  `Az.Resources` as a `RequiredModules` dependency for `Get-`/`Register-AzResourceProvider`.

The CI workflow now centralizes its permissions at the workflow level. The
deploy job inherits those permissions and maps GitHub Actions' automatic token
to the `GitHubToken` environment variable required by Sampler's release and
changelog tasks.

## Evidence

- `Az.Sql` 7.0.0 exposes the whole Elastic Jobs object model, so this module
  wraps it rather than reimplementing it - see
  `decisions/0002-wrap-az-sql-and-fail-safe-lookups.md`.
- Schedules are not a separate resource. They are parameters on
  `New-`/`Set-AzSqlElasticJob` (`-RunOnce`, `-IntervalType`, `-IntervalCount`,
  `-StartTime`, `-EndTime`, `-Enable`), verified from the cmdlet parameter sets.
- `Add-AzSqlElasticJobTarget` uses `-AgentServerName` for the agent's server and
  `-ServerName` for the target server. The wrapper exposes these as
  `-ServerName` and `-TargetServerName` for consistency with the rest of the
  module.
- Sampler ships **no** GitHub Actions workflow templates - only
  `azure-pipelines.yml.template`, `appveyor.yml` and GitHub *issue* templates.
  `.github/workflows/ci.yml` therefore comes from the canonical template in the
  `sampler-framework` skill, adapted to this module.
- Pester 5 does not populate `$PSBoundParameters` inside `ParameterFilter` or
  `MockWith`; see `decisions/0003-testable-optional-parameter-forwarding.md`.
- `tests/Integration/ElasticJobLifecycle.tests.ps1` runs only with the
  `Integration` tag and validates a caller-provided server/database before
  provisioning its unique agent, job, target group, target and step.
- Azure create cmdlets can emit non-terminating errors. Provisioning commands
  must use `-ErrorAction Stop`, log the captured error record, and return after
  `Stop-PSFFunction` so `-EnableException:$false` cannot continue to a
  dependent resource.

## Next step

Retry `New-SqlElasticJobEnvironment` with a globally unique server name, then
configure the three integration-test environment variables and run the live
lifecycle test.
