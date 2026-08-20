BeforeAll {
    $script:moduleName = 'PSAzureSQLElasticJob'
    $script:requiredEnvironmentVariables = @(
        'PSAZURESQLELASTICJOB_TEST_RESOURCE_GROUP'
        'PSAZURESQLELASTICJOB_TEST_SERVER'
        'PSAZURESQLELASTICJOB_TEST_DATABASE'
    )

    $missingEnvironmentVariables = $script:requiredEnvironmentVariables |
    Where-Object { [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_)) }

    if ($missingEnvironmentVariables) {
        throw ('Integration tests require these environment variables: {0}' -f ($missingEnvironmentVariables -join ', '))
    }

    Remove-Module -Name $script:moduleName -Force -ErrorAction SilentlyContinue

    Get-Module -Name $script:moduleName -ListAvailable |
    Select-Object -First 1 |
    Import-Module -Force -ErrorAction Stop

    $script:resourceGroupName = $env:PSAZURESQLELASTICJOB_TEST_RESOURCE_GROUP
    $script:serverName = $env:PSAZURESQLELASTICJOB_TEST_SERVER
    $script:databaseName = $env:PSAZURESQLELASTICJOB_TEST_DATABASE
    $script:resourceSuffix = [guid]::NewGuid().ToString('N').Substring(0, 10)
    $script:agentName = "psej-it-agent-$script:resourceSuffix"
    $script:jobName = "psej-it-job-$script:resourceSuffix"
    $script:targetGroupName = "psej-it-targets-$script:resourceSuffix"
    $script:stepName = "psej-it-step-$script:resourceSuffix"
}

AfterAll {
    $cleanupErrors = [System.Collections.Generic.List[System.Management.Automation.ErrorRecord]]::new()

    foreach ($cleanupAction in @(
            {
                Remove-SqlElasticJobStep -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -AgentName $script:agentName -JobName $script:jobName -Name $script:stepName -ErrorAction Stop
            },
            {
                Remove-SqlElasticJobTarget -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -AgentName $script:agentName -TargetGroupName $script:targetGroupName -TargetServerName $script:serverName -TargetDatabaseName $script:databaseName -ErrorAction Stop
            },
            {
                Remove-SqlElasticJob -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -AgentName $script:agentName -Name $script:jobName -Force -ErrorAction Stop
            },
            {
                Remove-SqlElasticJobTargetGroup -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -AgentName $script:agentName -Name $script:targetGroupName -Force -ErrorAction Stop
            },
            {
                Remove-SqlElasticJobAgent -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -Name $script:agentName -ErrorAction Stop
            }
        )) {
        try {
            & $cleanupAction
        } catch {
            $cleanupErrors.Add($_)
        }
    }

    Remove-Module -Name $script:moduleName -Force -ErrorAction SilentlyContinue

    if ($cleanupErrors.Count -gt 0) {
        throw ('Azure integration-test cleanup failed:{0}{1}' -f [Environment]::NewLine, ($cleanupErrors -join [Environment]::NewLine))
    }
}

Describe 'Azure SQL Elastic Job lifecycle' -Tag 'Integration' {
    It 'Should create, retrieve, and remove uniquely named Elastic Job resources' {
        $environment = Test-SqlElasticJobEnvironment -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -DatabaseName $script:databaseName -AgentName $script:agentName
        $environment.ServerExists | Should -BeTrue
        $environment.DatabaseExists | Should -BeTrue
        $environment.AgentExists | Should -BeFalse

        $agent = New-SqlElasticJobAgent -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -DatabaseName $script:databaseName -Name $script:agentName
        $agent | Should -Not -BeNullOrEmpty

        $retrievedAgent = Get-SqlElasticJobAgent -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -Name $script:agentName
        $retrievedAgent.Name | Should -Be $script:agentName

        $job = New-SqlElasticJob -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -AgentName $script:agentName -Name $script:jobName -Description 'PSAzureSQLElasticJob integration test'
        $job | Should -Not -BeNullOrEmpty

        $targetGroup = New-SqlElasticJobTargetGroup -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -AgentName $script:agentName -Name $script:targetGroupName
        $targetGroup | Should -Not -BeNullOrEmpty

        $target = Add-SqlElasticJobTarget -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -AgentName $script:agentName -TargetGroupName $script:targetGroupName -TargetServerName $script:serverName -TargetDatabaseName $script:databaseName
        $target | Should -Not -BeNullOrEmpty

        $step = Add-SqlElasticJobStep -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -AgentName $script:agentName -JobName $script:jobName -Name $script:stepName -TargetGroupName $script:targetGroupName -CommandText 'SELECT 1;'
        $step | Should -Not -BeNullOrEmpty

        $retrievedStep = Get-SqlElasticJobStep -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -AgentName $script:agentName -JobName $script:jobName -Name $script:stepName
        $retrievedStep.Name | Should -Be $script:stepName

        $existingAgent = New-SqlElasticJobAgent -ResourceGroupName $script:resourceGroupName -ServerName $script:serverName -DatabaseName $script:databaseName -Name $script:agentName
        $existingAgent.Name | Should -Be $script:agentName
    }
}
