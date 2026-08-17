<#
    .SYNOPSIS
        Stops a running Azure SQL Elastic Job execution.

    .DESCRIPTION
        Cancels a specific in-flight execution of a job. Azure identifies the
        execution rather than the job, so -JobExecutionId is required; use
        Get-AzSqlElasticJobExecution to find the id of a running execution.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the job.

    .PARAMETER Name
        The name of the job whose execution should be stopped.

    .PARAMETER JobExecutionId
        The id of the execution to cancel.

    .OUTPUTS
        None.

    .EXAMPLE
        Stop-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'nightly-reindex' -JobExecutionId '5555e5e5-5555-5e55-e555-5555e5e55555'
#>
function Stop-SqlElasticJob
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([System.Void])]
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

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Guid]
        $JobExecutionId
    )

    process
    {
        $null = Assert-AzContext

        if (-not $PSCmdlet.ShouldProcess(
                ('{0}/{1}' -f $AgentName, $Name),
                ("Stop Elastic Job execution '{0}'" -f $JobExecutionId)))
        {
            return
        }

        Write-PSFMessage -Level Verbose -Message ('Stopping execution ''{0}'' of Elastic Job ''{1}''.' -f $JobExecutionId, $Name) -Tag 'job', 'execution'

        Stop-AzSqlElasticJob -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -JobName $Name -JobExecutionId $JobExecutionId

        Write-PSFMessage -Level Verbose -Message ('Stopped execution ''{0}'' of Elastic Job ''{1}''.' -f $JobExecutionId, $Name) -Tag 'job', 'execution'
    }
}
