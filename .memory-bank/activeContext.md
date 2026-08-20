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

`New-SqlElasticJobEnvironment`'s output object gained an `Identity` property:
`$agent.Identity` when `-UseUserAssignedManagedIdentity` was used, `$null`
otherwise. Sourcing it from `$agent.Identity` (rather than the separately
created `$identity` variable, which only exists on the
`-CreateUserAssignedManagedIdentity` path) means it's populated consistently
across every identity path: newly created agent, newly assigned identity on
an existing agent, and an agent that already had the identity.

`AssignedIdentity` had the same "only true for this run" problem: an
idempotent re-run where the agent already had the identity reported
`AssignedIdentity = $false`, which reads as "no identity is assigned" even
though one clearly is. Fixed by computing the output `AssignedIdentity` from
current state (`$agent.Identity.UserAssignedIdentities -contains $UserAssignedIdentityId`)
rather than the internal `$identityAssignedThisRun` flag, which is now used only
for the idempotent-check/`Created: ...` summary logic where "changed this run"
is the correct semantics.

`Add-`/`Remove-SqlElasticJobTarget`'s target-identifying parameters were
renamed for consistency with `-TargetServerName`/`-TargetGroupName`:
`-DatabaseName` -> `-TargetDatabaseName`, `-ElasticPoolName` ->
`-TargetElasticPoolName`, `-ShardMapName` -> `-TargetShardMapName`. The
underlying `Add-`/`Remove-AzSqlElasticJobTarget` cmdlets keep their original
`DatabaseName`/`ElasticPoolName`/`ShardMapName` parameter names, so
`Add-OptionalParameter`'s same-name forwarding no longer applies to these
three - they are now mapped explicitly (`$targetParameters['DatabaseName'] = $TargetDatabaseName`,
etc.) instead, while `Add-OptionalParameter` still handles
`RefreshCredentialName`/`Exclude` whose names are unchanged. `RefreshCredentialName`
kept its name since it names a credential, not a target. No back-compat alias
was added; the module is still unreleased/preview.

The user separately standardized brace style to OTBS (opening brace on the
same line as `function`/`process`/`if`) across `Add-`/`Remove-SqlElasticJobTarget`;
follow that style (already the majority style elsewhere, e.g.
`New-SqlElasticJobEnvironment.ps1`) for new code.

Added `Grant-SqlElasticJobTargetDatabaseAccess`, the module's first command
that touches the SQL *data plane* (T-SQL) rather than only the ARM control
plane. It creates a contained database user for a managed identity directly
in the target database (`CREATE USER [name] FROM EXTERNAL PROVIDER;` - no
separate server-level login needed for Azure SQL Database, unlike SQL
Managed Instance) and adds it to a database role (`-RoleName`, default
`db_owner`). Design decisions (confirmed with the user):
- Connects via an Azure AD access token from `Get-AzAccessToken -ResourceUrl 'https://database.windows.net/'`
  (reusing the caller's signed-in Az context, no separate SQL credential),
  passed straight through to `dbatools`' `Connect-DbaInstance -AccessToken`
  (dbatools accepts the `Get-AzAccessToken` output object directly).
- `dbatools` was added as a new `RequiredModules` dependency (2.8.4 installed
  locally; manifest pins >= 2.1.0) specifically for `Connect-DbaInstance`/
  `Invoke-DbaQuery`/`Disconnect-DbaInstance`. It is a large module but was the
  user's explicit choice over raw `Microsoft.Data.SqlClient` or the `SqlServer`
  module.
- `-TargetServerName`/`-TargetDatabaseName` (renamed from the initial
  `-ServerName`/`-DatabaseName` for consistency with
  `Add-`/`Remove-SqlElasticJobTarget`, and to avoid a pipeline property
  collision - e.g. `Add-SqlElasticJobTarget`'s output has its own `ServerName`
  meaning the agent's hosting server, not the target). A short name gets
  `.database.windows.net` appended automatically unless the input already
  contains a `.`. Output object properties were renamed to match
  (`TargetServerName`/`TargetDatabaseName`).
- `IdentityName`/`RoleName` go directly into interpolated T-SQL (CREATE
  USER/ALTER ROLE cannot parameterize identifiers), so both are constrained by
  `[ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_\-]{0,127}$')]` as a first defense
  layer, and additionally passed through the new private helper
  `Format-SqlBracketedIdentifier` (doubles `]` and wraps in brackets) as a
  second, independent layer before being embedded in T-SQL - defense in depth
  per the module's security-review conventions. Values embedded in `SELECT`
  lookups are also single-quote-escaped even though the pattern already blocks
  quotes.
- Idempotent like the rest of the module: looks up `sys.database_principals`/
  `sys.database_role_members` first and only runs `CREATE USER`/`ALTER ROLE`
  when missing.
- The SQL connection is always disconnected via `Disconnect-DbaInstance` in a
  `finally` block, even on failure.

Follow-up fix after a live run: the user reported two confirmation prompts
and two pipeline outputs for one call, plus asked to double check idempotency.
1. **Double output**: `Disconnect-DbaInstance -InputObject $sqlConnection -ErrorAction SilentlyContinue`
   was called unassigned in the `finally` block. Any uncaptured cmdlet output
   inside a function - including in `finally` - flows to the function's own
   output stream, so its return value became a second emitted object after
   the summary `PSCustomObject`. Fixed with `$null = Disconnect-DbaInstance ...`.
2. **Two confirmations**: the user creation and role-membership steps each had
   their own `$PSCmdlet.ShouldProcess()` call. Consolidated into a single
   `ShouldProcess` covering "Grant database access: <verb list>" for the whole
   operation (both steps still individually skip work that's already done),
   matching the "one summary object, one confirm" feel of
   `New-SqlElasticJobEnvironment`.
3. **Idempotency check gotcha** (introduced and then reverted in the same
   pass): tried to "harden" `$null -eq $existingUser`/`$existingMembership`
   checks to `@($existingUser).Count -gt 0`, intending to also treat an empty
   array as "absent". This actually broke detection: **`@($null).Count` is
   `1`, not `0`** - wrapping a variable that holds a literal `$null` in `@()`
   produces a one-element array *containing* `$null`, it does not produce an
   empty array. `dbatools`' `Invoke-DbaQuery` returning zero rows is captured
   as a real `$null` (zero pipeline objects collapses to `$null` on
   assignment), so the correct, simpler check is `$null -eq $existingUser` -
   reverted to that. Lesson: `@($x).Count -eq 0` is only a safe "is this
   empty" test when `$x` might itself be a *populated* array/collection you
   want to size-check: do not use it as a blanket replacement for `$null -eq`
   / `$null -ne` on a variable that a command assignment may leave as literal
   `$null`.
- Pester note: dbatools' `-SqlInstance`/`-AccessToken`/etc. parameters use
  custom argument-transforming types (e.g. `DbaInstanceParameter`), so a mock
  for `Connect-DbaInstance` must return something that itself coerces to that
  type (a plain string works) - returning an arbitrary `PSCustomObject` fails
  argument transformation *before* the mock body even runs, since Pester
  proxies still enforce the real parameter type. Also, `DbaInstanceParameter`
  has no `-eq` string equality - compare via `"$SqlInstance" -eq '...'` in a
  `-ParameterFilter`, not `$SqlInstance -eq '...'`.

The CI workflow now centralizes its permissions at the workflow level. The
deploy job inherits those permissions and maps GitHub Actions' automatic token
to the `GitHubToken` environment variable required by Sampler's release and
changelog tasks.

`Add-SqlElasticJobStep` now supports `Add-AzSqlElasticJobStep`'s `WithOutputDb`
parameter set: `-OutputDatabaseObject` (a live `AzureSqlDatabaseModel`, e.g.
from `Get-AzSqlDatabase` - mandatory, `ParameterSetName = 'WithOutputDb'`),
`-OutputTableName` (mandatory in that set), `-OutputCredentialName` and
`-OutputSchemaName` (both optional). Azure's own parameter names are reused
as-is (unlike the `Target*` rename elsewhere), so they forward through
`Add-OptionalParameter` unchanged. `CmdletBinding` gained
`DefaultParameterSetName = 'Default'`; all pre-existing parameters stay
common to both sets (no `ParameterSetName` on them), which is why none needed
touching. Azure also exposes `WithOutputDbId` (`-OutputDatabaseResourceId`
instead of a live object) and parent-object/parent-resource-ID variants
(`ObjectSet`, `ResourceIdSet`, etc.) - only `WithOutputDb` was requested and
added; those others remain unimplemented if ever needed.

Added `Get-SqlElasticJobExecutionOutput`: retrieves the rows a job step's
output table (from `Add-SqlElasticJobStep -OutputDatabaseObject`) holds for
one execution. Same dbatools/Azure AD access token connection pattern as
`Grant-SqlElasticJobTargetDatabaseAccess` (`Connect-DbaInstance`/
`Invoke-DbaQuery`/`Disconnect-DbaInstance` in a `finally`), plus the same
`Format-SqlBracketedIdentifier` defense for the schema/table/column names,
which cannot be parameterized. The execution-ID *value* itself, unlike
identifiers, genuinely can be parameterized, so it's passed via
`Invoke-DbaQuery -SqlParameter @{ ExecutionId = $JobExecutionId }` rather than
string interpolation. Per Microsoft's Elastic Jobs docs
(`elastic-jobs-tsql-create-manage`), the output table - whether auto-created
by the job step or pre-created manually - carries an `internal_execution_id`
(`uniqueidentifier`) column that is the only reliable join key back to a
specific run; that's the column `Start-SqlElasticJob`'s `JobExecutionId`
return value correlates against. Defaulted to that column name via
`-ExecutionIdColumnName`, overridable in case a manually pre-created table
used a different name.
Pester note: `Invoke-DbaQuery`'s `-SqlParameter` is typed `[PSObject[]]`, not
`[Hashtable]`, so passing a hashtable literal gets wrapped in a one-element
array; access it in a mock `-ParameterFilter` as `$SqlParameter[0]['Key']`,
not `$SqlParameter['Key']` (the latter silently fails to match, since arrays
don't support string indexers).

A live run of `Add-SqlElasticJobStep` against a job that did not exist yet
surfaced the same two bugs as `New-SqlElasticJobUserAssignedIdentity` earlier:
it logged "Using Azure context" twice (it called the public
`Get-SqlElasticJobStep` for its idempotency check, which itself calls
`Assert-AzContext`), and it called `Add-AzSqlElasticJobStep` without
`-ErrorAction Stop`, so Azure's non-terminating "job not found" error was
swallowed and the function printed a false "Added step..." success message.
Fixed by looking up the step inline (`Get-AzResourceIfPresent` wrapping
`Get-AzSqlElasticJobStep` directly, mirroring `Get-SqlElasticJobStep`'s own
body) and adding `-ErrorAction Stop`.

**Open item, not yet fixed**: an audit found this exact two-bug pattern
(duplicate `Assert-AzContext` via calling a sibling public `Get-*` getter, and
missing `-ErrorAction Stop` on the Az mutation call) across essentially every
simple CRUD command: `Add-SqlElasticJobTarget`, `New-SqlElasticJob`,
`New-SqlElasticJobAgent`, `New-SqlElasticJobCredential`,
`New-SqlElasticJobTargetGroup`, `Remove-SqlElasticJob`,
`Remove-SqlElasticJobAgent`, `Remove-SqlElasticJobCredential`,
`Remove-SqlElasticJobStep`, `Remove-SqlElasticJobTargetGroup`,
`Set-SqlElasticJob`, `Set-SqlElasticJobAgent`, `Set-SqlElasticJobCredential`,
`Set-SqlElasticJobStep`. Only `Add-SqlElasticJobStep` was fixed (the reported
instance); the others are unchanged and still have both bugs latent. This is a
good candidate for a dedicated follow-up pass across the whole CRUD surface
rather than a one-off fix, since it touches ~14 files and their tests.

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
