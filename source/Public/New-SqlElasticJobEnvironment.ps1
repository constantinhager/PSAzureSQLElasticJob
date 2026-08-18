<#
    .SYNOPSIS
        Provisions a complete Azure SQL Elastic Job environment, creating only what is missing.

    .DESCRIPTION
        An Elastic Job agent needs three things: a logical SQL server, a job database
        on that server at service tier S0 or higher, and the agent itself. This
        command creates each part only when it is absent, so it is safe to re-run
        against a partially or fully provisioned environment.

        The resource group is never created. Resource group placement, tagging and
        policy are deployment concerns that belong to the caller, so a missing
        resource group is reported as an error instead of being guessed at.

        Existing resources are never reconfigured. If a server or database already
        exists but does not match the supplied parameters, it is left as it is and
        reported as existing - this command provisions, it does not converge.

    .PARAMETER ResourceGroupName
        The existing resource group to provision into.

    .PARAMETER ServerName
        The logical SQL server to use or create.

    .PARAMETER DatabaseName
        The job database to use or create.

    .PARAMETER AgentName
        The Elastic Job agent to use or create.

    .PARAMETER Location
        The Azure region for a new logical SQL server. Required only when the server
        does not yet exist.

    .PARAMETER ServerAdministratorCredential
        The SQL administrator login for a new logical SQL server. Required only when
        the server does not yet exist.

    .PARAMETER ServiceObjectiveName
        The service objective for a new job database. Elastic Jobs requires S0 or
        higher; the default is S1, which is the tier Microsoft recommends.

    .PARAMETER ServerVersion
        The version of a new logical SQL server. Defaults to '12.0'.

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed provisioning run cannot pass unnoticed. Pass $false to get a
        warning and no output instead.

    .OUTPUTS
        PSCustomObject describing the environment and which parts were created.

    .EXAMPLE
        $credential = Get-Credential -UserName 'sqladmin'
        New-SqlElasticJobEnvironment -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -DatabaseName 'jobdb' -AgentName 'agent01' -Location 'westeurope' -ServerAdministratorCredential $credential

        Creates the server, job database and agent. Running it again creates nothing.

    .EXAMPLE
        New-SqlElasticJobEnvironment -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -DatabaseName 'jobdb' -AgentName 'agent01' -WhatIf

        Shows what would be created without changing anything.

    .LINK
        https://learn.microsoft.com/azure/azure-sql/database/elastic-jobs-overview
#>
function New-SqlElasticJobEnvironment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
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
        [System.String]
        $AgentName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Location,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $ServerAdministratorCredential,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServiceObjectiveName = (Get-PSFConfigValue -FullName 'PSAzureSQLElasticJob.Provisioning.ServiceObjective'),

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerVersion = (Get-PSFConfigValue -FullName 'PSAzureSQLElasticJob.Provisioning.ServerVersion'),

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
    )

    process {
        $null = Assert-AzContext

        $resourceGroup = Get-AzResourceIfPresent -ScriptBlock {
            Get-AzResourceGroup -Name $ResourceGroupName
        }

        if ($null -eq $resourceGroup) {
            Stop-PSFFunction -Message ('Resource group ''{0}'' was not found. Create it before provisioning an Elastic Job environment.' -f
                $ResourceGroupName) -EnableException $EnableException -Category ObjectNotFound

            return
        }

        $createdServer = $false
        $createdDatabase = $false
        $createdAgent = $false

        $server = Get-AzResourceIfPresent -ScriptBlock {
            Get-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName
        }

        if ($null -eq $server) {
            if (-not $PSBoundParameters.ContainsKey('Location')) {
                Stop-PSFFunction -Message ('Logical SQL server ''{0}'' does not exist and no -Location was supplied.' -f $ServerName) -EnableException $EnableException -Category InvalidArgument

                return
            }

            if (-not $PSBoundParameters.ContainsKey('ServerAdministratorCredential')) {
                Stop-PSFFunction -Message ('Logical SQL server ''{0}'' does not exist and no -ServerAdministratorCredential was supplied.' -f
                    $ServerName) -EnableException $EnableException -Category InvalidArgument

                return
            }

            if ($PSCmdlet.ShouldProcess($ServerName, ("Create logical SQL server in '{0}'" -f $Location))) {
                Write-PSFMessage -Level Verbose -Message ('Provisioning step 1 of 3: create logical SQL server ''{0}''.' -f $ServerName) -Tag 'environment', 'progress'
                Write-PSFMessage -Level Verbose -Message ('Creating logical SQL server ''{0}'' in ''{1}''.' -f $ServerName, $Location) -Tag 'server', 'create'

                try {
                    $server = New-AzSqlServer -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Location $Location -ServerVersion $ServerVersion -SqlAdministratorCredentials $ServerAdministratorCredential -ErrorAction Stop
                } catch {
                    $message = ('Failed to create logical SQL server ''{0}'': {1}' -f $ServerName, $_.Exception.Message)
                    Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'server', 'create'
                    Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

                    return
                }

                Write-PSFMessage -Level Verbose -Message ('Created logical SQL server ''{0}''.' -f $ServerName) -Tag 'server', 'create'

                $createdServer = $true
            }
        } else {
            Write-PSFMessage -Level Verbose -Message ('Logical SQL server ''{0}'' already exists.' -f $ServerName) -Tag 'idempotent'
        }

        $database = Get-AzResourceIfPresent -ScriptBlock {
            Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName
        }

        if ($null -eq $database) {
            if ($PSCmdlet.ShouldProcess(
                    ('{0}/{1}' -f $ServerName, $DatabaseName),
                    ("Create job database at service objective '{0}'" -f $ServiceObjectiveName))) {
                Write-PSFMessage -Level Verbose -Message ('Provisioning step 2 of 3: create job database ''{0}''.' -f $DatabaseName) -Tag 'environment', 'progress'
                Write-PSFMessage -Level Verbose -Message ('Creating job database ''{0}'' at service objective ''{1}''.' -f $DatabaseName, $ServiceObjectiveName) -Tag 'database', 'create'

                try {
                    $database = New-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -RequestedServiceObjectiveName $ServiceObjectiveName -ErrorAction Stop
                } catch {
                    $message = ('Failed to create job database ''{0}'': {1}' -f $DatabaseName, $_.Exception.Message)
                    Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'database', 'create'
                    Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

                    return
                }

                Write-PSFMessage -Level Verbose -Message ('Created job database ''{0}''.' -f $DatabaseName) -Tag 'database', 'create'

                $createdDatabase = $true
            }
        } else {
            Write-PSFMessage -Level Verbose -Message ('Job database ''{0}'' already exists.' -f $DatabaseName) -Tag 'idempotent'
        }

        $agent = Get-SqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -Name $AgentName

        if ($null -eq $agent) {
            if ($PSCmdlet.ShouldProcess(('{0}/{1}' -f $ServerName, $AgentName), 'Create Elastic Job agent')) {
                Write-PSFMessage -Level Verbose -Message ('Provisioning step 3 of 3: create Elastic Job agent ''{0}''.' -f $AgentName) -Tag 'environment', 'progress'
                Write-PSFMessage -Level Verbose -Message ('Creating Elastic Job agent ''{0}''.' -f $AgentName) -Tag 'agent', 'create'

                try {
                    $agent = New-AzSqlElasticJobAgent -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -Name $AgentName -ErrorAction Stop
                } catch {
                    $message = ('Failed to create Elastic Job agent ''{0}'': {1}' -f $AgentName, $_.Exception.Message)
                    Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'agent', 'create'
                    Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

                    return
                }

                Write-PSFMessage -Level Verbose -Message ('Created Elastic Job agent ''{0}''.' -f $AgentName) -Tag 'agent', 'create'

                $createdAgent = $true
            }
        } else {
            Write-PSFMessage -Level Verbose -Message ('Elastic Job agent ''{0}'' already exists.' -f $AgentName) -Tag 'idempotent'
        }

        if (($null -ne $server) -and ($null -ne $database) -and ($null -ne $agent)) {
            if ((-not $createdServer) -and (-not $createdDatabase) -and (-not $createdAgent)) {
                Write-PSFMessage -Level Output -Message ('Elastic Job environment already exists on server ''{0}'' with database ''{1}'' and agent ''{2}''. No changes were made.' -f $ServerName, $DatabaseName, $AgentName) -Tag 'environment', 'idempotent'
            } else {
                $createdResources = @()

                if ($createdServer) {
                    $createdResources += 'server'
                }

                if ($createdDatabase) {
                    $createdResources += 'database'
                }

                if ($createdAgent) {
                    $createdResources += 'agent'
                }

                Write-PSFMessage -Level Output -Message ('Elastic Job environment is ready. Created: {0}.' -f ($createdResources -join ', ')) -Tag 'environment', 'create'
            }
        }

        [PSCustomObject]@{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            DatabaseName      = $DatabaseName
            AgentName         = $AgentName
            Server            = $server
            Database          = $database
            Agent             = $agent
            CreatedServer     = $createdServer
            CreatedDatabase   = $createdDatabase
            CreatedAgent      = $createdAgent
        }
    }
}
