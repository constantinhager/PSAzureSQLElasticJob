# Changelog for PSAzureSQLElasticJob

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-08-21

### Added

- Help files generation using PlatyPS and Sampler build pipeline. External
  MAML-formatted help files are automatically generated from comment-based help
  in Public cmdlets during the build, included in the module output, and
  validated by help quality checks.
- Command-level online-help URLs for every exported function. `Get-Help
  <command> -Online` opens the command's version-controlled help source.
- Module icon (`assets/PSAzureSQLElasticJob.svg`), referenced from the
  manifest's `IconUri` and shown at the top of `README.md`.
- Custom `Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobStepModel`
  table view in `PSAzureSQLElasticJob.Format.ps1xml`, overriding `Az.Sql`'s own
  default view (loaded first, via `Update-FormatData -PrependPath` in
  `suffix.ps1`). Its long `CommandText` no longer wraps across many
  hard-to-read lines - it's truncated with `...` in the table - and the
  `Output` column shows a short `schema.table` instead of the nested output
  model's raw type name.
- Tab completion (PSFramework TEPP) for `-ResourceGroupName`,
  `-ServerName`/`-TargetServerName`/`-OutputServerName`,
  `-DatabaseName`/`-TargetDatabaseName`/`-OutputDatabaseName`, `-AgentName`,
  job/step `-Name`/`-JobName`, credential
  `-Name`/`-CredentialName`/`-OutputCredentialName`/`-RefreshCredentialName`
  and target group `-Name`/`-TargetGroupName` across the module. Later
  parameters are scoped by whatever earlier ones the caller already typed
  (e.g. completing `-Name` on `Get-SqlElasticJobStep` only suggests steps
  that exist on the `-JobName` already given).
- `PSAzureSQLElasticJob.Format.ps1xml` with compact table views for
  `New-SqlElasticJobEnvironment`, `Test-SqlElasticJobEnvironment` and
  `Grant-SqlElasticJobTargetDatabaseAccess`. Their `PSCustomObject` output now
  carries a `PSTypeName` (`PSAzureSQLElasticJob.EnvironmentResult`,
  `PSAzureSQLElasticJob.EnvironmentStatus` and
  `PSAzureSQLElasticJob.TargetDatabaseAccessResult` respectively) so the
  default rendering is a one-line table instead of PowerShell's default list
  view, which each object's property count (6-11) would otherwise trigger.
  Other commands return Az.Sql model objects, which already have their own
  formatting from `Az.Sql`, so were left unchanged.
- Populated `README.md` with requirements, an end-to-end quick start example
  and a full command reference table.
- Opt-in Azure subscription integration tests that validate the Elastic Job
  lifecycle while preserving the supplied resource group, server and database.
- Sampler-based project scaffold with GitVersion, Pester 5 and GitHub Actions.
- `New-SqlElasticJobEnvironment` to provision the logical SQL server, job
  database and Elastic Job agent, creating only the parts that are missing.
- `New-SqlElasticJobEnvironment` accepts `-UseUserAssignedManagedIdentity` and
  `-UserAssignedIdentityId` to assign an existing user-assigned managed
  identity to the Elastic Job agent, idempotently. The output object gains an
  `Identity` property with the agent's identity details when used.
- `New-SqlElasticJobUserAssignedIdentity` to idempotently create a user-assigned
  managed identity, and a `-CreateUserAssignedManagedIdentity` (with
  `-UserAssignedIdentityName`) parameter set on `New-SqlElasticJobEnvironment`
  that creates the identity when missing and assigns it to the Elastic Job
  agent in one call. `New-SqlElasticJobUserAssignedIdentity` registers the
  `Microsoft.ManagedIdentity` resource provider automatically when it is not
  already registered on the subscription.
- `Grant-SqlElasticJobTargetDatabaseAccess` to idempotently create a contained
  database user for a user-assigned managed identity on a target Azure SQL
  Database (`CREATE USER ... FROM EXTERNAL PROVIDER`) and add it to a database
  role, `db_owner` by default. Connects using an Azure AD access token from the
  caller's signed-in Az context via the new `dbatools` dependency. Its
  `-TargetServerName`/`-TargetDatabaseName` parameters match the naming used by
  `Add-`/`Remove-SqlElasticJobTarget`. Both steps are confirmed once as a
  single grant operation and return exactly one summary object.
- `Get-SqlElasticJobExecutionOutput` to retrieve the rows a job step wrote to
  its output table for one execution, correlated by an explicit
  `$(job_execution_id)` column the step's `CommandText` must select (Azure's
  own system-managed output column does not match the `JobExecutionId`
  `Start-SqlElasticJob` returns, so it cannot be used for filtering). Uses the
  same `dbatools`/Azure AD access token connection as
  `Grant-SqlElasticJobTargetDatabaseAccess`.
- `Test-SqlElasticJobEnvironment` to report which parts of an environment exist
  without changing anything.
- `Get-SqlElasticJobAgent`, `New-SqlElasticJobAgent`, `Set-SqlElasticJobAgent`
  and `Remove-SqlElasticJobAgent` for Elastic Job agent CRUD.
- Job CRUD: `Get-SqlElasticJob`, `New-SqlElasticJob`, `Set-SqlElasticJob`,
  `Remove-SqlElasticJob`, plus `Start-SqlElasticJob` and `Stop-SqlElasticJob`.
  Schedules are set through the job itself with `-RunOnce` or
  `-IntervalType`/`-IntervalCount`, matching the Elastic Jobs object model.
- Job step CRUD: `Get-SqlElasticJobStep`, `Add-SqlElasticJobStep`,
  `Set-SqlElasticJobStep` and `Remove-SqlElasticJobStep`. `Add-SqlElasticJobStep`
  supports Azure's `WithOutputDb` parameter set (`-OutputDatabaseObject`,
  `-OutputTableName`, `-OutputCredentialName`, `-OutputSchemaName`) to write a
  step's query results into an output database table.
- Job credential CRUD: `Get-SqlElasticJobCredential`,
  `New-SqlElasticJobCredential`, `Set-SqlElasticJobCredential` and
  `Remove-SqlElasticJobCredential`.
- Target group CRUD: `Get-SqlElasticJobTargetGroup`,
  `New-SqlElasticJobTargetGroup` and `Remove-SqlElasticJobTargetGroup`, plus
  `Add-SqlElasticJobTarget` and `Remove-SqlElasticJobTarget`. Their target-type
  parameters are named `-TargetDatabaseName`, `-TargetElasticPoolName` and
  `-TargetShardMapName` for consistency with `-TargetServerName`.
- GitHub Actions workflow `.github/workflows/ci.yml` covering build, test and
  release to GitHub and the PowerShell Gallery.
- GitHub issue templates under `.github/ISSUE_TEMPLATE/`.
- MIT license file.

### Fixed

- CI release/packaging step still failing with "PowerShellGet cannot resolve
  the module dependency 'dbatools.library'" after the previous
  `ExternalModuleDependencies` fix - that setting only covers the real
  PSGallery publish step, not Sampler's `package_module_nupkg` task, which
  separately re-publishes every direct `RequiredModules` entry into a local
  `output` repository before validating the built module against it, and
  never touches transitive dependencies (`dbatools.library` is `dbatools`'s
  own dependency, not ours). Fixed by adding `dbatools.library` as an
  explicit `RequiredModules` entry, positioned *before* `dbatools` in the
  array so it gets published to that local repository first - order matters
  because Sampler's task processes the array in sequence and `dbatools`'s
  own publish step validates its `dbatools.library` requirement against
  whatever is already there. Reproduced and verified the fix locally with
  `.\build.ps1 -Tasks pack` before pushing.
- CI release/packaging step failing with "PowerShellGet cannot resolve the
  module dependency 'dbatools.library'" - declared it under
  `PrivateData.PSData.ExternalModuleDependencies` in the module manifest so
  PowerShellGet no longer tries to resolve it from the local build
  repository. Not reproducible locally since a plain `.\build.ps1` never
  runs the `package_module_nupkg`/release tasks that validate this.
- `Add-SqlElasticJobTarget`, `New-SqlElasticJob`, `New-SqlElasticJobAgent`,
  `New-SqlElasticJobCredential`, `New-SqlElasticJobTargetGroup`,
  `Remove-SqlElasticJob`, `Remove-SqlElasticJobAgent`,
  `Remove-SqlElasticJobCredential`, `Remove-SqlElasticJobStep`,
  `Remove-SqlElasticJobTargetGroup`, `Set-SqlElasticJob`,
  `Set-SqlElasticJobAgent`, `Set-SqlElasticJobCredential` and
  `Set-SqlElasticJobStep` no longer call `Assert-AzContext` twice per
  invocation (once directly, once again inside the public `Get-*` getter used
  for their existence check) and now force `-ErrorAction Stop` on their
  underlying Az mutation call, so a failure is reported instead of silently
  reporting success. Same pattern already fixed in `Add-SqlElasticJobStep`.
- `-ServerAdministratorCredential` on `New-SqlElasticJobEnvironment` is optional
  again; it is only required when the logical SQL server does not yet exist.
  When omitted in that case, you are now prompted interactively for it instead
  of failing outright or being forced to always supply it.
- `New-SqlElasticJobUserAssignedIdentity` now forces `-ErrorAction Stop` on the
  underlying `New-AzUserAssignedIdentity` call and fails when Azure returns no
  resource ID, instead of reporting success and letting
  `New-SqlElasticJobEnvironment` assign an empty identity ID to the Elastic Job
  agent.
- `New-SqlElasticJobEnvironment`'s `AssignedIdentity` output property now
  reflects whether the Elastic Job agent currently has the requested identity
  assigned, instead of only whether this call performed the assignment. It
  previously reported `$false` for an idempotent re-run even though the agent
  already had the identity.
- `Add-SqlElasticJobStep` no longer logs the Azure context twice (it looked up
  the existing step via the public `Get-SqlElasticJobStep`, which asserts the
  context again) and now forces `-ErrorAction Stop` on `Add-AzSqlElasticJobStep`,
  so a non-terminating Azure error (e.g. the job does not exist) throws instead
  of being silently swallowed and reported as a false success.

### Changed

- Replace raw Azure not-found errors with a concise status explaining that
  provisioning will create an absent resource when needed.
- Make ordinary Elastic Job lifecycle and existence messages visible by default.
- `New-SqlElasticJobEnvironment` now reports whether it reused an existing
  environment or which resources it created.
- The CI release and changelog tasks now use GitHub Actions' automatic token
  with repository-content write access, so a successful `main` deployment
  creates its GitHub release instead of silently skipping it when no personal
  access token secret is configured.
- Every Azure create, update, remove and execution call is now bracketed by an
  intent and a completion message, and every lookup is traced. Messages carry a
  resource tag and an operation tag, so `Get-PSFMessage -Tag 'agent'` or
  `-Tag 'remove'` slices the log without parsing console output. Enable a
  destination with `Set-PSFLoggingProvider` when a durable log is wanted.
- The module now depends on PSFramework. Diagnostics go through
  `Write-PSFMessage` and are retrievable with `Get-PSFMessage`; domain failures
  in public commands go through `Stop-PSFFunction`.
- Commands that can fail with a domain error gained an `-EnableException`
  parameter. It defaults to `$true`, which preserves the existing behaviour of
  raising a terminating error; pass `$false` for a warning and no output.
- The job database service objective and logical server version defaults are now
  PSFramework settings (`PSAzureSQLElasticJob.Provisioning.ServiceObjective` and
  `...ServerVersion`) instead of hardcoded parameter defaults, so they can be
  retuned with `Set-PSFConfig` without editing code.

### Deprecated

- For soon-to-be removed features.

### Removed

- For now removed features.

### Fixed

- Avoid duplicate Azure-context status messages during environment checks.
- Stop provisioning after an Azure server, database or agent creation failure,
  preserving accurate creation state and logging the failed provisioning step.
- Resource lookups no longer treat an unreadable resource as an absent one. A
  non-terminating authorization or throttling error from Azure was previously
  discarded, which could make provisioning attempt to create a resource that
  already existed and hide the real failure.

### Security

- A permission, authentication, quota or throttling failure is never classified
  as a missing resource, even when Azure words it as "not found or you do not
  have access". An HTTP status now settles the classification on its own, and
  message text is only consulted when no status is available.
- Every GitHub Actions reference is pinned to a commit SHA, so a moved tag
  cannot introduce new code into the job that holds the release secrets.
- `.gitignore` now excludes common credential material.
