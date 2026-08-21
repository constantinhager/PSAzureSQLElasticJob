<#
    .SYNOPSIS
        Gets an Azure SQL Elastic Job credential.

    .DESCRIPTION
        Returns a job credential defined on an Elastic Job agent. Returns $null
        instead of throwing when the credential does not exist.

        Only the credential name and user name are returned by Azure; the
        password is never readable once stored.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the credential.

    .PARAMETER Name
        The credential name. When omitted, all credentials on the agent are returned.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobCredentialModel

    .EXAMPLE
        Get-SqlElasticJobCredential -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'jobuser'

    .EXAMPLE
        Get-SqlElasticJobCredential -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01'

        Returns every credential on the agent.
    .LINK
        https://github.com/constantinhager/PSAzureSQLElasticJob/blob/main/source/Public/Get-SqlElasticJobCredential.ps1
#>
function Get-SqlElasticJobCredential
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('CredentialName')]
        [System.String]
        $Name
    )

    process
    {
        $null = Assert-AzContext

        $credentialParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
        }

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $credentialParameters['Name'] = $Name
        }

        Write-PSFMessage -Level VeryVerbose -Message ('Looking up Elastic Job credential on agent ''{0}'' in resource group ''{1}''.' -f $AgentName, $ResourceGroupName) -Tag 'credential', 'lookup'

        Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobCredential @credentialParameters }
    }
}
