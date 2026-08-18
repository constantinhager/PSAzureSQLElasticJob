# Azure integration tests

`ElasticJobLifecycle.tests.ps1` exercises the module against an existing Azure
SQL Elastic Job environment. It creates uniquely named Elastic Job resources
and removes only those resources when the test ends. It never creates or
removes the resource group, logical SQL server, or job database.

Set these non-secret environment variables before running the tagged test:

```powershell
$env:PSAZURESQLELASTICJOB_TEST_RESOURCE_GROUP = 'rg-elastic-jobs-test'
$env:PSAZURESQLELASTICJOB_TEST_SERVER = 'sql-elastic-jobs-test'
$env:PSAZURESQLELASTICJOB_TEST_DATABASE = 'ElasticJobs'
```

The signed-in identity needs permission to create and remove Elastic Job agents,
jobs, steps, target groups, and targets in that environment. The job database
must be at least S0.

The default Sampler suite excludes the `Integration` tag. Build the module,
then run the tagged suite through the repository's detached PowerShell test
launcher:

```powershell
$runId = [guid]::NewGuid().ToString('N')
$logPath = Join-Path $env:TEMP "pester-integration-$runId.log"
$payload = @"
Set-Location -LiteralPath '$((Get-Location).Path.Replace("'", "''"))'
`$ErrorActionPreference = 'Stop'
& .\build.ps1 -Tasks build
Invoke-Pester -Path .\tests\Integration -Tag Integration -Output Detailed
"@
$encodedPayload = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($payload))
& (Join-Path $HOME '.copilot/skills/long-running-job-monitor/scripts/Start-DetachedPowerShell.ps1') -EncodedCommand $encodedPayload
```
