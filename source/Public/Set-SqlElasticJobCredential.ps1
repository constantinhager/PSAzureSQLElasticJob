<#
    .SYNOPSIS
        Updates an Azure SQL Elastic Job credential.

    .DESCRIPTION
        Replaces the user name and password of an existing job credential, which
        is how a password rotation is applied. The command fails with a clear
        error when the credential does not exist, rather than silently creating one.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the credential.

    .PARAMETER Name
        The name of the credential to update.

    .PARAMETER Credential
        The new user name and password.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobCredentialModel

    .EXAMPLE
        $credential = Get-Credential -UserName 'jobuser'
        Set-SqlElasticJobCredential -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'jobuser' -Credential $credential

        Rotates the password stored in the credential.
#>
function Set-SqlElasticJobCredential
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
        [Alias('CredentialName')]
        [System.String]
        $Name,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    process
    {
        $null = Assert-AzContext

        $existingCredential = Get-SqlElasticJobCredential -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name

        if ($null -eq $existingCredential)
        {
            throw ("Elastic Job credential '{0}' was not found on agent '{1}' in resource group '{2}'." -f
                $Name, $AgentName, $ResourceGroupName)
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Update Elastic Job credential'))
        {
            return
        }

        Set-AzSqlElasticJobCredential -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name -Credential $Credential
    }
}
