<#
    .SYNOPSIS
        Updates an Azure SQL Elastic Job agent.

    .DESCRIPTION
        Updates the tags of an existing Elastic Job agent. The command fails with a
        clear error when the agent does not exist, rather than silently creating one.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER Name
        The name of the Elastic Job agent to update.

    .PARAMETER Tag
        The tags to apply to the agent.

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed operation cannot pass unnoticed. Pass $false to get a warning and
        no output instead, which suits pipeline processing.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobAgentModel

    .EXAMPLE
        Set-SqlElasticJobAgent -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -Name 'agent01' -Tag @{ Env = 'Prod' }
#>
function Set-SqlElasticJobAgent {
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
        [Alias('AgentName')]
        [System.String]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [System.Collections.Hashtable]
        $Tag,

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
    )

    process {
        $null = Assert-AzContext

        $existingAgent = Get-SqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $Name

        if ($null -eq $existingAgent) {
            Stop-PSFFunction -Message ('Elastic Job agent ''{0}'' was not found on server ''{1}'' in resource group ''{2}''.' -f
                $Name, $ServerName, $ResourceGroupName) -EnableException $EnableException -Category ObjectNotFound

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $ServerName, $Name), 'Update Elastic Job agent')) {
            return
        }

        Write-PSFMessage -Level Output -Message ('Updating Elastic Job agent ''{0}'' on server ''{1}''.' -f $Name, $ServerName) -Tag 'agent', 'update'

        $agent = Set-AzSqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $Name -Tag $Tag

        Write-PSFMessage -Level Output -Message ('Updated Elastic Job agent ''{0}'' on server ''{1}''.' -f $Name, $ServerName) -Tag 'agent', 'update'

        return $agent
    }
}
