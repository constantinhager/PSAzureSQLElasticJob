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
