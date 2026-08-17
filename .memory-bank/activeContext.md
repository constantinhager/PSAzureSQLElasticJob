---
status: current
last-verified: 2026-08-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

Memory Bank populated with initial project scope for the `PSAzureSQLElasticJob`
module. No module code has been written yet (user explicitly requested
memory bank only, no code, for this turn).

## Evidence

- Repository currently contains only `README.md` (one-line description).
- Scope and stack confirmed via clarifying questions with the user on
  2026-08-17 (see `decisions/0001-initial-scope-and-stack.md`): PowerShell 7+
  only, `Az.Accounts` context reuse for auth, Sampler build scaffold, full
  Elastic Jobs object-model CRUD (Jobs, Job Steps, Job Credentials, Target
  Groups, Schedules) plus Job Agent, PowerShell Gallery as publish target.

## Next step

When the user requests implementation, scaffold the Sampler-based module
structure (`build.ps1`, `RequiredModules.psd1`, `source/Public`,
`source/Private`, Pester tests) per the `sampler-framework` skill, then design
the cmdlet list before writing cmdlet bodies.
