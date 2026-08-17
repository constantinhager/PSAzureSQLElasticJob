---
status: current
last-verified: 2026-08-17
owner: active-agent
source: repository evidence
---

# Tech context

## Stack

- PowerShell 7+ (`PowerShellVersion = '7.0'`, `CompatiblePSEditions = @('Core')`).
- `Az.Accounts` (>= 2.13.0) and `Az.Sql` (>= 4.0.0) as manifest `RequiredModules`.
  The module reuses the caller's `Az.Accounts` context and never authenticates.
- Sampler 0.120.1 build framework (`build.ps1`, `build.yaml`,
  `RequiredModules.psd1`), ModuleBuilder, InvokeBuild.
- Pester **pinned to `[5.7.1, 6.0.0)`**; GitVersion for semantic versioning.
- CI: GitHub Actions, `.github/workflows/ci.yml` (build -> test -> deploy).
  Sampler ships no GitHub Actions template, so this came from the canonical
  template in the `sampler-framework` skill. Requires the `GitHubToken` and
  `GalleryApiToken` repository secrets.

## Environment

- Development machine: Windows, PowerShell 7.6.3.
- Module targets PowerShell 7+ cross-platform; no OS-specific code beyond what
  the Az modules require.

## Constraints

- No Windows PowerShell 5.1 support.
- No independent authentication logic; `Assert-AzContext` fails fast when the
  caller is not signed in.
- Provisioning is create-if-missing only. Existing resources are never
  reconfigured, and the resource group is never created.
- A "not found" lookup failure must be distinguished from an authorization
  failure; see `Test-AzResourceNotFoundError`.
- Elastic Jobs requires the job database at service tier S0 or higher; the
  module defaults to S1.

## Validation

- Build: `.\build.ps1 -ResolveDependency -Tasks build`
- Test: `.\build.ps1 -Tasks test`
- Both must be launched via the canonical detached launcher, never directly in
  the VS Code terminal.
- The detached child is the MSIX-packaged `pwsh`, which resets `PATH` to two
  entries. Restore it in the payload or the QA test's `git` call fails:
  `$env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')`
- Sampler's QA test requires one `tests/Unit/**/<FunctionName>.tests.ps1` per
  exported function; grouping several functions into one file fails the build.
- Last verified run: `.\build.ps1` -> 322 tests passed, 17 tasks, 0 errors.
