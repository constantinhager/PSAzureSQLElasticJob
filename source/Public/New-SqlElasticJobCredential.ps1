<#
    .SYNOPSIS
        Creates an Azure SQL Elastic Job credential.

    .DESCRIPTION
        Creates a database-scoped credential on the job database that job steps
        use to connect to their targets. The command is idempotent: when a
        credential with the same name already exists it is returned unchanged.

        Because Azure never returns a stored password, this command cannot tell
        whether an existing credential holds the password you supplied. It will
        not overwrite it - use Set-SqlElasticJobCredential to rotate a password.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that will own the credential.

    .PARAMETER Name
        The name of the credential to create.

    .PARAMETER Credential
        The user name and password the job steps authenticate with. This login
        must exist on every target database.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobCredentialModel

    .EXAMPLE
        $credential = Get-Credential -UserName 'jobuser'
        New-SqlElasticJobCredential -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'jobuser' -Credential $credential
    .LINK
        https://github.com/constantinhager/PSAzureSQLElasticJob/blob/main/source/Public/New-SqlElasticJobCredential.ps1
#>
function New-SqlElasticJobCredential
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

        $existingCredential = Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobCredential -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name }

        if ($null -ne $existingCredential)
        {
            Write-PSFMessage -Level Output -Message ('Elastic Job credential ''{0}'' already exists on agent ''{1}''.' -f $Name, $AgentName) -Tag 'idempotent'

            return $existingCredential
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $AgentName, $Name), 'Create Elastic Job credential'))
        {
            return
        }

        Write-PSFMessage -Level Output -Message ('Creating Elastic Job credential ''{0}'' on agent ''{1}''.' -f $Name, $AgentName) -Tag 'credential', 'create'

        $jobCredential = New-AzSqlElasticJobCredential -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -Name $Name -Credential $Credential -ErrorAction Stop

        Write-PSFMessage -Level Output -Message ('Created Elastic Job credential ''{0}'' on agent ''{1}''.' -f $Name, $AgentName) -Tag 'credential', 'create'

        return $jobCredential
    }
}
