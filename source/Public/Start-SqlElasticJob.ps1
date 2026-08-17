<#
    .SYNOPSIS
        Starts an Azure SQL Elastic Job.

    .DESCRIPTION
        Triggers an immediate execution of a job, independently of its schedule.
        The job must already exist; this command does not create one.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the job.

    .PARAMETER Name
        The name of the job to start.

    .PARAMETER Wait
        Wait for the job execution to finish before returning.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobExecutionModel

    .EXAMPLE
        Start-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'nightly-reindex'

    .EXAMPLE
        Start-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'nightly-reindex' -Wait

        Starts the job and blocks until the execution completes.
#>
function Start-SqlElasticJob
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
        [Alias('JobName')]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Wait
    )

    process
    {
        $null = Assert-AzContext

        $existingJob = Get-SqlElasticJob -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name

        if ($null -eq $existingJob)
        {
            throw ("Elastic Job '{0}' was not found on agent '{1}' in resource group '{2}'." -f
                $Name, $AgentName, $ResourceGroupName)
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Start Elastic Job'))
        {
            return
        }

        $startParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
            JobName           = $Name
        }

        $startParameters = Add-OptionalParameter -Parameter $startParameters -BoundParameter $PSBoundParameters -Name 'Wait'

        Start-AzSqlElasticJob @startParameters
    }
}
