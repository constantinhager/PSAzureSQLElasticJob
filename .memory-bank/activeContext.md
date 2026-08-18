---
status: current
last-verified: 2026-08-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

Opt-in integration coverage now exercises a real Azure SQL Elastic Job
lifecycle. It requires a caller-supplied resource group, logical SQL server and
S0-or-higher job database, creates uniquely named Elastic Job resources, and
removes only those test resources in reverse dependency order. The default
Sampler suite excludes the `Integration` tag and remains credential-free.

The CI workflow now centralizes its permissions at the workflow level. The
deploy job inherits those permissions and maps GitHub Actions' automatic token
to the `GitHubToken` environment variable required by Sampler's release and
changelog tasks.

## Evidence

- `Az.Sql` 7.0.0 exposes the whole Elastic Jobs object model, so this module
  wraps it rather than reimplementing it - see
  `decisions/0002-wrap-az-sql-and-fail-safe-lookups.md`.
- Schedules are not a separate resource. They are parameters on
  `New-`/`Set-AzSqlElasticJob` (`-RunOnce`, `-IntervalType`, `-IntervalCount`,
  `-StartTime`, `-EndTime`, `-Enable`), verified from the cmdlet parameter sets.
- `Add-AzSqlElasticJobTarget` uses `-AgentServerName` for the agent's server and
  `-ServerName` for the target server. The wrapper exposes these as
  `-ServerName` and `-TargetServerName` for consistency with the rest of the
  module.
- Sampler ships **no** GitHub Actions workflow templates - only
  `azure-pipelines.yml.template`, `appveyor.yml` and GitHub *issue* templates.
  `.github/workflows/ci.yml` therefore comes from the canonical template in the
  `sampler-framework` skill, adapted to this module.
- Pester 5 does not populate `$PSBoundParameters` inside `ParameterFilter` or
  `MockWith`; see `decisions/0003-testable-optional-parameter-forwarding.md`.
- `tests/Integration/ElasticJobLifecycle.tests.ps1` runs only with the
  `Integration` tag and validates a caller-provided server/database before
  provisioning its unique agent, job, target group, target and step.

## Next step

Enable secret scanning and push protection in the repository settings, configure
the three integration-test environment variables, then run the live lifecycle
test and populate `README.md`.
