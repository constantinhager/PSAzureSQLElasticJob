<#
    .SYNOPSIS
        Removes an Azure SQL Elastic Job.

    .DESCRIPTION
        Removes a job and its steps from an Elastic Job agent. Removing a
        non-existent job is a no-op unless -Strict is supplied.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the job.

    .PARAMETER Name
        The name of the job to remove.

    .PARAMETER Force
        Passed through to Azure to force removal of a job that is currently
        executing.

    .PARAMETER Strict
        Throw when the job does not exist instead of returning silently.

    .PARAMETER PassThru
        Return the removed job object.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobModel

    .EXAMPLE
        Remove-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'nightly-reindex'
#>
function Remove-SqlElasticJob
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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
        $Force,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Strict,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    process
    {
        $null = Assert-AzContext

        $existingJob = Get-SqlElasticJob -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name

        if ($null -eq $existingJob)
        {
            $message = "Elastic Job '{0}' was not found on agent '{1}' in resource group '{2}'." -f
                $Name, $AgentName, $ResourceGroupName

            if ($Strict.IsPresent)
            {
                throw $message
            }

            Write-Verbose -Message ('{0} Nothing to remove.' -f $message)

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Remove Elastic Job'))
        {
            return
        }

        $removeParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
            Name              = $Name
        }

        $removeParameters = Add-OptionalParameter -Parameter $removeParameters -BoundParameter $PSBoundParameters -Name 'Force'

        $null = Remove-AzSqlElasticJob @removeParameters

        if ($PassThru.IsPresent)
        {
            return $existingJob
        }
    }
}
