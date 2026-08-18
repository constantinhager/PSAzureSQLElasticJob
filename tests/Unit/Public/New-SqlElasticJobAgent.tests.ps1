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

Describe 'New-SqlElasticJobAgent' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ AgentName = 'agent01'; Created = $true }
        }
    }

    Context 'When the agent already exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'agent01'; Created = $false }
            }
        }

        It 'Should return the existing agent without creating one' {
            $result = New-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -DatabaseName 'jobdb' -Name 'agent01'

            $result.Created | Should -BeFalse

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the agent does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should create the agent' {
            $result = New-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -DatabaseName 'jobdb' -Name 'agent01'

            $result.Created | Should -BeTrue

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should pass the job database through to Azure' {
            $null = New-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -DatabaseName 'jobdb' -Name 'agent01'

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $DatabaseName -eq 'jobdb'
            }
        }

        It 'Should create nothing when -WhatIf is used' {
            New-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -DatabaseName 'jobdb' -Name 'agent01' -WhatIf

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
