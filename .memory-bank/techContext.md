---
status: current
last-verified: 2026-08-17
owner: active-agent
source: repository evidence
---

# Tech context

## Stack

- PowerShell 7+ (`PowerShellVersion = '7.0'`, `CompatiblePSEditions = @('Core')`).
- `Az.Accounts` (>= 2.13.0), `Az.Sql` (>= 4.0.0), `Az.ManagedServiceIdentity`
  (>= 2.0.0), `Az.Resources` (>= 6.0.0) and `dbatools` (>= 2.1.0) as manifest
  `RequiredModules`. The module reuses the caller's `Az.Accounts` context and
  never authenticates. `dbatools` is the sole data-plane (T-SQL) dependency;
  everything else is ARM control-plane.
- `PSFramework` (>= 1.9.310) for logging (`Write-PSFMessage`), flow control
  (`Stop-PSFFunction`) and configuration (`Set-PSFConfig`).
- Sampler 0.120.1 build framework (`build.ps1`, `build.yaml`,
  `RequiredModules.psd1`), ModuleBuilder, InvokeBuild.
- Pester **pinned to `[5.7.1, 6.0.0)`**; GitVersion for semantic versioning.
- CI: GitHub Actions, `.github/workflows/ci.yml` (build -> test -> deploy).
  Sampler ships no GitHub Actions template, so this came from the canonical
  template in the `sampler-framework` skill. Uses GitHub Actions' automatic
  token for releases and changelog pull requests; requires only the
  `GalleryApiToken` repository secret.

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
- `.\build.ps1 -Tasks test` alone does **not** rebuild the module; it imports
  whatever is already in `output/module`. After editing `source/`, run the
  default workflow (`.\build.ps1` with no `-Tasks`, which runs `build` then
  `test`) or explicitly `-Tasks build,test`, otherwise source changes appear
  as `ParameterBindingException`/stale-behavior failures against the old
  build.
- Last verified run: `.\build.ps1` -> 341 tests passed, 17 tasks, 0 errors.
- Logging conformance is checkable: 64 `Write-PSFMessage` calls, all with an
  explicit `-Level`, and zero `Write-Verbose`/`Warning`/`Host`/`Error` calls in
  `source/`.
- `source/suffix.ps1` is appended to the built `.psm1` by ModuleBuilder
  (`suffix: suffix.ps1` in `build.yaml`) and is the only place module code runs
  at import time. The `Set-PSFConfig -Initialize` calls live there.
- Do not run `-ResolveDependency` from a session that has imported
  `PSScriptAnalyzer` from `output/RequiredModules`: the loaded assembly locks the
  folder and dependency resolution fails trying to replace it.
