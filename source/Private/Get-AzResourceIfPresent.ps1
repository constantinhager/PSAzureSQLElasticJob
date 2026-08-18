<#
    .SYNOPSIS
        Runs an Az lookup and returns $null when the resource does not exist.

    .DESCRIPTION
        Most Az.Sql Get-* cmdlets throw instead of returning $null when a resource
        is absent, which makes create-if-missing logic awkward. This helper runs the
        supplied lookup and converts only a genuine "not found" failure into $null.

        Any other failure - authentication, authorization, throttling, transient
        network errors - is rethrown. Swallowing those would make a resource the
        caller simply cannot see look like a resource that does not exist, and the
        caller would then try to create something that is already there.

        Rethrowing is the contract, so this helper does not call Stop-PSFFunction.
        Its callers are public commands that own the -EnableException decision.

    .PARAMETER ScriptBlock
        The lookup to run, for example { Get-AzSqlServer -ResourceGroupName $rg -ServerName $name }.

    .OUTPUTS
        The object returned by the lookup, or $null when it does not exist.

    .EXAMPLE
        Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobAgent @params }
#>
function Get-AzResourceIfPresent {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )

    try {
        # Az cmdlets report failures both ways. Merging the error stream into the
        # output keeps non-terminating errors classifiable instead of discarding
        # them, which would make an unreadable resource look like an absent one.
        $output = & $ScriptBlock 2>&1

        $errorRecord = @($output).Where({ $_ -is [System.Management.Automation.ErrorRecord] }, 'First')

        if ($errorRecord.Count -gt 0) {
            if (Test-AzResourceNotFoundError -ErrorRecord $errorRecord[0]) {
                Write-PSFMessage -Level Output -Message ('Resource not found: {0}' -f $errorRecord[0].Exception.Message) -Tag 'lookup'

                return $null
            }

            throw $errorRecord[0]
        }

        return $output
    } catch {
        if (Test-AzResourceNotFoundError -ErrorRecord $_) {
            Write-PSFMessage -Level Output -Message ('Resource not found: {0}' -f $_.Exception.Message) -Tag 'lookup'

            return $null
        }

        throw
    }
}
