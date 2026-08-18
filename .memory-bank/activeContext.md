---
status: current
last-verified: 2026-08-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

PSFramework adopted across the module: `Write-PSFMessage` logging,
`Stop-PSFFunction` flow control with a caller-controlled `-EnableException`, and
`Set-PSFConfig` provisioning defaults. Logging now covers every Azure mutation
and lookup, tagged by resource and operation. 341 tests passing.

The CI workflow now centralizes its permissions at the workflow level. The
deploy job inherits those permissions and retains the `GitHubToken` secret
mapping required by Sampler's release and changelog tasks.

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

## Next step

Enable secret scanning and push protection in the repository settings, then add
integration tests against a real subscription and populate `README.md`.
