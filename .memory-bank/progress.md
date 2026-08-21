---
status: current
last-verified: 2026-08-17
owner: active-agent
source: repository evidence
---

# Progress

## Current status

Version `1.0.0` released for the agreed CRUD scope. The release workflow passed
package creation, Ubuntu/macOS/Windows tests, GitHub Release publication and
PowerShell Gallery publication. Azure subscription integration tests remain
opt-in.

## Recent milestones

- 2026-08-21: Released version `1.0.0` from `main` with tag `v1.0.0`. GitHub
  Actions passed package, cross-platform tests and deploy; the module is
  available on PowerShell Gallery as `PSAzureSQLElasticJob` version `1.0.0`.
- 2026-08-21: Added command-level online-help URLs for every exported function
  and moved MAML generation into the shared Sampler `build` workflow, so CI's
  `pack` workflow includes external help. Full build and test validation passed
  with the detached PowerShell Core runner.
- 2026-08-17: Canonical Memory Bank base initialized.
- 2026-08-17: Project scope, stack, and CRUD surface confirmed with the user.
- 2026-08-17: Sampler `SimpleModule` scaffold generated and merged; manifest
  retargeted to PowerShell 7+ with `Az.Accounts`/`Az.Sql` dependencies.
- 2026-08-17: Provisioning (`New-`/`Test-SqlElasticJobEnvironment`) and agent
  CRUD implemented; full `build.ps1` run green with 105 passing tests.
- 2026-08-17: Job, job step, job credential, target group and target CRUD
  implemented; GitHub Actions CI/release workflow and issue templates added;
  `build.ps1` green with 322 passing tests.
- 2026-08-17: Security review completed. Fixed a fail-open resource lookup that
  reported unreadable resources as absent; 326 tests passing.
- 2026-08-17: Remediation pass. Tightened not-found classification, pinned every
  GitHub Action to a commit SHA, added credential patterns to `.gitignore`;
  332 tests passing.
- 2026-08-17: Adopted PSFramework for logging, flow control and configuration;
  337 tests passing.
- 2026-08-17: Extended logging to every Azure mutation and lookup with resource
  and operation tags; 341 tests passing.
- 2026-08-18: Removed the redundant deploy-job permission override; it now
  inherits the workflow-level permissions while release tasks keep the
  `GitHubToken` personal-access-token mapping.
- 2026-08-18: Fixed the green-but-no-release workflow outcome by mapping
  GitHub Actions' automatic token to Sampler's `GitHubToken` input and granting
  `contents: write` at the workflow level.
- 2026-08-18: Added opt-in Azure subscription lifecycle coverage. The default
  suite excludes the `Integration` tag; `build.ps1 -Tasks test` passed with 9
  tasks and 0 errors.
- 2026-08-18: Fixed provisioning to stop on Azure server, database and agent
  creation errors, log each current step through PSFramework, and avoid false
  `Created*` results. Full suite passed with 344 tests.
- 2026-08-18: Added a caller-visible PSFramework completion summary for
  `New-SqlElasticJobEnvironment`; the full Sampler suite passed with 344 tests.
- 2026-08-18: Promoted all ordinary PSFramework lifecycle and existence
  messages to `Output`; retained `VeryVerbose` lookup diagnostics and added a
  source-level regression guard. Full Sampler suite passed.
- 2026-08-18: Replaced raw Azure not-found error messages with a concise
  absent-resource status explaining that provisioning will create it when
  needed. Full Sampler suite passed.
- 2026-08-18: Removed the redundant public agent lookup from environment
  checks, so Azure context is asserted and reported once. Full Sampler suite
  passed.
- 2026-08-20: Added `-UseUserAssignedManagedIdentity`/`-UserAssignedIdentityId`
  to `New-SqlElasticJobEnvironment` to idempotently assign an existing
  user-assigned managed identity to the Elastic Job agent. Full Sampler suite
  passed with 352 tests.
- 2026-08-20: Added `New-SqlElasticJobUserAssignedIdentity` (wrapping the new
  `Az.ManagedServiceIdentity` dependency) and wired
  `-CreateUserAssignedManagedIdentity`/`-UserAssignedIdentityName` into
  `New-SqlElasticJobEnvironment` so it can create the identity when missing and
  assign it to the Elastic Job agent in one call. Full Sampler suite passed
  with 366 tests.
- 2026-08-20: Fixed two bugs found during a live Azure run: reverted an
  accidental `-ServerAdministratorCredential` mandatory-parameter change that
  caused interactive prompting/test hangs, and hardened
  `New-SqlElasticJobUserAssignedIdentity` to fail when Azure reports success
  but returns no resource ID (seen when the `Microsoft.ManagedIdentity`
  resource provider is not registered). Full Sampler suite passed with 369
  tests.
- 2026-08-20: Made `-ServerAdministratorCredential` prompt interactively via
  `Get-Credential` when omitted and the server doesn't exist yet (rather than
  erroring), and added automatic `Microsoft.ManagedIdentity` resource-provider
  registration (new private `Assert-AzResourceProviderRegistered` helper, new
  `Az.Resources` dependency) to `New-SqlElasticJobUserAssignedIdentity`. Full
  Sampler suite passed with 380 tests.
- 2026-08-20: Added an `Identity` property (`$agent.Identity`) to
  `New-SqlElasticJobEnvironment`'s output object whenever
  `-UseUserAssignedManagedIdentity` was used. Full Sampler suite passed with
  380 tests.
- 2026-08-20: Fixed `AssignedIdentity` to reflect current state (the agent has
  the identity) rather than only "assigned during this call", so an idempotent
  re-run against an agent that already has the identity now correctly reports
  `$true`. Full Sampler suite passed with 380 tests.
- 2026-08-20: Renamed `Add-`/`Remove-SqlElasticJobTarget`'s `-DatabaseName`/
  `-ElasticPoolName`/`-ShardMapName` to `-TargetDatabaseName`/
  `-TargetElasticPoolName`/`-TargetShardMapName` for consistency with
  `-TargetServerName`. Full Sampler suite passed with 380 tests.
- 2026-08-20: Added `Grant-SqlElasticJobTargetDatabaseAccess`, the first
  command to touch the SQL data plane: creates a contained database user for a
  managed identity on a target Azure SQL Database and adds it to a database
  role (default `db_owner`), authenticating via an Azure AD token from the
  caller's Az context and the new `dbatools` dependency. Full Sampler suite
  passed with 404 tests.
- 2026-08-20: Renamed `Grant-SqlElasticJobTargetDatabaseAccess`'s
  `-ServerName`/`-DatabaseName` to `-TargetServerName`/`-TargetDatabaseName`;
  fixed a live-run bug where it produced two confirmation prompts and two
  pipeline outputs (an uncaptured `Disconnect-DbaInstance` call leaked a
  second output) by consolidating to one `ShouldProcess` and suppressing that
  call's output. Full Sampler suite passed with 406 tests.
- 2026-08-20: Fixed `Add-SqlElasticJobStep`: it logged the Azure context twice
  (called the public `Get-SqlElasticJobStep` getter, which asserts context
  again) and swallowed a non-terminating `Add-AzSqlElasticJobStep` error
  (missing `-ErrorAction Stop`), printing a false success message when the job
  did not exist. Fixed both; an audit found the same two-bug pattern latent in
  ~14 other CRUD commands, not yet fixed (see Open work). Full Sampler suite
  passed with 407 tests.
- 2026-08-20: Added Azure's `WithOutputDb` parameter set to
  `Add-SqlElasticJobStep` (`-OutputDatabaseObject`, `-OutputTableName`,
  `-OutputCredentialName`, `-OutputSchemaName`) so a step can write its query
  results into an output database table. Full Sampler suite passed with 409
  tests.
- 2026-08-20: Added `Get-SqlElasticJobExecutionOutput` to retrieve a job
  step's output-table rows for a specific execution, correlated via the
  table's `internal_execution_id` column against `Start-SqlElasticJob`'s
  `JobExecutionId`. Same dbatools/Azure AD token connection pattern as
  `Grant-SqlElasticJobTargetDatabaseAccess`. Full Sampler suite passed with
  423 tests.
- 2026-08-20: Live-tested `Get-SqlElasticJobExecutionOutput` against a real
  job/output table and found `internal_execution_id` does NOT match
  `JobExecutionId` (verified at job/step/target execution level - none of 6
  distinct table IDs matched any of the job's 6 successful execution IDs,
  despite the counts lining up). Fixed by switching to an explicit
  `$(job_execution_id) AS JobExecutionId` column the step's `CommandText`
  must select, changing the default `-ExecutionIdColumnName` to
  `JobExecutionId` and updating `Add-SqlElasticJobStep`'s `WithOutputDb`
  example accordingly. Full Sampler suite still passed with 423 tests.
- 2026-08-20: Fixed the duplicate-`Assert-AzContext`/missing-`-ErrorAction
  Stop` pattern (found earlier in `Add-SqlElasticJobStep`) across the rest of
  the CRUD surface: `Add-SqlElasticJobTarget`, `New-SqlElasticJob`,
  `New-SqlElasticJobAgent`, `New-SqlElasticJobCredential`,
  `New-SqlElasticJobTargetGroup`, `Remove-SqlElasticJob`,
  `Remove-SqlElasticJobAgent`, `Remove-SqlElasticJobCredential`,
  `Remove-SqlElasticJobStep`, `Remove-SqlElasticJobTargetGroup`,
  `Set-SqlElasticJob`, `Set-SqlElasticJobAgent`, `Set-SqlElasticJobCredential`,
  `Set-SqlElasticJobStep`. No test changes needed since existing unit tests
  already mocked the underlying `Get-AzSqlElasticJob*`/mutation cmdlets
  directly. Full Sampler suite still passed with 423 tests.
- 2026-08-20: Populated `README.md` (previously a two-line stub) with
  requirements, an end-to-end quick start covering environment provisioning
  through job execution and output retrieval, and a full command reference
  table grouped by area (environment, agents, jobs/steps,
  credentials/targets).
- 2026-08-20: Added `PSAzureSQLElasticJob.Format.ps1xml` with table views for
  the three `PSCustomObject`-returning commands (`New-SqlElasticJobEnvironment`,
  `Test-SqlElasticJobEnvironment`, `Grant-SqlElasticJobTargetDatabaseAccess`),
  each now tagged with a `PSTypeName` so the view applies. Their default
  rendering was PowerShell's list view (property count > 4 with no format
  data), which is functional but less scannable than a one-line table for a
  quick idempotent-check summary. Every other command returns an Az.Sql (or
  Az.ManagedServiceIdentity) model object already carrying its own format
  data from that module, so left untouched; `Get-SqlElasticJobExecutionOutput`
  returns rows of an arbitrary user-defined query shape, so a fixed format
  view isn't applicable there. Registered via `FormatsToProcess` in the
  manifest and `CopyPaths` in `build.yaml` (ModuleBuilder only merges *.ps1
  automatically; standalone files like a `.Format.ps1xml` need an explicit
  `CopyPaths` entry to land in `output/module/.../<version>/`). Full Sampler
  suite passed with 429 tests (6 new).
- 2026-08-20: Added PSFramework TEPP tab completion for
  `-ResourceGroupName`, `-ServerName`/`-TargetServerName`/`-OutputServerName`,
  `-DatabaseName`/`-TargetDatabaseName`/`-OutputDatabaseName`, `-AgentName`,
  job/step `-Name`/`-JobName`, credential
  `-Name`/`-CredentialName`/`-OutputCredentialName`/`-RefreshCredentialName`
  and target group `-Name`/`-TargetGroupName`, registered in `suffix.ps1`
  (the only place module code runs at import - see the file's own header
  comment). Each completer reads already-bound parameters via
  `$fakeBoundParameter` to scope its Azure lookup (e.g. step names are only
  looked up once `-JobName` is already typed) and silently returns nothing
  rather than throwing, since a broken completer must never interrupt typing.
  **Bug found and fixed during manual live-environment verification**: the
  Elastic Jobs Az.Sql model objects do NOT expose a generic `.Name` property -
  they use type-specific names (`AgentName`, `JobName`, `StepName`,
  `CredentialName`, `TargetGroupName`); using `.Name` compiled and imported
  fine but silently returned zero completions for every one of those five
  completers. Only `Get-AzSqlServer`/`.ServerName` and
  `Get-AzSqlDatabase`/`.DatabaseName` happen to match the generic pattern.
  Verified against the live `elasticjobtest-rg` environment with
  `TabExpansion2` before/after the fix. Added
  `tests/Unit/TabCompletion.tests.ps1` (12 tests) mocking each `Get-AzSql*`
  cmdlet with the correct property names so this class of bug regresses
  loudly instead of silently. Also fixed an unrelated pre-existing bug found
  while chasing a test failure here: `FormatData.tests.ps1`'s "should render
  as a table" test relied on `Hashtable.Keys` enumeration order (undefined in
  PowerShell) to pick an "expected" substring, making it flaky - fixed by
  asserting a specific, explicitly-chosen value instead. Full Sampler suite
  passed with 440 tests.
  Left unaddressed (documented, not implemented): tab completion for
  `New-SqlElasticJobUserAssignedIdentity -Name` (creating a brand-new
  identity name has no natural "existing values" source without adding
  `Get-AzUserAssignedIdentity` lookups, judged low value for this pass).
- 2026-08-20: Added a custom table view for
  `Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobStepModel`
  (the type `Get-SqlElasticJobStep`/`Add-SqlElasticJobStep`/etc. return) to
  fix ugly multi-line wrapping of long `CommandText` values in the default
  console table. Key finding: simply adding a `View` for an Az.Sql-owned type
  to our own `FormatsToProcess` entry is NOT enough to override it - `Az.Sql`
  is a `RequiredModules` dependency and imports (registering its own format
  data for that type) *before* our module does, and PowerShell's default view
  selection prefers the first-registered view for a type when multiple exist
  and no `-View` is given. Fixed by calling
  `Update-FormatData -PrependPath <path-to-our-.ps1xml>` explicitly in
  `suffix.ps1` (module-load-time code), which inserts our format data at the
  front of the search order, ahead of `Az.Sql`'s. Verified this ordering
  empirically (`Format-Table`/default rendering) both before and after the
  fix against the live environment - before the fix the view looked
  identical to Az.Sql's stock output despite our format data being loaded.
  Also learned along the way: the nested `Output` property
  (`AzureSqlElasticJobStepOutputModel`) has no `ToString()` override of its
  own either - Az.Sql's nice `(server.db.schema.table)`-looking display for
  it in their own view comes from an inline `<ScriptBlock>` column
  expression, not the object's own string conversion; replicated with a
  `ScriptBlock` reading its `ServerName`/`DatabaseName`/`SchemaName`/
  `TableName` properties, simplified to just `schema.table` for column width.
  Added `tests/Unit/FormatData.tests.ps1` cases asserting the step view
  exists, renders as one line, truncates `CommandText`, and doesn't leak the
  `AzureSqlElasticJobStepOutputModel` type name. Full Sampler suite passed
  with 443 tests.
- 2026-08-20: Fixed a CI-only failure (never reproducible locally) in the
  `package_module_nupkg`/release Sampler task: `Publish-PSArtifactUtility`
  couldn't resolve `dbatools`'s own dependency `dbatools.library` against
  the local build-output PSRepository. `dbatools.library` is a large native
  binary package, not something we vendor or want PowerShellGet to try to
  validate/publish as part of our own dependency chain. Fixed by declaring
  it under `PrivateData.PSData.ExternalModuleDependencies` in the module
  manifest - exactly what PowerShellGet's own error message suggested. A
  plain `.\build.ps1` never runs the release/package tasks, which is why
  this only ever surfaced in the GitHub Actions pipeline (job link from the
  user: run 32383793291), not locally. Full Sampler suite still passed with
  443 tests locally (this task itself can't be exercised without actually
  publishing, so the real validation is the next CI run on the PR).
- 2026-08-20: **CORRECTION** - the `ExternalModuleDependencies` fix above did
  NOT resolve the CI failure; the exact same error recurred on the next push
  (run 32385654684), and this time it WAS reproducible locally, via
  `.\build.ps1 -Tasks pack` (the default `.\build.ps1` never runs the `pack`
  workflow, only `build`+`test` - use `-Tasks pack` specifically to exercise
  `package_module_nupkg` locally instead of waiting on CI round-trips).
  Root cause, found by reading Sampler's own
  `release.module.build.ps1` (`output/RequiredModules/Sampler/<version>/tasks/`
  locally): the `package_module_nupkg` task loops over the BUILT module's
  OWN `RequiredModules` array and calls
  `Publish-Module -Repository output -Path $module.ModuleBase` for each one,
  republishing every direct dependency into a throwaway local PSRepository
  folder so the final `Publish-Module` call for our own module can validate
  against it. `ExternalModuleDependencies` only affects the manifest of the
  module *being published* (ours) - it does nothing for a THIRD PARTY
  module's (dbatools's) own nested `RequiredModules` entry
  (`dbatools.library`), which this loop never publishes at all since it
  isn't in *our* `RequiredModules` list. When the loop reaches `dbatools`
  and calls `Publish-Module -Repository output -Path <dbatools path>`,
  THAT call recursively validates dbatools's own `dbatools.library`
  requirement against the (still-empty-of-it) `output` repo and fails.
  Real fix: add `dbatools.library` as an explicit `RequiredModules` entry in
  OUR manifest too (version pinned to what `dbatools`'s own manifest
  requires - checked via
  `Select-String -Path .../dbatools.psd1 -Pattern library` locally, found
  `ModuleVersion = '2026.5.3'`), **and put it BEFORE `dbatools` in the
  array** - Sampler's loop processes the array in declared order, and
  `dbatools`'s own dependency check only succeeds if `dbatools.library` was
  already published to `output` in an earlier loop iteration. Verified with
  `.\build.ps1 -Tasks pack` locally: failed with `dbatools.library` still
  after `dbatools` in the array (identical error, reproduced exactly),
  succeeded ("Packaged PSAzureSQLElasticJob NuGet package") once reordered.
  Kept the `ExternalModuleDependencies` entry too since it's still correct
  guidance for the real PSGallery publish step. Full Sampler suite (regular
  `build`+`test`) still passed with 443 tests.
- 2026-08-20: PR #7 merged to `main` (tagged `v0.2.0-preview0006`), so all
  the work above (Get-SqlElasticJobExecutionOutput, the CRUD audit fix, the
  README, the Format.ps1xml views, tab completion, and the dbatools.library
  packaging fix) is now on `main`. Started a new branch
  `feature/add-module-icon` for the user's `assets/PSAzureSQLElasticJob.svg`
  icon: referenced from the manifest's `IconUri` and shown at the top of
  `README.md`. The QA suite's "Changelog has been updated" test (compares
  changed files against a base ref) requires a `CHANGELOG.md` entry for
  every change, including asset-only ones - forgot it once and had to add
  it retroactively. Full Sampler suite passed with 443 tests.

## Stable capabilities

- Idempotent provisioning of the logical SQL server, job database and Elastic
  Job agent, with `-WhatIf` support.
- CRUD for Elastic Job agents, jobs, job steps, job credentials, target groups
  and targets, plus `Start-`/`Stop-SqlElasticJob`.
- Non-throwing `Get-*` commands usable in conditional logic.
- Consistent `-Strict` and `-PassThru` semantics on every `Remove-*` command.

## Open work

- Enable secret scanning and push protection in the repository settings
  (FIND-2026-004; cannot be done from a commit).
- Configure the Azure integration-test environment variables and run the live
  subscription lifecycle test.
- Retry the live environment provisioning with a globally unique logical SQL
  server name.
- Configure the `GalleryApiToken` repository secret before the first release.
- Confirm the PowerShell Gallery publish path end to end.
