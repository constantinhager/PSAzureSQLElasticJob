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

    .PARAMETER ScriptBlock
        The lookup to run, for example { Get-AzSqlServer -ResourceGroupName $rg -ServerName $name }.

    .OUTPUTS
        The object returned by the lookup, or $null when it does not exist.

    .EXAMPLE
        Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobAgent @params }
#>
function Get-AzResourceIfPresent
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )

    try
    {
        return & $ScriptBlock 2>$null
    }
    catch
    {
        if (Test-AzResourceNotFoundError -ErrorRecord $_)
        {
            Write-Verbose -Message ('Resource not found: {0}' -f $_.Exception.Message)

            return $null
        }

        throw
    }
}
