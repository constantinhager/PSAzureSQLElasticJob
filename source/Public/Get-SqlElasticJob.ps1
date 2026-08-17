<#
    .SYNOPSIS
        Gets an Azure SQL Elastic Job.

    .DESCRIPTION
        Returns a job defined on an Elastic Job agent. Unlike Get-AzSqlElasticJob,
        this command returns $null instead of throwing when the job does not
        exist, so it can be used directly in conditional logic.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the job.

    .PARAMETER Name
        The job name. When omitted, all jobs on the agent are returned.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobModel

    .EXAMPLE
        Get-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'nightly-reindex'

    .EXAMPLE
        Get-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01'

        Returns every job on the agent.
#>
function Get-SqlElasticJob
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
        [Alias('JobName')]
        [System.String]
        $Name
    )

    process
    {
        $null = Assert-AzContext

        $jobParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
        }

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $jobParameters['Name'] = $Name
        }

        Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJob @jobParameters }
    }
}
