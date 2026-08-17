<#
    .SYNOPSIS
        Creates an Azure SQL Elastic Job target group.

    .DESCRIPTION
        Creates an empty target group on an Elastic Job agent. The command is
        idempotent: when a target group with the same name already exists it is
        returned unchanged. Add members with Add-SqlElasticJobTarget.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that will own the target group.

    .PARAMETER Name
        The name of the target group to create.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobTargetGroupModel

    .EXAMPLE
        New-SqlElasticJobTargetGroup -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'all-databases'
#>
function New-SqlElasticJobTargetGroup
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
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

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('TargetGroupName')]
        [System.String]
        $Name
    )

    process
    {
        $null = Assert-AzContext

        $existingTargetGroup = Get-SqlElasticJobTargetGroup -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name

        if ($null -ne $existingTargetGroup)
        {
            Write-PSFMessage -Level Verbose -Message ('Elastic Job target group ''{0}'' already exists on agent ''{1}''.' -f $Name, $AgentName) -Tag 'idempotent'

            return $existingTargetGroup
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Create Elastic Job target group'))
        {
            return
        }

        New-AzSqlElasticJobTargetGroup -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name
    }
}
