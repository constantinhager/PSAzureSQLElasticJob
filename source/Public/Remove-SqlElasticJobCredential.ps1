<#
    .SYNOPSIS
        Removes an Azure SQL Elastic Job credential.

    .DESCRIPTION
        Removes a job credential from an Elastic Job agent. Job steps that still
        reference the credential will fail at their next execution, so check for
        references before removing one. Removing a non-existent credential is a
        no-op unless -Strict is supplied.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the credential.

    .PARAMETER Name
        The name of the credential to remove.

    .PARAMETER Strict
        Throw when the credential does not exist instead of returning silently.

    .PARAMETER PassThru
        Return the removed credential object.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobCredentialModel

    .EXAMPLE
        Remove-SqlElasticJobCredential -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'jobuser'
#>
function Remove-SqlElasticJobCredential
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
        [Alias('CredentialName')]
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

        $existingCredential = Get-SqlElasticJobCredential -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name

        if ($null -eq $existingCredential)
        {
            $message = "Elastic Job credential '{0}' was not found on agent '{1}' in resource group '{2}'." -f
                $Name, $AgentName, $ResourceGroupName

            if ($Strict.IsPresent)
            {
                throw $message
            }

            Write-Verbose -Message ('{0} Nothing to remove.' -f $message)

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Remove Elastic Job credential'))
        {
            return
        }

        $null = Remove-AzSqlElasticJobCredential -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name

        if ($PassThru.IsPresent)
        {
            return $existingCredential
        }
    }
}
