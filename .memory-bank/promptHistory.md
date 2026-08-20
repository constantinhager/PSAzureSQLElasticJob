---
status: local
last-verified: 2026-08-17
owner: shared
source: Substantive turns
---

# Prompt history

Log Substantive turns only.

Line format:
`YYYY-MM-DD HH:mm UTC | agent-name | one-line intent`

Trim entries older than 90 days.

2026-08-20 06:15 UTC | default | Added idempotent user-assigned managed identity assignment to New-SqlElasticJobEnvironment
2026-08-20 08:27 UTC | default | Renamed branch to feature/*; moved managed identity assignment from SQL server to Elastic Job agent
2026-08-20 08:45 UTC | default | Added New-SqlElasticJobUserAssignedIdentity and wired -CreateUserAssignedManagedIdentity into New-SqlElasticJobEnvironment
2026-08-20 09:10 UTC | default | Fixed live-run bugs: reverted accidental mandatory ServerAdministratorCredential; hardened identity creation against empty resource IDs
2026-08-20 09:25 UTC | default | Made ServerAdministratorCredential prompt interactively; added Microsoft.ManagedIdentity resource-provider auto-registration
2026-08-20 09:32 UTC | default | Added Identity property to New-SqlElasticJobEnvironment output object
2026-08-20 09:38 UTC | default | Fixed AssignedIdentity to reflect current agent identity state instead of only this-run changes
2026-08-20 10:15 UTC | default | Renamed Add-/Remove-SqlElasticJobTarget's DatabaseName/ElasticPoolName/ShardMapName to TargetDatabaseName/TargetElasticPoolName/TargetShardMapName
2026-08-20 10:52 UTC | default | Added Grant-SqlElasticJobTargetDatabaseAccess (dbatools-based T-SQL data-plane command) to create a contained DB user for a managed identity and grant a database role
2026-08-20 11:01 UTC | default | Renamed Grant-SqlElasticJobTargetDatabaseAccess's ServerName/DatabaseName to TargetServerName/TargetDatabaseName for naming consistency
2026-08-20 11:12 UTC | default | Fixed Grant-SqlElasticJobTargetDatabaseAccess double-confirm/double-output bug; consolidated to one ShouldProcess and one summary object
2026-08-20 13:53 UTC | default | Fixed Add-SqlElasticJobStep double context message and swallowed Az error; flagged same pattern in ~14 other CRUD commands as open work
2026-08-20 14:21 UTC | default | Added Azure's WithOutputDb parameter set to Add-SqlElasticJobStep (OutputDatabaseObject/OutputTableName/OutputCredentialName/OutputSchemaName)
2026-08-20 14:42 UTC | default | Added Get-SqlElasticJobExecutionOutput to retrieve output-table rows for a job execution via internal_execution_id
2026-08-20 15:15 UTC | default | Fixed Get-SqlElasticJobExecutionOutput correlation: internal_execution_id doesn't match JobExecutionId; switched to explicit $(job_execution_id) column
2026-08-20 15:50 UTC | default | Fixed duplicate Assert-AzContext / missing -ErrorAction Stop across remaining ~14 CRUD commands
2026-08-20 16:00 UTC | default | Populated README.md with requirements, quick start and command reference table
2026-08-20 16:10 UTC | default | Added Format.ps1xml table views for the 3 PSCustomObject-returning commands (Environment*/TargetDatabaseAccess results)

2026-08-17 12:12 UTC | default | Initialized Memory Bank and captured scope/stack for PSAzureSQLElasticJob (no code written).
2026-08-17 12:20 UTC | technical-writer | Scaffolded Sampler project; implemented Elastic Job environment provisioning and agent CRUD with 105 passing tests.
2026-08-17 12:52 UTC | technical-writer | Added job/step/credential/target-group CRUD, GitHub Actions release workflow, and Add-OptionalParameter after finding Pester mock $PSBoundParameters is empty; 322 tests passing.
2026-08-17 13:22 UTC | security-reviewer | Security review of source and docs; fixed fail-open resource lookup (non-terminating errors read as absent), 326 tests passing.
2026-08-17 13:55 UTC | security-reviewer | Remediated review findings: tightened not-found classification, SHA-pinned Actions, hardened .gitignore; 332 tests passing.
2026-08-17 14:30 UTC | software-engineer | Adopted PSFramework: Write-PSFMessage logging, Stop-PSFFunction with caller-controlled -EnableException (default $true), Set-PSFConfig provisioning defaults; 337 tests passing.
2026-08-17 15:05 UTC | software-engineer | Extended PSFramework logging to every Azure mutation and lookup with resource/operation tags; 341 tests passing.
2026-08-18 12:34 UTC | default | Removed the redundant deploy-level CI permissions and documented why Sampler release tasks retain the GitHubToken secret mapping.
2026-08-18 12:34 UTC | default | Fixed a successful CI release task silently skipping when GitHubToken was unset by mapping the automatic GitHub token and granting contents write permission.
2026-08-18 13:15 UTC | software-engineer | Added opt-in Azure subscription integration coverage with isolated resource cleanup and a default-suite Integration tag exclusion.
2026-08-18 15:27 UTC | software-engineer | Fixed Azure provisioning failure handling and added PSFramework progress/error logging with regression coverage.
2026-08-18 15:50 UTC | software-engineer | Added caller-visible PSFramework environment reuse and creation summaries.
2026-08-18 16:02 UTC | software-engineer | Promoted ordinary PSFramework lifecycle and existence messages to Output with a regression guard.
2026-08-18 16:06 UTC | software-engineer | Replaced raw Azure not-found messages with a concise provisioning-oriented absent-resource status.
2026-08-18 16:14 UTC | software-engineer | Removed the redundant nested agent lookup that repeated Azure context status in environment checks.
