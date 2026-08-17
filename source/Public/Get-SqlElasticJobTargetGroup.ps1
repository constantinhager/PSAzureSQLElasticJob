<#
    .SYNOPSIS
        Gets an Azure SQL Elastic Job target group.

    .DESCRIPTION
        Returns a target group defined on an Elastic Job agent, including its
        member targets. Returns $null instead of throwing when the target group
        does not exist.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the target group.

    .PARAMETER Name
        The target group name. When omitted, all target groups on the agent are
        returned.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobTargetGroupModel

    .EXAMPLE
        Get-SqlElasticJobTargetGroup -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'all-databases'

    .EXAMPLE
        Get-SqlElasticJobTargetGroup -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01'

        Returns every target group on the agent.
#>
function Get-SqlElasticJobTargetGroup
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

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AgentName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('TargetGroupName')]
        [System.String]
        $Name
    )

    process
    {
        $null = Assert-AzContext

        $targetGroupParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
        }

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $targetGroupParameters['Name'] = $Name
        }

        Write-PSFMessage -Level VeryVerbose -Message ('Looking up Elastic Job target group on agent ''{0}'' in resource group ''{1}''.' -f $AgentName, $ResourceGroupName) -Tag 'targetgroup', 'lookup'

        Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobTargetGroup @targetGroupParameters }
    }
}
