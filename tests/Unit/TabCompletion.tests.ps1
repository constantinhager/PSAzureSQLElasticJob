BeforeAll {
    $script:moduleName = 'PSAzureSQLElasticJob'

    Remove-Module -Name $script:moduleName -Force -ErrorAction SilentlyContinue

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
            Import-Module -Force -ErrorAction Stop

    Mock -CommandName Get-AzResourceGroup -ModuleName $script:moduleName -MockWith {
        [PSCustomObject]@{ ResourceGroupName = 'rg-jobs' }
    }

    Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith {
        [PSCustomObject]@{ ServerName = 'sql-jobs'; ResourceGroupName = 'rg-jobs' }
    }

    Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith {
        [PSCustomObject]@{ DatabaseName = 'AppDb' }
    }

    Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
        [PSCustomObject]@{ AgentName = 'agent01' }
    }

    Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
        [PSCustomObject]@{ JobName = 'nightly-report' }
    }

    Mock -CommandName Get-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
        [PSCustomObject]@{ StepName = 'collect-counts' }
    }

    Mock -CommandName Get-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
        [PSCustomObject]@{ CredentialName = 'jobuser' }
    }

    Mock -CommandName Get-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -MockWith {
        [PSCustomObject]@{ TargetGroupName = 'all-databases' }
    }

    function script:Complete
    {
        param
        (
            [Parameter(Mandatory)]
            [System.String]
            $InputScript
        )

        (TabExpansion2 -InputScript $InputScript -CursorColumn $InputScript.Length).CompletionMatches.CompletionText
    }
}

AfterAll {
    Remove-Module -Name $script:moduleName -Force -ErrorAction SilentlyContinue
}

Describe 'Tab completion' {
    It 'Should complete -ResourceGroupName' {
        Complete "Get-SqlElasticJob -ResourceGroupName " | Should -Contain 'rg-jobs'
    }

    It 'Should complete -ServerName once -ResourceGroupName is given' {
        Complete "Get-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName " | Should -Contain 'sql-jobs'
    }

    It 'Should complete -TargetServerName the same way as -ServerName' {
        Complete "Add-SqlElasticJobTarget -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -TargetGroupName 'all-databases' -TargetServerName " | Should -Contain 'sql-jobs'
    }

    It 'Should complete -DatabaseName once -ServerName is given' {
        Complete "New-SqlElasticJobAgent -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -DatabaseName " | Should -Contain 'AppDb'
    }

    It 'Should complete -AgentName once -ResourceGroupName and -ServerName are given' {
        Complete "Get-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName " | Should -Contain 'agent01'
    }

    It 'Should complete job -Name once -AgentName is given' {
        Complete "Start-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name " | Should -Contain 'nightly-report'
    }

    It 'Should complete step -Name once -JobName is given' {
        Complete "Get-SqlElasticJobStep -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -JobName 'nightly-report' -Name " | Should -Contain 'collect-counts'
    }

    It 'Should complete credential -Name' {
        Complete "Get-SqlElasticJobCredential -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name " | Should -Contain 'jobuser'
    }

    It 'Should complete -CredentialName on Add-SqlElasticJobStep the same way' {
        Complete "Add-SqlElasticJobStep -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -JobName 'nightly-report' -Name 'step' -TargetGroupName 'all-databases' -CommandText 'SELECT 1' -CredentialName " | Should -Contain 'jobuser'
    }

    It 'Should complete target group -Name' {
        Complete "Get-SqlElasticJobTargetGroup -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name " | Should -Contain 'all-databases'
    }

    It 'Should complete -TargetGroupName on Add-SqlElasticJobTarget the same way' {
        Complete "Add-SqlElasticJobTarget -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -TargetGroupName " | Should -Contain 'all-databases'
    }
}
