<#
    .SYNOPSIS
        Updates an Azure SQL Elastic Job.

    .DESCRIPTION
        Updates the description or schedule of an existing job. The command fails
        with a clear error when the job does not exist, rather than silently
        creating one.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the job.

    .PARAMETER Name
        The name of the job to update.

    .PARAMETER Description
        A new free-text description for the job.

    .PARAMETER Enable
        Whether the job's schedule is enabled. Pass -Enable:$false to disable it.

    .PARAMETER RunOnce
        Change the job to run a single time.

    .PARAMETER IntervalType
        The unit of the recurring interval: Minute, Hour, Day, Week or Month.

    .PARAMETER IntervalCount
        How many IntervalType units elapse between runs.

    .PARAMETER StartTime
        When the schedule becomes active.

    .PARAMETER EndTime
        When the recurring schedule stops.

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed operation cannot pass unnoticed. Pass $false to get a warning and
        no output instead, which suits pipeline processing.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobModel

    .EXAMPLE
        Set-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'nightly-reindex' -Enable:$false

        Disables the job's schedule without deleting the job.

    .EXAMPLE
        Set-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'nightly-reindex' -IntervalType 'Hour' -IntervalCount 6
#>
function Set-SqlElasticJob
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'NoSchedule')]
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
        [Alias('JobName')]
        [System.String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [System.String]
        $Description,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Enable,

        [Parameter(Mandatory, ParameterSetName = 'RunOnce')]
        [System.Management.Automation.SwitchParameter]
        $RunOnce,

        [Parameter(Mandatory, ParameterSetName = 'Recurring', ValueFromPipelineByPropertyName)]
        [ValidateSet('Minute', 'Hour', 'Day', 'Week', 'Month')]
        [System.String]
        $IntervalType,

        [Parameter(Mandatory, ParameterSetName = 'Recurring', ValueFromPipelineByPropertyName)]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]
        $IntervalCount,

        [Parameter(ParameterSetName = 'RunOnce', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Recurring', ValueFromPipelineByPropertyName)]
        [System.DateTime]
        $StartTime,

        [Parameter(ParameterSetName = 'Recurring', ValueFromPipelineByPropertyName)]
        [System.DateTime]
        $EndTime,

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
    )

    process
    {
        $null = Assert-AzContext

        $existingJob = Get-SqlElasticJob -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name

        if ($null -eq $existingJob)
        {
            Stop-PSFFunction -Message ('Elastic Job ''{0}'' was not found on agent ''{1}'' in resource group ''{2}''.' -f
                $Name, $AgentName, $ResourceGroupName) -EnableException $EnableException -Category ObjectNotFound

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Update Elastic Job'))
        {
            return
        }

        $jobParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
            Name              = $Name
        }

        # Enable is forwarded on presence, not on value, so -Enable:$false can
        # disable a job while omitting it leaves the schedule untouched.
        $jobParameters = Add-OptionalParameter -Parameter $jobParameters -BoundParameter $PSBoundParameters -Name 'Description', 'Enable', 'RunOnce', 'IntervalType', 'IntervalCount', 'StartTime', 'EndTime'

        Write-PSFMessage -Level Output -Message ('Updating Elastic Job ''{0}'' on agent ''{1}''.' -f $Name, $AgentName) -Tag 'job', 'update'

        $job = Set-AzSqlElasticJob @jobParameters

        Write-PSFMessage -Level Output -Message ('Updated Elastic Job ''{0}'' on agent ''{1}''.' -f $Name, $AgentName) -Tag 'job', 'update'

        return $job
    }
}
