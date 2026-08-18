---
status: accepted
last-verified: 2026-08-17
owner: shared
source: user clarification (2026-08-17)
---

# Decision 1: Initial scope and technology stack for PSAzureSQLElasticJob

## Context

The repository contained only a one-line `README.md`. The user asked for a
PowerShell module to manage Azure SQL Elastic Jobs, including provisioning the
Elastic Job Agent's SQL Server and database when not already available, plus
full CRUD on Elastic Job resources. Before writing any code, the user asked
for a Memory Bank only. Five clarifying questions were asked to avoid
guessing architecture.

## Decision

- **PowerShell version**: Target PowerShell 7+ only; no Windows PowerShell 5.1
  support.
- **Authentication**: Reuse the caller's existing `Az.Accounts` context
  (`Get-AzContext`); the module does not implement independent
  authentication/token logic.
- **Project scaffold**: Use the Sampler build framework (`build.ps1`,
  `RequiredModules.psd1`, Pester, GitVersion).
- **Elastic Job resource scope**: Full CRUD across the Elastic Jobs object
  model — Job Agent, Jobs, Job Steps, Job Credentials, Target Groups, and
  Schedules — in addition to create-if-missing provisioning of the
  prerequisite logical SQL Server and job database.
- **Publishing target**: PowerShell Gallery.

## Rationale

These choices were confirmed directly with the user rather than inferred, to
keep the Memory Bank's `techContext.md`/`projectbrief.md` facts evidence-based
per the Memory Bank Skill's safeguard against inferring architecture.

## Consequences

- Implementation work should scaffold via Sampler before writing cmdlets.
- Cmdlet design must assume an already-authenticated `Az` session; no
  `Connect-AzAccount`-equivalent cmdlet is needed in this module.
- CI/CD provider and exact `Az.Sql` submodule dependency remain open
  (`To confirm`) and should be resolved during implementation, not guessed.
