---
status: accepted
last-verified: 2026-08-17
owner: shared
source: runtime probe against the built module
---

# Decision 4: Resource lookups fail closed

## Context

`Get-AzResourceIfPresent` originally ran the lookup as `& $ScriptBlock 2>$null`.
That redirect discards the error stream, so any **non-terminating** error never
reached `Test-AzResourceNotFoundError`; the function simply returned `$null`.

`$null` means "resource absent" to every caller. A probe against the built module
confirmed the consequence:

| Lookup outcome | Before | After |
|---|---|---|
| Terminating authorization error | rethrown | rethrown |
| Non-terminating authorization error | **`$null` - reported absent** | rethrown |
| Non-terminating throttling error | **`$null` - reported absent** | rethrown |
| Non-terminating not-found error | `$null` | `$null` |
| Success | value | value |

`New-SqlElasticJobEnvironment` would therefore conclude that a server it merely
lacked permission to read did not exist, and would try to create it. The operator
would see a name-conflict error instead of the permission problem. This is exactly
the failure mode decision 0002 says the classifier prevents, defeated by the
redirect placed alongside it.

Setting `$ErrorActionPreference` inside the helper does not fix this: a script
block resolves unqualified variables through the scope where it was *defined*, not
the scope that invokes it, so the preference set in the helper is invisible to the
caller's script block.

## Decision

Merge the error stream into the output with `2>&1`, pull out the first
`ErrorRecord`, and route it through `Test-AzResourceNotFoundError`. Terminating
errors keep the existing `catch` path. Both paths now fail closed: anything that
is not positively identified as "not found" is rethrown.

## Consequences

- A resource the caller cannot read is no longer indistinguishable from one that
  does not exist.
- Callers must tolerate the helper throwing for reasons other than absence; every
  public command already lets those errors propagate.
- Four regression tests cover the non-terminating paths, which had no coverage
  because the original tests only exercised `throw`.
