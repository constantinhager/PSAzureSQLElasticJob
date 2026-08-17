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

Describe 'Remove-SqlElasticJobAgent' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Remove-AzSqlElasticJobAgent -ModuleName $script:moduleName
    }

    Context 'When the agent exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'agent01' }
            }
        }

        It 'Should remove the agent' {
            Remove-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01' -Confirm:$false

            Should -Invoke -CommandName Remove-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should remove nothing when -WhatIf is used' {
            Remove-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01' -WhatIf

            Should -Invoke -CommandName Remove-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should return nothing by default' {
            $result = Remove-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01' -Confirm:$false

            $result | Should -BeNullOrEmpty
        }

        It 'Should return the removed agent with -PassThru' {
            $result = Remove-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01' -PassThru -Confirm:$false

            $result.AgentName | Should -Be 'agent01'
        }
    }

    Context 'When the agent does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should be a no-op by default' {
            { Remove-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'gone' -Confirm:$false } |
                Should -Not -Throw

            Should -Invoke -CommandName Remove-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should throw when -Strict is used' {
            { Remove-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'gone' -Strict -Confirm:$false } |
                Should -Throw -ExpectedMessage '*was not found*'
        }
    }
}
