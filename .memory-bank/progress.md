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
- Populate `README.md` with usage examples.
- Configure the `GalleryApiToken` repository secret before the first release.
- Confirm the PowerShell Gallery publish path end to end.
