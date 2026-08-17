---
status: current
last-verified: 2026-08-17
owner: security-reviewer
source: assessment records
---

# Assessment log

## 2026-08-17 - Documentation and source security review

**Scope**: `source/` (25 public, 4 private functions), `.github/workflows/ci.yml`,
`.github/ISSUE_TEMPLATE/`, comment-based help, `CHANGELOG.md`, `.gitignore`,
Memory Bank decision records.

**Verdict**: CONDITIONAL. One High finding was fixed and verified during the
review; the remaining findings are Medium and below and do not block use.

**Findings**

| ID            | Severity | Finding                                                                                                                                                                                                                                                                           | State                         |
| ------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- |
| FIND-2026-001 | High     | `Get-AzResourceIfPresent` discarded the error stream with `2>$null`, so a non-terminating authorization or throttling error returned `$null` and was read as "resource absent". Provisioning would then attempt to create an existing resource and the real error never surfaced. | Fixed, regression tests added |
| FIND-2026-002 | Medium   | `Test-AzResourceNotFoundError` matches free-text substrings (`does not exist`, `was not found`). Those strings can appear in non-404 failures, and ARM also returns 404 for resources hidden by RBAC.                                                                             | Accepted, documented          |
| FIND-2026-003 | Medium   | Workflow actions are pinned to mutable major tags while the deploy job holds `contents: write`, `pull-requests: write`, `GitHubToken` and `GalleryApiToken`.                                                                                                                      | Open recommendation           |
| FIND-2026-004 | Low      | Secret scanning and push protection are not enabled on the repository.                                                                                                                                                                                                            | Open recommendation           |
| FIND-2026-005 | Low      | `.gitignore` has no defensive secret patterns (`*.env`, `*.pfx`, `*.key`, `*.publishsettings`).                                                                                                                                                                                   | Open recommendation           |
| FIND-2026-006 | Low      | `Assert-AzContext` writes the subscription id to the verbose stream.                                                                                                                                                                                                              | Accepted                      |
| FIND-2026-007 | Info     | Unit tests use `ConvertTo-SecureString -AsPlainText -Force` with obvious dummy values, confined to `tests/`.                                                                                                                                                                      | Accepted                      |

**Evidence**

- PSScriptAnalyzer over `source/`: zero active findings; four suppressions, each
  scoped to a named parameter with a justification, all genuine false positives
  on credential *names*.
- Runtime probe before the fix: a non-terminating authorization error returned
  `$null` (reported absent). After the fix, terminating and non-terminating
  authorization and throttling errors all rethrow, not-found still returns
  `$null`, and successful lookups are unchanged.
- `./build.ps1`: 326 tests passed, 17 tasks, 0 errors.

## 2026-08-17 - Remediation pass

**Verdict**: PASS. Every finding that can be fixed from the codebase is fixed and
verified; only the repository setting remains.

- FIND-2026-002: the classifier now runs strongest signal first. A permission,
  authentication, quota or throttling signal returns false outright; an exposed
  HTTP status settles the question on its own; free text is consulted only when
  neither is available. Covered by six new tests, including ARM's
  "was not found or you do not have access" phrasing and a 403 whose message
  says the resource does not exist.
- FIND-2026-003: all six action references pinned to commit SHAs with the version
  in a trailing comment.
- FIND-2026-005: credential-material patterns added to `.gitignore`.
- FIND-2026-004 stays open. Secret scanning and push protection are repository
  settings under Settings > Code security; they cannot be enabled from a commit.

**Evidence**: `./build.ps1` -> 332 tests passed, 17 tasks, 0 errors.

**Positive controls confirmed**

- No `Invoke-Expression`, no `[scriptblock]::Create` on user input, and no
  plaintext credential extraction in module source.
- Credentials are `PSCredential` throughout and are never logged.
- Workflow uses `pull_request` rather than `pull_request_target`, so fork pull
  requests never see repository secrets.
- Workflow default is `permissions: contents: read`; the deploy job elevates
  narrowly and is fenced to the upstream owner and to main or `v*` tags.
