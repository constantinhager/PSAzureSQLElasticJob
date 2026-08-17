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

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed operation cannot pass unnoticed. Pass $false to get a warning and
        no output instead, which suits pipeline processing.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobAgentModel

    .EXAMPLE
        Remove-SqlElasticJobAgent -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -Name 'agent01'
#>
function Remove-SqlElasticJobAgent {
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
        $PassThru,

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
    )

    process {
        $null = Assert-AzContext

        $existingAgent = Get-SqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $Name

        if ($null -eq $existingAgent) {
            $message = "Elastic Job agent '{0}' was not found on server '{1}' in resource group '{2}'." -f
            $Name, $ServerName, $ResourceGroupName

            if ($Strict.IsPresent) {
                Stop-PSFFunction -Message $message -EnableException $EnableException -Category ObjectNotFound -Tag 'strict'

                return
            }

            Write-PSFMessage -Level Verbose -Message ('{0} Nothing to remove.' -f $message) -Tag 'idempotent'

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $ServerName, $Name), 'Remove Elastic Job agent')) {
            return
        }

        Write-PSFMessage -Level Verbose -Message ('Removing Elastic Job agent ''{0}'' from server ''{1}''.' -f $Name, $ServerName) -Tag 'agent', 'remove'

        $null = Remove-AzSqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $Name

        Write-PSFMessage -Level Verbose -Message ('Removed Elastic Job agent ''{0}'' from server ''{1}''.' -f $Name, $ServerName) -Tag 'agent', 'remove'

        if ($PassThru.IsPresent) {
            return $existingAgent
        }
    }
}
