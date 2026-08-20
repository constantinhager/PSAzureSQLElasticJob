# Changelog for PSAzureSQLElasticJob

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Opt-in Azure subscription integration tests that validate the Elastic Job
  lifecycle while preserving the supplied resource group, server and database.
- Sampler-based project scaffold with GitVersion, Pester 5 and GitHub Actions.
- `New-SqlElasticJobEnvironment` to provision the logical SQL server, job
  database and Elastic Job agent, creating only the parts that are missing.
- `New-SqlElasticJobEnvironment` accepts `-UseUserAssignedManagedIdentity` and
  `-UserAssignedIdentityId` to assign an existing user-assigned managed
  identity to the Elastic Job agent, idempotently.
- `New-SqlElasticJobUserAssignedIdentity` to idempotently create a user-assigned
  managed identity, and a `-CreateUserAssignedManagedIdentity` (with
  `-UserAssignedIdentityName`) parameter set on `New-SqlElasticJobEnvironment`
  that creates the identity when missing and assigns it to the Elastic Job
  agent in one call.
- `Test-SqlElasticJobEnvironment` to report which parts of an environment exist
  without changing anything.
- `Get-SqlElasticJobAgent`, `New-SqlElasticJobAgent`, `Set-SqlElasticJobAgent`
  and `Remove-SqlElasticJobAgent` for Elastic Job agent CRUD.
- Job CRUD: `Get-SqlElasticJob`, `New-SqlElasticJob`, `Set-SqlElasticJob`,
  `Remove-SqlElasticJob`, plus `Start-SqlElasticJob` and `Stop-SqlElasticJob`.
  Schedules are set through the job itself with `-RunOnce` or
  `-IntervalType`/`-IntervalCount`, matching the Elastic Jobs object model.
- Job step CRUD: `Get-SqlElasticJobStep`, `Add-SqlElasticJobStep`,
  `Set-SqlElasticJobStep` and `Remove-SqlElasticJobStep`.
- Job credential CRUD: `Get-SqlElasticJobCredential`,
  `New-SqlElasticJobCredential`, `Set-SqlElasticJobCredential` and
  `Remove-SqlElasticJobCredential`.
- Target group CRUD: `Get-SqlElasticJobTargetGroup`,
  `New-SqlElasticJobTargetGroup` and `Remove-SqlElasticJobTargetGroup`, plus
  `Add-SqlElasticJobTarget` and `Remove-SqlElasticJobTarget`.
- GitHub Actions workflow `.github/workflows/ci.yml` covering build, test and
  release to GitHub and the PowerShell Gallery.
- GitHub issue templates under `.github/ISSUE_TEMPLATE/`.
- MIT license file.

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
