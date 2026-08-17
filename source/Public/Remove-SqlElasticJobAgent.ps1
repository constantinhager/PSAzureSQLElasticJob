<#
    .SYNOPSIS
        Removes an Azure SQL Elastic Job agent.

    .DESCRIPTION
        Removes an Elastic Job agent from a logical SQL server. The job database and
        the logical server itself are never removed by this command - deleting them
        is a separate, far more destructive decision that the caller must make
        explicitly.

        Removing a non-existent agent is a no-op unless -Strict is supplied.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER Name
        The name of the Elastic Job agent to remove.

    .PARAMETER Strict
        Throw when the agent does not exist instead of returning silently.

    .PARAMETER PassThru
        Return the removed agent object.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobAgentModel

    .EXAMPLE
        Remove-SqlElasticJobAgent -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -Name 'agent01'
#>
function Remove-SqlElasticJobAgent
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
        [Alias('AgentName')]
        [System.String]
        $Name,

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

        $existingAgent = Get-SqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $Name

        if ($null -eq $existingAgent)
        {
            $message = "Elastic Job agent '{0}' was not found on server '{1}' in resource group '{2}'." -f
                $Name, $ServerName, $ResourceGroupName

            if ($Strict.IsPresent)
            {
                throw $message
            }

            Write-Verbose -Message ('{0} Nothing to remove.' -f $message)

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $ServerName, $Name), 'Remove Elastic Job agent'))
        {
            return
        }

        $null = Remove-AzSqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $Name

        if ($PassThru.IsPresent)
        {
            return $existingAgent
        }
    }
}
