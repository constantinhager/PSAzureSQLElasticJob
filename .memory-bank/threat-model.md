---
status: current
last-verified: 2026-08-17
owner: security-reviewer
source: source review, PSScriptAnalyzer sweep, runtime probes
---

# Threat model

## Assets

- The caller's Azure credentials, held only as an `Az.Accounts` context that this
  module reads and never persists.
- Job credentials (`PSCredential`) passed to `New-`/`Set-SqlElasticJobCredential`
  and stored by Azure as database-scoped credentials.
- The SQL administrator credential for a newly created logical server.
- Release secrets `GitHubToken` and `GalleryApiToken`, held only as GitHub
  Actions repository secrets.

## Trust boundaries

1. Caller session -> Azure ARM, via `Az.Sql`. The module never constructs its own
   HTTP requests or tokens.
2. Caller -> target databases, via T-SQL supplied as `-CommandText` on a job step.
   That text is executed by Azure against every target in the group.
3. GitHub Actions runner -> PowerShell Gallery and the GitHub API, in the deploy
   job only.

## Attack surface

- **T-SQL in job steps.** `-CommandText` is arbitrary T-SQL by design; the module
  passes it through unmodified. Anyone who can create or modify a job step can run
  that SQL against every target database under the job credential. This is the
  feature, not a flaw, but it makes write access to the job agent equivalent to
  write access to every target. Least-privilege job credentials matter more than
  input validation here.
- **Credential names.** `CredentialName` / `RefreshCredentialName` are
  identifiers, not secrets. PSScriptAnalyzer flags them as passwords; the four
  suppressions are narrowly scoped to those parameter names.
- **Error classification.** Deciding "absent" versus "cannot read" governs whether
  provisioning creates a resource. Getting it wrong is a fail-open condition; see
  `decisions/0004-fail-closed-resource-lookup.md`.

## Non-applicable

No LLM, agent, MCP server, or RAG store is in scope, so the OWASP Top 10 for LLM
Applications and the lethal-trifecta test do not apply to this repository.
