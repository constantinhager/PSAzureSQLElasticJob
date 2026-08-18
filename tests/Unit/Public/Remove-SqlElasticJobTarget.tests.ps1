BeforeAll {
    $script:moduleName = 'PSAzureSQLElasticJob'

    Remove-Module -Name $script:moduleName -Force -ErrorAction SilentlyContinue

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
            Import-Module -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module -Name $script:moduleName -Force -ErrorAction SilentlyContinue
}

Describe 'Remove-SqlElasticJobTarget' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Remove-AzSqlElasticJobTarget -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ TargetGroupName = 'all-databases' }
        }

        $script:targetParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'sql-jobs'
            AgentName         = 'agent01'
            TargetGroupName   = 'all-databases'
            TargetServerName  = 'sql-prod'
        }
    }

    It 'Should map the agent server and the target server to the correct Azure parameters' {
        $null = Remove-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -Confirm:$false

        Should -Invoke -CommandName Remove-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $AgentServerName -eq 'sql-jobs' -and $ServerName -eq 'sql-prod'
        }
    }

    It 'Should remove a single database target' {
        $null = Remove-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -Confirm:$false

        Should -Invoke -CommandName Remove-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $DatabaseName -eq 'AppDb'
        }
    }

    It 'Should remove an elastic pool target' {
        $null = Remove-SqlElasticJobTarget @script:targetParameters -ElasticPoolName 'pool01' -Confirm:$false

        Should -Invoke -CommandName Remove-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $ElasticPoolName -eq 'pool01'
        }
    }

    It 'Should remove nothing when -WhatIf is used' {
        Remove-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -WhatIf

        Should -Invoke -CommandName Remove-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 0 -Exactly
    }

    Context 'When the caller is not signed in' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith { $null }
        }

        It 'Should throw before calling Azure' {
            { Remove-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -Confirm:$false } |
                Should -Throw -ExpectedMessage '*Connect-AzAccount*'

            Should -Invoke -CommandName Remove-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
