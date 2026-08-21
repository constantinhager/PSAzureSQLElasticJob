<#
    .SYNOPSIS
        Reports which parts of an Elastic Job environment already exist.

    .DESCRIPTION
        Inspects the logical SQL server, the job database and the Elastic Job agent
        that together make up an Elastic Job environment, and reports the presence
        of each one without changing anything.

        Use this to preview what New-SqlElasticJobEnvironment would create.

    .PARAMETER ResourceGroupName
        The resource group that contains, or will contain, the environment.

    .PARAMETER ServerName
        The logical SQL server hosting the job database and agent.

    .PARAMETER DatabaseName
        The job database backing the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent name.

    .OUTPUTS
        PSCustomObject with ServerExists, DatabaseExists, AgentExists and IsComplete.
        Typed as PSAzureSQLElasticJob.EnvironmentStatus, which has a custom
        table format view showing a compact summary.

    .EXAMPLE
        Test-SqlElasticJobEnvironment -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -DatabaseName 'jobdb' -AgentName 'agent01'
    .LINK
        https://github.com/constantinhager/PSAzureSQLElasticJob/blob/main/source/Public/Test-SqlElasticJobEnvironment.ps1
#>
function Test-SqlElasticJobEnvironment
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ResourceGroupName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AgentName
    )

    process
    {
        $null = Assert-AzContext

        $server = Get-AzResourceIfPresent -ScriptBlock {
            Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName
        }

        $database = $null
        $agent = $null

        # A database or agent lookup against a missing server reports the server as
        # missing, which would be misleading, so only probe deeper once it exists.
        if ($null -ne $server)
        {
            $database = Get-AzResourceIfPresent -ScriptBlock {
                Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
            }

            $agent = Get-AzResourceIfPresent -ScriptBlock {
                Get-AzSqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $AgentName
            }
        }

        Write-PSFMessage -Level Output -Message ('Environment check for agent ''{0}'': server {1}, database {2}, agent {3}.' -f
            $AgentName,
            $(if ($null -ne $server) { 'present' } else { 'absent' }),
            $(if ($null -ne $database) { 'present' } else { 'absent' }),
            $(if ($null -ne $agent) { 'present' } else { 'absent' })) -Tag 'environment', 'lookup'

        [PSCustomObject]@{
            PSTypeName        = 'PSAzureSQLElasticJob.EnvironmentStatus'
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            DatabaseName      = $DatabaseName
            AgentName         = $AgentName
            ServerExists      = $null -ne $server
            DatabaseExists    = $null -ne $database
            AgentExists       = $null -ne $agent
            IsComplete        = ($null -ne $server) -and ($null -ne $database) -and ($null -ne $agent)
        }
    }
}
