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

Describe 'Get-SqlElasticJobTargetGroup' {
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

    Context 'When the target group exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ TargetGroupName = 'all-databases' }
            }
        }

        It 'Should return the target group' {
            $result = Get-SqlElasticJobTargetGroup @script:agentParameters -Name 'all-databases'

            $result.TargetGroupName | Should -Be 'all-databases'
        }

        It 'Should not pass a name filter when none was supplied' {
            $null = Get-SqlElasticJobTargetGroup @script:agentParameters

            Should -Invoke -CommandName Get-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $null -eq $Name
            }
        }
    }

    Context 'When the target group does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should return null instead of throwing' {
            $result = Get-SqlElasticJobTargetGroup @script:agentParameters -Name 'missing'

            $result | Should -BeNullOrEmpty
        }
    }
}
