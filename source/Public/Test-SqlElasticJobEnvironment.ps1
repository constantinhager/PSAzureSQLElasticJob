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

    .EXAMPLE
        Test-SqlElasticJobEnvironment -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -DatabaseName 'jobdb' -AgentName 'agent01'
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

            $agent = Get-SqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $AgentName
        }

        [PSCustomObject]@{
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
