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

Describe 'Set-SqlElasticJobAgent' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Set-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ AgentName = 'agent01' }
        }
    }

    Context 'When the agent exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'agent01' }
            }
        }

        It 'Should update the agent' {
            $null = Set-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01' -Tag @{ Env = 'Prod' }

            Should -Invoke -CommandName Set-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should update nothing when -WhatIf is used' {
            Set-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01' -Tag @{ Env = 'Prod' } -WhatIf

            Should -Invoke -CommandName Set-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the agent does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should throw rather than silently create an agent' {
            { Set-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01' -Tag @{ Env = 'Prod' } } |
                Should -Throw -ExpectedMessage '*was not found*'

            Should -Invoke -CommandName Set-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should warn instead of throwing when -EnableException is $false' {
            { Set-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01' -Tag @{ Env = 'Prod' } -EnableException $false -WarningAction SilentlyContinue } |
                Should -Not -Throw

            Should -Invoke -CommandName Set-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
