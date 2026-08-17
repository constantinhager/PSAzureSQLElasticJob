<#
    .SYNOPSIS
        Gets a step of an Azure SQL Elastic Job.

    .DESCRIPTION
        Returns a step defined on a job. Returns $null instead of throwing when
        the step does not exist, so it can be used in conditional logic.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the job.

    .PARAMETER JobName
        The job that owns the step.

    .PARAMETER Name
        The step name. When omitted, all steps of the job are returned.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobStepModel

    .EXAMPLE
        Get-SqlElasticJobStep -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -JobName 'nightly-reindex' -Name 'rebuild-indexes'

    .EXAMPLE
        Get-SqlElasticJobStep -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -JobName 'nightly-reindex'

        Returns every step of the job.
#>
function Get-SqlElasticJobStep
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

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $JobName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('StepName')]
        [System.String]
        $Name
    )

    process
    {
        $null = Assert-AzContext

        $stepParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
            JobName           = $JobName
        }

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $stepParameters['Name'] = $Name
        }

        Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobStep @stepParameters }
    }
}
