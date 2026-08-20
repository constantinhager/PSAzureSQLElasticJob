<#
    .SYNOPSIS
        Creates an Azure SQL Elastic Job.

    .DESCRIPTION
        Creates a job on an Elastic Job agent. The command is idempotent: when a
        job with the same name already exists it is returned unchanged rather
        than causing an error. Use Set-SqlElasticJob to change an existing job.

        Elastic Jobs has no separate schedule resource - the schedule is part of
        the job. Supply -RunOnce for a single execution, or -IntervalType with
        -IntervalCount for a recurring schedule. Supplying neither creates a job
        with no schedule, which can only be started manually with
        Start-SqlElasticJob.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that will own the job.

    .PARAMETER Name
        The name of the job to create.

    .PARAMETER Description
        A free-text description of the job.

    .PARAMETER Enable
        Enable the job's schedule. Without this switch the job is created
        disabled.

    .PARAMETER RunOnce
        Schedule the job to run a single time.

    .PARAMETER IntervalType
        The unit of the recurring interval: Minute, Hour, Day, Week or Month.

    .PARAMETER IntervalCount
        How many IntervalType units elapse between runs.

    .PARAMETER StartTime
        When the schedule becomes active.

    .PARAMETER EndTime
        When the recurring schedule stops.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobModel

    .EXAMPLE
        New-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'nightly-reindex' -IntervalType 'Day' -IntervalCount 1 -Enable

        Creates a job that runs once a day.

    .EXAMPLE
        New-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'one-off-migration' -RunOnce

        Creates a job scheduled to run a single time.

    .LINK
        https://learn.microsoft.com/azure/azure-sql/database/elastic-jobs-overview
#>
function New-SqlElasticJob {
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
        $EndTime
    )

    process {
        $null = Assert-AzContext

        $existingJob = Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJob -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name }

        if ($null -ne $existingJob) {
            Write-PSFMessage -Level Output -Message ('Elastic Job ''{0}'' already exists on agent ''{1}''.' -f $Name, $AgentName) -Tag 'idempotent'

            return $existingJob
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Create Elastic Job')) {
            return
        }

        $jobParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
            Name              = $Name
        }

        $jobParameters = Add-OptionalParameter -Parameter $jobParameters -BoundParameter $PSBoundParameters -Name 'Description', 'Enable', 'RunOnce', 'IntervalType', 'IntervalCount', 'StartTime', 'EndTime'

        Write-PSFMessage -Level Output -Message ('Creating Elastic Job ''{0}'' on agent ''{1}''.' -f $Name, $AgentName) -Tag 'job', 'create'

        $job = New-AzSqlElasticJob @jobParameters -ErrorAction Stop

        Write-PSFMessage -Level Output -Message ('Created Elastic Job ''{0}'' on agent ''{1}''.' -f $Name, $AgentName) -Tag 'job', 'create'

        return $job
    }
}
