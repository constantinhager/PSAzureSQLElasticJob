---
status: accepted
last-verified: 2026-08-17
owner: shared
source: Pester 5.9.1 probe runs
---

# Decision 3: Move optional-parameter forwarding into a testable private function

## Context

Several Az.Sql cmdlets distinguish "parameter not supplied" from "parameter
supplied with a falsy value". `Set-AzSqlElasticJob` only changes a job's
enablement when `Enable` was actually bound, so `-Enable:$false` means "disable
this job" while omitting it means "leave the schedule alone".

The wrappers originally implemented this inline, with a `foreach` over parameter
names guarded by `$PSBoundParameters.ContainsKey(...)`, repeated in eight
functions.

Trying to unit test that behaviour exposed a Pester limitation. Two probe runs
against Pester 5.9.1 established that **`$PSBoundParameters` is empty inside both
`-ParameterFilter` and `-MockWith`**:

| Assertion | Result |
|---|---|
| `ParameterFilter { $PSBoundParameters.ContainsKey('Name') }` after supplying `Name` | fails |
| `ParameterFilter { -not $PSBoundParameters.ContainsKey('Name') }` after omitting `Name` | passes |
| `MockWith { $PSBoundParameters.ContainsKey('Name') }` after supplying `Name` | fails |

Only the parameter *variables* are bound in those scopes. Every
`-not $PSBoundParameters.ContainsKey(...)` assertion therefore passes
unconditionally and proves nothing.

## Decision

1. Extract the forwarding logic into the private function
   `Add-OptionalParameter`, and unit test it directly.
2. In mock assertions, discriminate on parameter *variables* only:
   `$null -eq $Name` for strings and nullable integers, `-not $Exclude` for
   switches. Never use `$PSBoundParameters` inside a `ParameterFilter`.
3. Accept that a mock cannot distinguish an unbound switch from one bound to
   `$false`. That distinction is covered by the `Add-OptionalParameter` tests
   instead of by an assertion that cannot observe it.

## Consequences

- The eight duplicated `foreach` loops collapse to one call each.
- The presence-versus-value behaviour now has genuine coverage.
- Several previously written assertions were vacuous and were rewritten; this is
  worth remembering when reviewing any future mock-based test in this repository.
