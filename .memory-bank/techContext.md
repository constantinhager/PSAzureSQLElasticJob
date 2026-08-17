---
status: current
last-verified: 2026-08-17
owner: active-agent
source: repository evidence
---

# Tech context

## Stack

- PowerShell 7+ (target runtime for the module and its manifest).
- Az module family for Azure calls, reusing the caller's `Az.Accounts`
  context (`Get-AzContext`); exact submodule dependency (`Az.Sql`,
  `Az.Accounts`, direct ARM REST) to be finalized at implementation time.
- Sampler build framework (`build.ps1`, `RequiredModules.psd1`) for
  scaffolding, build, and release tasks.
- Pester for unit/integration tests; GitVersion for semantic versioning.

## Environment

- Development machine: Windows (per session environment info).
- Module itself targets PowerShell 7+ cross-platform (no OS-specific code
  expected beyond what Az modules require).

## Constraints

- No Windows PowerShell 5.1 support.
- Must not implement independent authentication/token logic; rely on the
  caller already being signed in via `Az.Accounts`.
- Elastic Job Agent provisioning must be idempotent (create-if-missing, never
  destructive on re-run).
- Azure region/tier availability for Elastic Jobs and exact `Az.Sql` cmdlet
  coverage: To confirm during implementation.

## Validation

- Expected Sampler convention: `./build.ps1 -Tasks test` (Pester) and
  `./build.ps1 -Tasks build`; exact task names to confirm once the Sampler
  scaffold is created.
- PSScriptAnalyzer linting expected as part of the Sampler pipeline.
