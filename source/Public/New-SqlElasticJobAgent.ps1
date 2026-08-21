<#
    .SYNOPSIS
        Creates an Azure SQL Elastic Job agent.

    .DESCRIPTION
        Creates an Elastic Job agent on an existing logical SQL server and job
        database. The command is idempotent: when an agent with the same name
        already exists it is returned unchanged rather than causing an error.

        The job database must already exist and must be at service tier S0 or
        higher. Use New-SqlElasticJobEnvironment to provision the server, the job
        database and the agent in one idempotent call.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server that will host the agent.

    .PARAMETER DatabaseName
        The existing job database backing the agent.

    .PARAMETER Name
        The name of the Elastic Job agent to create.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobAgentModel

    .EXAMPLE
        New-SqlElasticJobAgent -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -DatabaseName 'jobdb' -Name 'agent01'
    .LINK
        https://github.com/constantinhager/PSAzureSQLElasticJob/blob/main/source/Public/New-SqlElasticJobAgent.ps1
#>
function New-SqlElasticJobAgent {
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
        $DatabaseName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('AgentName')]
        [System.String]
        $Name
    )

    process {
        $null = Assert-AzContext

        $existingAgent = Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $Name }

        if ($null -ne $existingAgent) {
            Write-PSFMessage -Level Output -Message ('Elastic Job agent ''{0}'' already exists on server ''{1}''.' -f $Name, $ServerName) -Tag 'idempotent'

            return $existingAgent
        }

        if (-not $PSCmdlet.ShouldProcess(
                ('{0}/{1}' -f $ServerName, $Name),
                ("Create Elastic Job agent backed by database '{0}'" -f $DatabaseName))) {
            return
        }

        Write-PSFMessage -Level Output -Message ('Creating Elastic Job agent ''{0}'' on server ''{1}'' backed by database ''{2}''.' -f $Name, $ServerName, $DatabaseName) -Tag 'agent', 'create'

        $agent = New-AzSqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -Name $Name -ErrorAction Stop

        Write-PSFMessage -Level Output -Message ('Created Elastic Job agent ''{0}'' on server ''{1}''.' -f $Name, $ServerName) -Tag 'agent', 'create'

        return $agent
    }
}
