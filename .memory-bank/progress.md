---
status: current
last-verified: 2026-08-17
owner: active-agent
source: repository evidence
---

# Progress

## Current status

Feature-complete for the agreed CRUD scope. 25 public commands, 322 passing
unit tests, green `build.ps1`. Not yet released or integration tested.

## Recent milestones

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
- Populate `README.md` with usage examples.
- Configure the `GalleryApiToken` repository secret before the first release.
- Confirm the PowerShell Gallery publish path end to end.
