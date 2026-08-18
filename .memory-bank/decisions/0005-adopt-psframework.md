---
status: accepted
last-verified: 2026-08-17
owner: shared
source: user request; psframework.instructions.md; psframework-development skill
---

# Decision 5: Adopt PSFramework, with exceptions on by default

## Context

`psframework.instructions.md` forbids adding a PSFramework dependency unless the
user asks. The user asked, which authorises the dependency and brings the module
under the rest of that instruction's rules: one logging system, `Stop-PSFFunction`
instead of raw `throw`, and `Set-PSFConfig` instead of hardcoded tunables.

## Decision

1. **Logging.** Every `Write-Verbose` becomes `Write-PSFMessage -Level Verbose`
   with a `-Tag` (`context`, `lookup`, `idempotent`, `strict`). No mixing.
2. **Flow control.** Every domain-level `throw` in a public command becomes
   `Stop-PSFFunction ... -EnableException $EnableException` followed by `return`.
3. **`-EnableException` defaults to `$true`.** This deviates from the usual
   PSFramework default of `$false`.
4. **Configuration.** `Provisioning.ServiceObjective` (`S1`) and
   `Provisioning.ServerVersion` (`12.0`) are registered with `Set-PSFConfig
   -Initialize` in `source/suffix.ps1`, which ModuleBuilder appends to the built
   `.psm1` so it runs on import. `New-SqlElasticJobEnvironment` reads them as
   parameter defaults.
5. **The two private helpers keep raw `throw`.** They are internal plumbing.
   `Get-AzResourceIfPresent` exists precisely to rethrow anything that is not a
   confirmed absence, and `Assert-AzContext` is a precondition assert; both have
   to interrupt their caller unconditionally. The public commands own the
   `-EnableException` contract.

## Rationale for the default

PSFramework normally defaults `-EnableException` to `$false`, so a failure warns
and produces no output. That fits pipeline commands where one bad item should not
abort a batch.

It fits this module badly. These commands provision and delete Azure
infrastructure, and decision 0004 exists because a failure that produced no output
was being read as "the resource is not there". Defaulting to `$false` would
reintroduce exactly that class of silent failure at the public boundary: a
`Set-SqlElasticJobAgent` against a missing agent would warn and continue, and a
script without `-WarningAction Stop` would carry on as though it had worked.

`$true` is a parameter default, not a hardcoded value, so it does not breach the
rule the skill actually states - the caller can still pass `$false` and get the
pipeline-friendly behaviour.

## Consequences

- The existing public contract is unchanged; all prior tests still pass.
- Callers who want warn-and-continue must opt in with `-EnableException $false`.
- Anyone porting patterns from this module to a conventional PSFramework module
  should expect the opposite default there.
- `Get-PSFMessage` now retrieves the module's diagnostics, and `Set-PSFConfig`
  can retune provisioning defaults without editing code.
