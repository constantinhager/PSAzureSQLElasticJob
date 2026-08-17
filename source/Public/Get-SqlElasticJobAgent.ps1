<#
    .SYNOPSIS
        Gets an Azure SQL Elastic Job agent.

    .DESCRIPTION
        Returns the Elastic Job agent hosted on the specified logical SQL server.
        Unlike Get-AzSqlElasticJobAgent, this command returns $null instead of
        throwing when the agent does not exist, which makes it usable in
        create-if-missing logic and in conditional pipelines.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER Name
        The Elastic Job agent name. When omitted, all agents on the server are returned.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobAgentModel

    .EXAMPLE
        Get-SqlElasticJobAgent -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -Name 'agent01'

    .EXAMPLE
        Get-SqlElasticJobAgent -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs'

        Returns every Elastic Job agent on the server.
#>
function Get-SqlElasticJobAgent
{
    [CmdletBinding()]
    [OutputType([System.Object])]
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('AgentName')]
        [System.String]
        $Name
    )

    process
    {
        $null = Assert-AzContext

        $agentParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
        }

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $agentParameters['Name'] = $Name
        }

        Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobAgent @agentParameters }
    }
}
