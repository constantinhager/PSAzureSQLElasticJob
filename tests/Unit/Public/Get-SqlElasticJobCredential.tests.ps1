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

Describe 'Get-SqlElasticJobCredential' {
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

    Context 'When the credential exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ CredentialName = 'jobuser' }
            }
        }

        It 'Should return the credential' {
            $result = Get-SqlElasticJobCredential @script:agentParameters -Name 'jobuser'

            $result.CredentialName | Should -Be 'jobuser'
        }

        It 'Should not pass a name filter when none was supplied' {
            $null = Get-SqlElasticJobCredential @script:agentParameters

            Should -Invoke -CommandName Get-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $null -eq $Name
            }
        }
    }

    Context 'When the credential does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should return null instead of throwing' {
            $result = Get-SqlElasticJobCredential @script:agentParameters -Name 'missing'

            $result | Should -BeNullOrEmpty
        }
    }
}
