<#
    .SYNOPSIS
        Adds a target to an Azure SQL Elastic Job target group.

    .DESCRIPTION
        Adds a database, a whole server, an elastic pool or a shard map as a
        member of a target group.

        Note the two different servers involved: -ServerName is the logical SQL
        server hosting the Elastic Job agent, while -TargetServerName is the
        server being targeted. They are frequently different, and the underlying
        Az.Sql cmdlet distinguishes them as AgentServerName and ServerName.

        Use -Exclude to add the member as an exclusion, which removes it from a
        broader inclusion such as an entire server.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server hosting the agent.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the target group.

    .PARAMETER TargetGroupName
        The target group the member is added to.

    .PARAMETER TargetServerName
        The server being targeted.

    .PARAMETER TargetDatabaseName
        The database being targeted, or the shard map manager database when
        -TargetShardMapName is used.

    .PARAMETER TargetElasticPoolName
        The elastic pool being targeted.

    .PARAMETER TargetShardMapName
        The shard map being targeted.

    .PARAMETER RefreshCredentialName
        The credential used to enumerate the databases of a server, elastic pool
        or shard map target.

    .PARAMETER Exclude
        Add the member as an exclusion rather than an inclusion.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobTargetGroupModel

    .EXAMPLE
        Add-SqlElasticJobTarget -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -TargetGroupName 'all-databases' -TargetServerName 'sql-prod' -TargetDatabaseName 'AppDb'

        Adds a single database to the target group.

    .EXAMPLE
        Add-SqlElasticJobTarget -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -TargetGroupName 'all-databases' -TargetServerName 'sql-prod' -RefreshCredentialName 'refreshcred'

        Adds every database on a server, refreshed using the supplied credential.

    .EXAMPLE
        Add-SqlElasticJobTarget -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -TargetGroupName 'all-databases' -TargetServerName 'sql-prod' -TargetDatabaseName 'AppDb' -Exclude

        Excludes one database from a broader server-level inclusion.
#>
function Add-SqlElasticJobTarget {
    # RefreshCredentialName names an existing job credential; it never carries a secret.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'RefreshCredentialName', Justification = 'The parameter is the name of a job credential, not a password.')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'SqlDatabase')]
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
        $TargetDatabaseName,

        [Parameter(ParameterSetName = 'SqlServerOrElasticPool', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetElasticPoolName,

        [Parameter(Mandatory, ParameterSetName = 'SqlShardMap', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetShardMapName,

        [Parameter(ParameterSetName = 'SqlServerOrElasticPool', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'SqlShardMap', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RefreshCredentialName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Exclude
    )

    process {
        $null = Assert-AzContext

        $targetParameters = @{
            ResourceGroupName = $ResourceGroupName
            AgentServerName   = $ServerName
            AgentName         = $AgentName
            TargetGroupName   = $TargetGroupName
            ServerName        = $TargetServerName
        }

        # Local parameter names carry a Target* prefix for clarity; Azure's own parameter names do not.
        if ($PSBoundParameters.ContainsKey('TargetDatabaseName')) {
            $targetParameters['DatabaseName'] = $TargetDatabaseName
        }

        if ($PSBoundParameters.ContainsKey('TargetElasticPoolName')) {
            $targetParameters['ElasticPoolName'] = $TargetElasticPoolName
        }

        if ($PSBoundParameters.ContainsKey('TargetShardMapName')) {
            $targetParameters['ShardMapName'] = $TargetShardMapName
        }

        $targetParameters = Add-OptionalParameter -Parameter $targetParameters -BoundParameter $PSBoundParameters -Name 'RefreshCredentialName', 'Exclude'

        $action = if ($Exclude.IsPresent) { 'Exclude target from Elastic Job target group' } else { 'Add target to Elastic Job target group' }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $TargetGroupName), $action)) {
            return
        }

        Write-PSFMessage -Level Output -Message ('Adding target server ''{0}'' to target group ''{1}'' on agent ''{2}''.' -f $TargetServerName, $TargetGroupName, $AgentName) -Tag 'target', 'create'

        $targetGroup = Add-AzSqlElasticJobTarget @targetParameters -ErrorAction Stop

        Write-PSFMessage -Level Output -Message ('Added target server ''{0}'' to target group ''{1}''.' -f $TargetServerName, $TargetGroupName) -Tag 'target', 'create'

        return $targetGroup
    }
}
