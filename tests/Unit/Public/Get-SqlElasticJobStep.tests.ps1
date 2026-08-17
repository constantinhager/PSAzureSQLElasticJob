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

Describe 'Get-SqlElasticJobStep' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        $script:stepParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
            JobName           = 'nightly'
        }
    }

    Context 'When the step exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ StepName = 'rebuild' }
            }
        }

        It 'Should return the step' {
            $result = Get-SqlElasticJobStep @script:stepParameters -Name 'rebuild'

            $result.StepName | Should -Be 'rebuild'
        }

        It 'Should not pass a name filter when none was supplied' {
            $null = Get-SqlElasticJobStep @script:stepParameters

            Should -Invoke -CommandName Get-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $null -eq $Name
            }
        }
    }

    Context 'When the step does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should return null instead of throwing' {
            $result = Get-SqlElasticJobStep @script:stepParameters -Name 'missing'

            $result | Should -BeNullOrEmpty
        }
    }
}
