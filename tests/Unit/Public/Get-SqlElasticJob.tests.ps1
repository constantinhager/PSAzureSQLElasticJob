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

Describe 'Get-SqlElasticJob' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        $script:agentParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
        }
    }

    Context 'When the job exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ JobName = 'nightly' }
            }
        }

        It 'Should return the job' {
            $result = Get-SqlElasticJob @script:agentParameters -Name 'nightly'

            $result.JobName | Should -Be 'nightly'
        }

        It 'Should not pass a name filter when none was supplied' {
            $null = Get-SqlElasticJob @script:agentParameters

            Should -Invoke -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $null -eq $Name
            }
        }
    }

    Context 'When the job does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should return null instead of throwing' {
            $result = Get-SqlElasticJob @script:agentParameters -Name 'missing'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When the caller is not signed in' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith { $null }
        }

        It 'Should throw before calling Azure' {
            Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName

            { Get-SqlElasticJob @script:agentParameters -Name 'nightly' } |
                Should -Throw -ExpectedMessage '*Connect-AzAccount*'

            Should -Invoke -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
