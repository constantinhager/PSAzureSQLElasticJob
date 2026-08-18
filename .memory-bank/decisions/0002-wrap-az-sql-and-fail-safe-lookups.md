---
status: accepted
last-verified: 2026-08-17
owner: shared
source: Az.Sql 7.0.0 cmdlet inventory; Pester 6.1.0 QA test failure
---

# Decision 2: Wrap Az.Sql, and never let a lookup failure masquerade as absence

## Context

Before writing cmdlets, the exported command surface of `Az.Sql` 7.0.0 was
inspected. It already provides 29 `*ElasticJob*` cmdlets covering the entire
object model: agent, job, job step, job credential, target group, target,
private endpoint, and the execution/start/stop verbs.

That removes the original assumption that this module would have to talk to the
job database or ARM directly.

## Decision

1. **Wrap `Az.Sql` rather than reimplement it.** The gap this module fills is
   (a) idempotent, one-call provisioning of the server + job database + agent,
   and (b) wrappers whose `Get-*` returns `$null` instead of throwing, so they
   compose in conditional logic.
2. **Use the `SqlElasticJob*` noun family** (`Get-SqlElasticJobAgent`), which
   cannot collide with `Az.Sql`'s `AzSqlElasticJob*` names when both are loaded.
3. **Classify lookup failures explicitly.** `Test-AzResourceNotFoundError` is the
   only place that decides whether an error means "absent". `Get-AzResourceIfPresent`
   rethrows everything else.
4. **Never create the resource group,** and never reconfigure an existing server
   or database. Provisioning creates what is missing; it does not converge.
5. **Pin Pester to `[5.7.1, 6.0.0)`.** With `latest` resolving to 6.1.0,
   Sampler's own `tests/QA/module.tests.ps1` aborts the run with a labelled
   break/continue error (pester/pester#2669).

## Rationale

Point 3 is the important one. The obvious implementation - `try { Get-... } catch { $null }` -
would turn an authorization failure, a throttling response, or a transient
network error into "this resource does not exist". `New-SqlElasticJobEnvironment`
would then try to create a server that is already there, and the caller would get
a confusing name-conflict error instead of the real permission problem.

## Consequences

- `Az.Sql` is a hard runtime dependency, declared in the manifest.
- Callers who need behaviour this module does not wrap can drop down to `Az.Sql`
  directly; the two command sets coexist.
- The not-found classifier matches on HTTP 404, error ids, and message text. The
  message matching is inherently brittle and should be revisited if Az changes
  its error shapes.
