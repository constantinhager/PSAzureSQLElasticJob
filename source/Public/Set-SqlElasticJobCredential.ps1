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

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed operation cannot pass unnoticed. Pass $false to get a warning and
        no output instead, which suits pipeline processing.

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
        $Credential,

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
            Stop-PSFFunction -Message ('Elastic Job credential ''{0}'' was not found on agent ''{1}'' in resource group ''{2}''.' -f
                $Name, $AgentName, $ResourceGroupName) -EnableException $EnableException -Category ObjectNotFound

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Update Elastic Job credential'))
        {
            return
        }

        Write-PSFMessage -Level Verbose -Message ('Rotating Elastic Job credential ''{0}'' on agent ''{1}''.' -f $Name, $AgentName) -Tag 'credential', 'update'

        $jobCredential = Set-AzSqlElasticJobCredential -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name -Credential $Credential

        Write-PSFMessage -Level Verbose -Message ('Rotated Elastic Job credential ''{0}'' on agent ''{1}''.' -f $Name, $AgentName) -Tag 'credential', 'update'

        return $jobCredential
    }
}
