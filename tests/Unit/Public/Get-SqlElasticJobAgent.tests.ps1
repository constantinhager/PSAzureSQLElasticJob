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

Describe 'Get-SqlElasticJobAgent' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }
    }

    Context 'When the agent exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'agent01' }
            }
        }

        It 'Should return the agent' {
            $result = Get-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01'

            $result.AgentName | Should -Be 'agent01'
        }

        It 'Should query Azure exactly once' {
            $null = Get-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01'

            Should -Invoke -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 1 -Exactly
        }
    }

    Context 'When the agent does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should return null instead of throwing' {
            $result = Get-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'missing'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When the caller is not signed in' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith { $null }
        }

        It 'Should throw before calling Azure' {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName

            { Get-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -Name 'agent01' } |
                Should -Throw -ExpectedMessage '*Connect-AzAccount*'

            Should -Invoke -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
