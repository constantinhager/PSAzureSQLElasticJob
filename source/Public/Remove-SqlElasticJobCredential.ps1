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

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed operation cannot pass unnoticed. Pass $false to get a warning and
        no output instead, which suits pipeline processing.

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
        $PassThru,

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
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
                Stop-PSFFunction -Message $message -EnableException $EnableException -Category ObjectNotFound -Tag 'strict'

                return
            }

            Write-PSFMessage -Level Verbose -Message ('{0} Nothing to remove.' -f $message) -Tag 'idempotent'

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Remove Elastic Job credential'))
        {
            return
        }

        Write-PSFMessage -Level Verbose -Message ('Removing Elastic Job credential ''{0}'' from agent ''{1}''.' -f $Name, $AgentName) -Tag 'credential', 'remove'

        $null = Remove-AzSqlElasticJobCredential -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name

        Write-PSFMessage -Level Verbose -Message ('Removed Elastic Job credential ''{0}'' from agent ''{1}''.' -f $Name, $AgentName) -Tag 'credential', 'remove'

        if ($PassThru.IsPresent)
        {
            return $existingCredential
        }
    }
}
