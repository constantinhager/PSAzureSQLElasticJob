<#
    Runs on module import. ModuleBuilder appends this file to the built .psm1,
    so it is the only place in the module where code executes at load time.

    -Initialize registers each setting once per session and deliberately does not
    overwrite a value the user has already changed.
#>

Set-PSFConfig -Module 'PSAzureSQLElasticJob' -Name 'Provisioning.ServiceObjective' -Value 'S1' -Initialize -Validation 'string' -Description 'Service objective used for a job database this module creates. Elastic Jobs requires S0 or higher; S1 is the tier Microsoft recommends.'

Set-PSFConfig -Module 'PSAzureSQLElasticJob' -Name 'Provisioning.ServerVersion' -Value '12.0' -Initialize -Validation 'string' -Description 'Version used for a logical SQL server this module creates.'

<#
    Tab completion (PSFramework TEPP). Every scriptblock below silently returns
    nothing rather than throwing - a broken completer must never interrupt the
    user's typing - and relies only on whatever the caller has already typed
    ($fakeBoundParameter), never on a live Assert-AzContext, since there may be
    no signed-in context yet while the user is still filling in parameters.
#>

Register-PSFTeppScriptblock -Name 'PSAzureSQLElasticJob.ResourceGroupName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    try {
        $resourceGroups = (Get-AzResourceGroup -ErrorAction Stop).ResourceGroupName | Where-Object { $_ -like "$wordToComplete*" }

        foreach ($resourceGroup in $resourceGroups) {
            New-PSFTeppCompletionResult -CompletionText $resourceGroup -ToolTip $resourceGroup
        }
    } catch {
    }
}

Register-PSFTeppScriptblock -Name 'PSAzureSQLElasticJob.ServerName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    try {
        $serverParameters = @{}

        if ($fakeBoundParameter['ResourceGroupName']) {
            $serverParameters['ResourceGroupName'] = $fakeBoundParameter['ResourceGroupName']
        }

        $servers = (Get-AzSqlServer @serverParameters -ErrorAction Stop).ServerName | Where-Object { $_ -like "$wordToComplete*" }

        foreach ($server in $servers) {
            New-PSFTeppCompletionResult -CompletionText $server -ToolTip $server
        }
    } catch {
    }
}

Register-PSFTeppScriptblock -Name 'PSAzureSQLElasticJob.DatabaseName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    try {
        $server = $fakeBoundParameter['ServerName'], $fakeBoundParameter['TargetServerName'], $fakeBoundParameter['OutputServerName'] |
            Where-Object { $_ } | Select-Object -First 1

        if (-not $server) {
            return
        }

        $resourceGroupName = $fakeBoundParameter['ResourceGroupName']

        if (-not $resourceGroupName) {
            $resourceGroupName = (Get-AzSqlServer -ErrorAction Stop | Where-Object ServerName -EQ $server | Select-Object -First 1).ResourceGroupName
        }

        if (-not $resourceGroupName) {
            return
        }

        $databases = (Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $server -ErrorAction Stop).DatabaseName |
            Where-Object { $_ -ne 'master' -and $_ -like "$wordToComplete*" }

        foreach ($database in $databases) {
            New-PSFTeppCompletionResult -CompletionText $database -ToolTip $database
        }
    } catch {
    }
}

Register-PSFTeppScriptblock -Name 'PSAzureSQLElasticJob.AgentName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    try {
        $resourceGroupName = $fakeBoundParameter['ResourceGroupName']
        $serverName = $fakeBoundParameter['ServerName']

        if (-not $resourceGroupName -or -not $serverName) {
            return
        }

        $agents = (Get-AzSqlElasticJobAgent -ResourceGroupName $resourceGroupName -ServerName $serverName -ErrorAction Stop).AgentName |
            Where-Object { $_ -like "$wordToComplete*" }

        foreach ($agent in $agents) {
            New-PSFTeppCompletionResult -CompletionText $agent -ToolTip $agent
        }
    } catch {
    }
}

Register-PSFTeppScriptblock -Name 'PSAzureSQLElasticJob.JobName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    try {
        $resourceGroupName = $fakeBoundParameter['ResourceGroupName']
        $serverName = $fakeBoundParameter['ServerName']
        $agentName = $fakeBoundParameter['AgentName']

        if (-not $resourceGroupName -or -not $serverName -or -not $agentName) {
            return
        }

        $jobs = (Get-AzSqlElasticJob -ResourceGroupName $resourceGroupName -ServerName $serverName -AgentName $agentName -ErrorAction Stop).JobName |
            Where-Object { $_ -like "$wordToComplete*" }

        foreach ($job in $jobs) {
            New-PSFTeppCompletionResult -CompletionText $job -ToolTip $job
        }
    } catch {
    }
}

Register-PSFTeppScriptblock -Name 'PSAzureSQLElasticJob.StepName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    try {
        $resourceGroupName = $fakeBoundParameter['ResourceGroupName']
        $serverName = $fakeBoundParameter['ServerName']
        $agentName = $fakeBoundParameter['AgentName']
        $jobName = $fakeBoundParameter['JobName']

        if (-not $resourceGroupName -or -not $serverName -or -not $agentName -or -not $jobName) {
            return
        }

        $steps = (Get-AzSqlElasticJobStep -ResourceGroupName $resourceGroupName -ServerName $serverName -AgentName $agentName -JobName $jobName -ErrorAction Stop).StepName |
            Where-Object { $_ -like "$wordToComplete*" }

        foreach ($step in $steps) {
            New-PSFTeppCompletionResult -CompletionText $step -ToolTip $step
        }
    } catch {
    }
}

Register-PSFTeppScriptblock -Name 'PSAzureSQLElasticJob.CredentialName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    try {
        $resourceGroupName = $fakeBoundParameter['ResourceGroupName']
        $serverName = $fakeBoundParameter['ServerName']
        $agentName = $fakeBoundParameter['AgentName']

        if (-not $resourceGroupName -or -not $serverName -or -not $agentName) {
            return
        }

        $credentials = (Get-AzSqlElasticJobCredential -ResourceGroupName $resourceGroupName -ServerName $serverName -AgentName $agentName -ErrorAction Stop).CredentialName |
            Where-Object { $_ -like "$wordToComplete*" }

        foreach ($credential in $credentials) {
            New-PSFTeppCompletionResult -CompletionText $credential -ToolTip $credential
        }
    } catch {
    }
}

Register-PSFTeppScriptblock -Name 'PSAzureSQLElasticJob.TargetGroupName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    try {
        $resourceGroupName = $fakeBoundParameter['ResourceGroupName']
        $serverName = $fakeBoundParameter['ServerName']
        $agentName = $fakeBoundParameter['AgentName']

        if (-not $resourceGroupName -or -not $serverName -or -not $agentName) {
            return
        }

        $targetGroups = (Get-AzSqlElasticJobTargetGroup -ResourceGroupName $resourceGroupName -ServerName $serverName -AgentName $agentName -ErrorAction Stop).TargetGroupName |
            Where-Object { $_ -like "$wordToComplete*" }

        foreach ($targetGroup in $targetGroups) {
            New-PSFTeppCompletionResult -CompletionText $targetGroup -ToolTip $targetGroup
        }
    } catch {
    }
}

# -ResourceGroupName: every command that talks to ARM.
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobStep', 'Add-SqlElasticJobTarget', 'Get-SqlElasticJob', 'Get-SqlElasticJobAgent', 'Get-SqlElasticJobCredential', 'Get-SqlElasticJobStep', 'Get-SqlElasticJobTargetGroup', 'New-SqlElasticJob', 'New-SqlElasticJobAgent', 'New-SqlElasticJobCredential', 'New-SqlElasticJobEnvironment', 'New-SqlElasticJobTargetGroup', 'New-SqlElasticJobUserAssignedIdentity', 'Remove-SqlElasticJob', 'Remove-SqlElasticJobAgent', 'Remove-SqlElasticJobCredential', 'Remove-SqlElasticJobStep', 'Remove-SqlElasticJobTarget', 'Remove-SqlElasticJobTargetGroup', 'Set-SqlElasticJob', 'Set-SqlElasticJobAgent', 'Set-SqlElasticJobCredential', 'Set-SqlElasticJobStep', 'Start-SqlElasticJob', 'Stop-SqlElasticJob', 'Test-SqlElasticJobEnvironment' -Parameter 'ResourceGroupName' -Name 'PSAzureSQLElasticJob.ResourceGroupName'

# -ServerName / -TargetServerName / -OutputServerName: all Azure SQL logical server names.
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobStep', 'Get-SqlElasticJob', 'Get-SqlElasticJobAgent', 'Get-SqlElasticJobCredential', 'Get-SqlElasticJobStep', 'Get-SqlElasticJobTargetGroup', 'New-SqlElasticJob', 'New-SqlElasticJobAgent', 'New-SqlElasticJobCredential', 'New-SqlElasticJobEnvironment', 'New-SqlElasticJobTargetGroup', 'Remove-SqlElasticJob', 'Remove-SqlElasticJobAgent', 'Remove-SqlElasticJobCredential', 'Remove-SqlElasticJobStep', 'Remove-SqlElasticJobTargetGroup', 'Set-SqlElasticJob', 'Set-SqlElasticJobAgent', 'Set-SqlElasticJobCredential', 'Set-SqlElasticJobStep', 'Start-SqlElasticJob', 'Stop-SqlElasticJob', 'Test-SqlElasticJobEnvironment' -Parameter 'ServerName' -Name 'PSAzureSQLElasticJob.ServerName'
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobTarget', 'Remove-SqlElasticJobTarget', 'Grant-SqlElasticJobTargetDatabaseAccess' -Parameter 'TargetServerName' -Name 'PSAzureSQLElasticJob.ServerName'
Register-PSFTeppArgumentCompleter -Command 'Get-SqlElasticJobExecutionOutput' -Parameter 'OutputServerName' -Name 'PSAzureSQLElasticJob.ServerName'

# -DatabaseName / -TargetDatabaseName / -OutputDatabaseName: databases on whichever server was already typed.
Register-PSFTeppArgumentCompleter -Command 'New-SqlElasticJobAgent', 'New-SqlElasticJobEnvironment', 'Test-SqlElasticJobEnvironment' -Parameter 'DatabaseName' -Name 'PSAzureSQLElasticJob.DatabaseName'
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobTarget', 'Remove-SqlElasticJobTarget', 'Grant-SqlElasticJobTargetDatabaseAccess' -Parameter 'TargetDatabaseName' -Name 'PSAzureSQLElasticJob.DatabaseName'
Register-PSFTeppArgumentCompleter -Command 'Get-SqlElasticJobExecutionOutput' -Parameter 'OutputDatabaseName' -Name 'PSAzureSQLElasticJob.DatabaseName'

# -AgentName: every command scoped to a specific Elastic Job agent.
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobStep', 'Add-SqlElasticJobTarget', 'Get-SqlElasticJob', 'Get-SqlElasticJobCredential', 'Get-SqlElasticJobStep', 'Get-SqlElasticJobTargetGroup', 'New-SqlElasticJob', 'New-SqlElasticJobCredential', 'New-SqlElasticJobTargetGroup', 'Remove-SqlElasticJob', 'Remove-SqlElasticJobCredential', 'Remove-SqlElasticJobStep', 'Remove-SqlElasticJobTarget', 'Remove-SqlElasticJobTargetGroup', 'Set-SqlElasticJob', 'Set-SqlElasticJobCredential', 'Set-SqlElasticJobStep', 'Start-SqlElasticJob', 'Stop-SqlElasticJob' -Parameter 'AgentName' -Name 'PSAzureSQLElasticJob.AgentName'
Register-PSFTeppArgumentCompleter -Command 'Get-SqlElasticJobAgent', 'Set-SqlElasticJobAgent', 'Remove-SqlElasticJobAgent' -Parameter 'Name' -Name 'PSAzureSQLElasticJob.AgentName'

# -Name (job) / -JobName: an existing job on the agent already typed.
Register-PSFTeppArgumentCompleter -Command 'Get-SqlElasticJob', 'New-SqlElasticJob', 'Remove-SqlElasticJob', 'Set-SqlElasticJob', 'Start-SqlElasticJob', 'Stop-SqlElasticJob' -Parameter 'Name' -Name 'PSAzureSQLElasticJob.JobName'
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobStep', 'Get-SqlElasticJobStep', 'Remove-SqlElasticJobStep', 'Set-SqlElasticJobStep' -Parameter 'JobName' -Name 'PSAzureSQLElasticJob.JobName'

# -Name (step): an existing step on the job already typed.
Register-PSFTeppArgumentCompleter -Command 'Get-SqlElasticJobStep', 'Remove-SqlElasticJobStep', 'Set-SqlElasticJobStep' -Parameter 'Name' -Name 'PSAzureSQLElasticJob.StepName'

# -Name (credential) / -CredentialName / -OutputCredentialName / -RefreshCredentialName.
Register-PSFTeppArgumentCompleter -Command 'Get-SqlElasticJobCredential', 'New-SqlElasticJobCredential', 'Remove-SqlElasticJobCredential', 'Set-SqlElasticJobCredential' -Parameter 'Name' -Name 'PSAzureSQLElasticJob.CredentialName'
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobStep', 'Set-SqlElasticJobStep' -Parameter 'CredentialName' -Name 'PSAzureSQLElasticJob.CredentialName'
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobStep' -Parameter 'OutputCredentialName' -Name 'PSAzureSQLElasticJob.CredentialName'
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobTarget', 'Remove-SqlElasticJobTarget' -Parameter 'RefreshCredentialName' -Name 'PSAzureSQLElasticJob.CredentialName'

# -Name (target group) / -TargetGroupName.
Register-PSFTeppArgumentCompleter -Command 'Get-SqlElasticJobTargetGroup', 'New-SqlElasticJobTargetGroup', 'Remove-SqlElasticJobTargetGroup' -Parameter 'Name' -Name 'PSAzureSQLElasticJob.TargetGroupName'
Register-PSFTeppArgumentCompleter -Command 'Add-SqlElasticJobStep', 'Add-SqlElasticJobTarget', 'Remove-SqlElasticJobTarget', 'Set-SqlElasticJobStep' -Parameter 'TargetGroupName' -Name 'PSAzureSQLElasticJob.TargetGroupName'
