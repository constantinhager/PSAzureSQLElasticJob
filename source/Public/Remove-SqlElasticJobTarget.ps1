<#
    .SYNOPSIS
        Removes a target from an Azure SQL Elastic Job target group.

    .DESCRIPTION
        Removes a database, server, elastic pool or shard map member from a
        target group. The target group itself is left in place.

        As with Add-SqlElasticJobTarget, -ServerName is the logical SQL server
        hosting the Elastic Job agent and -TargetServerName is the server being
        targeted.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server hosting the agent.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the target group.

    .PARAMETER TargetGroupName
        The target group the member is removed from.

    .PARAMETER TargetServerName
        The server being targeted.

    .PARAMETER DatabaseName
        The database being targeted, or the shard map manager database when
        -ShardMapName is used.

    .PARAMETER ElasticPoolName
        The elastic pool being targeted.

    .PARAMETER ShardMapName
        The shard map being targeted.

    .PARAMETER RefreshCredentialName
        The credential associated with the server, elastic pool or shard map
        target being removed.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobTargetGroupModel

    .EXAMPLE
        Remove-SqlElasticJobTarget -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -TargetGroupName 'all-databases' -TargetServerName 'sql-prod' -DatabaseName 'AppDb'
#>
function Remove-SqlElasticJobTarget
{
    # RefreshCredentialName names an existing job credential; it never carries a secret.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'RefreshCredentialName', Justification = 'The parameter is the name of a job credential, not a password.')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'SqlDatabase')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ResourceGroupName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('AgentServerName')]
        [System.String]
        $ServerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AgentName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetGroupName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetServerName,

        [Parameter(Mandatory, ParameterSetName = 'SqlDatabase', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'SqlShardMap', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName,

        [Parameter(ParameterSetName = 'SqlServerOrElasticPool', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ElasticPoolName,

        [Parameter(Mandatory, ParameterSetName = 'SqlShardMap', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ShardMapName,

        [Parameter(ParameterSetName = 'SqlServerOrElasticPool', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'SqlShardMap', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RefreshCredentialName
    )

    process
    {
        $null = Assert-AzContext

        $targetParameters = @{
            ResourceGroupName = $ResourceGroupName
            AgentServerName   = $ServerName
            AgentName         = $AgentName
            TargetGroupName   = $TargetGroupName
            ServerName        = $TargetServerName
        }

        $targetParameters = Add-OptionalParameter -Parameter $targetParameters -BoundParameter $PSBoundParameters -Name 'DatabaseName', 'ElasticPoolName', 'ShardMapName', 'RefreshCredentialName'

        if (-not $PSCmdlet.ShouldProcess(
                ('{0}/{1}' -f $AgentName, $TargetGroupName),
                'Remove target from Elastic Job target group'))
        {
            return
        }

        Write-PSFMessage -Level Output -Message ('Removing target server ''{0}'' from target group ''{1}'' on agent ''{2}''.' -f $TargetServerName, $TargetGroupName, $AgentName) -Tag 'target', 'remove'

        $targetGroup = Remove-AzSqlElasticJobTarget @targetParameters

        Write-PSFMessage -Level Output -Message ('Removed target server ''{0}'' from target group ''{1}''.' -f $TargetServerName, $TargetGroupName) -Tag 'target', 'remove'

        return $targetGroup
    }
}
