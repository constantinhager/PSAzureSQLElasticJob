---
status: local
last-verified: 2026-08-17
owner: shared
source: Substantive turns
---

# Prompt history

Log Substantive turns only.

Line format:
`YYYY-MM-DD HH:mm UTC | agent-name | one-line intent`

Trim entries older than 90 days.

2026-08-17 12:12 UTC | default | Initialized Memory Bank and captured scope/stack for PSAzureSQLElasticJob (no code written).
2026-08-17 12:20 UTC | technical-writer | Scaffolded Sampler project; implemented Elastic Job environment provisioning and agent CRUD with 105 passing tests.
2026-08-17 12:52 UTC | technical-writer | Added job/step/credential/target-group CRUD, GitHub Actions release workflow, and Add-OptionalParameter after finding Pester mock $PSBoundParameters is empty; 322 tests passing.
2026-08-17 13:22 UTC | security-reviewer | Security review of source and docs; fixed fail-open resource lookup (non-terminating errors read as absent), 326 tests passing.
2026-08-17 13:55 UTC | security-reviewer | Remediated review findings: tightened not-found classification, SHA-pinned Actions, hardened .gitignore; 332 tests passing.
2026-08-17 14:30 UTC | software-engineer | Adopted PSFramework: Write-PSFMessage logging, Stop-PSFFunction with caller-controlled -EnableException (default $true), Set-PSFConfig provisioning defaults; 337 tests passing.
2026-08-17 15:05 UTC | software-engineer | Extended PSFramework logging to every Azure mutation and lookup with resource/operation tags; 341 tests passing.
2026-08-18 12:34 UTC | default | Removed the redundant deploy-level CI permissions and documented why Sampler release tasks retain the GitHubToken secret mapping.
2026-08-18 12:34 UTC | default | Fixed a successful CI release task silently skipping when GitHubToken was unset by mapping the automatic GitHub token and granting contents write permission.
2026-08-18 13:15 UTC | software-engineer | Added opt-in Azure subscription integration coverage with isolated resource cleanup and a default-suite Integration tag exclusion.
2026-08-18 15:27 UTC | software-engineer | Fixed Azure provisioning failure handling and added PSFramework progress/error logging with regression coverage.
2026-08-18 15:50 UTC | software-engineer | Added caller-visible PSFramework environment reuse and creation summaries.
2026-08-18 16:02 UTC | software-engineer | Promoted ordinary PSFramework lifecycle and existence messages to Output with a regression guard.
2026-08-18 16:06 UTC | software-engineer | Replaced raw Azure not-found messages with a concise provisioning-oriented absent-resource status.
2026-08-18 16:14 UTC | software-engineer | Removed the redundant nested agent lookup that repeated Azure context status in environment checks.
