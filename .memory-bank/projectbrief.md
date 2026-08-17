---
status: current
last-verified: 2026-08-17
owner: shared
source: repository evidence
---

# Project brief

## Purpose

Build a PowerShell module, `PSAzureSQLElasticJob`, that manages Azure SQL
Elastic Jobs: it provisions the prerequisite Elastic Job Agent infrastructure
(logical SQL Server and job database) when not already present, and provides
full CRUD for Elastic Job resources.

## Scope

- In scope:
  - Idempotent provisioning: create the Elastic Job Agent's logical SQL Server
    and job database only if they do not already exist.
  - Full CRUD cmdlets for the Elastic Jobs object model: Job Agent, Jobs, Job
    Steps, Job Credentials, Target Groups, and Schedules.
  - PowerShell 7+ only (no Windows PowerShell 5.1 support).
  - Authenticate by reusing the caller's existing `Az.Accounts` context
    (`Get-AzContext`); no independent auth/token logic.
  - Sampler-based build/test scaffold (`build.ps1`, `RequiredModules.psd1`,
    Pester tests, GitVersion).
  - Eventual publication to the PowerShell Gallery.
- Out of scope:
  - Non-Azure-SQL elastic scenarios.
  - GUI/portal tooling.
  - Windows PowerShell 5.1 compatibility.
  - CI/CD pipeline specifics beyond "Sampler + PSGallery publish" (exact
    workflow/provider: To confirm).

## Stakeholders

- Repository owner: constantinhager (GitHub).
- Additional stakeholders: To confirm.

## Acceptance criteria

1. Running the module's provisioning cmdlet(s) against a subscription without
   an existing Elastic Job Agent server/database creates them; running again
   is a no-op (idempotent).
2. CRUD cmdlets exist for Job Agent, Jobs, Job Steps, Job Credentials, Target
   Groups, and Schedules, following approved PowerShell verb-noun naming.
3. The module targets PowerShell 7+ and authenticates via the caller's
   existing `Az.Accounts` context.
4. The project builds and tests via the Sampler framework (Pester tests pass).
5. The module is structured to be publishable to the PowerShell Gallery.
