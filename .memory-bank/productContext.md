---
status: current
last-verified: 2026-08-17
owner: shared
source: repository evidence
---

# Product context

## Problem

Azure has no single first-party PowerShell module that both bootstraps the
Elastic Job Agent prerequisite infrastructure (logical SQL Server + job
database) and offers full CRUD over Elastic Job resources; operators must
combine `Az.Sql` cmdlets, ARM/REST calls, and manual T-SQL against the job
database.

## Users

- DBAs and DevOps engineers automating Azure SQL Elastic Job setup and
  lifecycle management via PowerShell/CI pipelines.

## Core workflows

1. Ensure the Elastic Job Agent's logical SQL Server and job database exist,
   creating them only when missing.
2. Create, read, update, and delete the Elastic Job Agent resource itself.
3. Create, read, update, and delete Jobs, Job Steps, Job Credentials, Target
   Groups, and Schedules.
4. Start/monitor job executions and view execution history (in scope vs.
   deferred: To confirm).

## Experience goals

- Idiomatic, approved-verb PowerShell cmdlets consistent with `Az.*` module
  conventions.
- Idempotent provisioning (safe to re-run).
- Works against the caller's existing `Az.Accounts` session without
  additional sign-in steps.
