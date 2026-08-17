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

Describe 'Add-SqlElasticJobTarget' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Add-AzSqlElasticJobTarget -ModuleName $script:moduleName -MockWith {
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
        $null = Add-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -Confirm:$false

        Should -Invoke -CommandName Add-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $AgentServerName -eq 'sql-jobs' -and $ServerName -eq 'sql-prod'
        }
    }

    It 'Should add a single database target' {
        $null = Add-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -Confirm:$false

        Should -Invoke -CommandName Add-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $DatabaseName -eq 'AppDb'
        }
    }

    It 'Should add a whole server target without a database name' {
        $null = Add-SqlElasticJobTarget @script:targetParameters -RefreshCredentialName 'refreshcred' -Confirm:$false

        Should -Invoke -CommandName Add-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $null -eq $DatabaseName -and $RefreshCredentialName -eq 'refreshcred'
        }
    }

    It 'Should pass -Exclude through to Azure' {
        $null = Add-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -Exclude -Confirm:$false

        Should -Invoke -CommandName Add-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $Exclude -eq $true
        }
    }

    It 'Should not mark the target as excluded when -Exclude was not supplied' {
        $null = Add-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -Confirm:$false

        Should -Invoke -CommandName Add-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            -not $Exclude
        }
    }

    It 'Should add a shard map target' {
        $null = Add-SqlElasticJobTarget @script:targetParameters -ShardMapName 'customers' -DatabaseName 'ShardMapManager' -Confirm:$false

        Should -Invoke -CommandName Add-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $ShardMapName -eq 'customers' -and $DatabaseName -eq 'ShardMapManager'
        }
    }

    It 'Should add nothing when -WhatIf is used' {
        Add-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -WhatIf

        Should -Invoke -CommandName Add-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 0 -Exactly
    }

    Context 'When the caller is not signed in' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith { $null }
        }

        It 'Should throw before calling Azure' {
            { Add-SqlElasticJobTarget @script:targetParameters -DatabaseName 'AppDb' -Confirm:$false } |
                Should -Throw -ExpectedMessage '*Connect-AzAccount*'

            Should -Invoke -CommandName Add-AzSqlElasticJobTarget -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
