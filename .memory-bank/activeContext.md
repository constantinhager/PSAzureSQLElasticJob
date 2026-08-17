---
status: current
last-verified: 2026-08-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

First implementation slice of the `PSAzureSQLElasticJob` module: Sampler scaffold
plus idempotent environment provisioning and Elastic Job **agent** CRUD, with unit
tests. Job, Job Step, Job Credential and Target Group CRUD are not implemented yet.

## Evidence

- Sampler `SimpleModule` scaffold generated and merged into the repository
  (`build.ps1`, `build.yaml`, `RequiredModules.psd1`, `GitVersion.yml`,
  `.github/`, `.vscode/`, `source/`, `tests/`). The existing `README.md` was
  preserved and the placeholder sample functions were not copied.
- `Az.Sql` 7.0.0 already exposes the complete Elastic Jobs object model
  (29 `*ElasticJob*` cmdlets, verified via `ExportedCommands`). This module's
  value is therefore idempotent provisioning and consistent, non-throwing
  wrappers - not reimplementing the API.
- Implemented: `Assert-AzContext`, `Get-AzResourceIfPresent`,
  `Test-AzResourceNotFoundError` (private); `New-SqlElasticJobEnvironment`,
  `Test-SqlElasticJobEnvironment`, and `Get`/`New`/`Set`/`Remove-SqlElasticJobAgent`
  (public).
- Pester had to be pinned to 5.x. `Pester = 'latest'` resolved to 6.1.0, under
  which Sampler's own `tests/QA/module.tests.ps1` aborts with a labelled
  break/continue error (pester/pester#2669).

## Next step

Implement the remaining CRUD surface - Job, Job Step, Job Credential, Target Group
and Target - following the same wrapper pattern, then add integration tests.
