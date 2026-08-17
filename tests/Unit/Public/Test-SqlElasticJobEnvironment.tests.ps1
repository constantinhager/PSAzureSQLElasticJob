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

Describe 'Test-SqlElasticJobEnvironment' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        $script:baseParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            DatabaseName      = 'jobdb'
            AgentName         = 'agent01'
        }
    }

    Context 'When the environment is complete' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith { [PSCustomObject]@{ ServerName = 'srv' } }
            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith { [PSCustomObject]@{ DatabaseName = 'jobdb' } }
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith { [PSCustomObject]@{ AgentName = 'agent01' } }
        }

        It 'Should report every part as present' {
            $result = Test-SqlElasticJobEnvironment @script:baseParameters

            $result.ServerExists | Should -BeTrue
            $result.DatabaseExists | Should -BeTrue
            $result.AgentExists | Should -BeTrue
            $result.IsComplete | Should -BeTrue
        }

        It 'Should echo back the identifying parameters' {
            $result = Test-SqlElasticJobEnvironment @script:baseParameters

            $result.ResourceGroupName | Should -Be 'rg'
            $result.ServerName | Should -Be 'srv'
            $result.DatabaseName | Should -Be 'jobdb'
            $result.AgentName | Should -Be 'agent01'
        }
    }

    Context 'When the server is missing' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith { throw 'Server does not exist.' }
            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName
        }

        It 'Should report the environment as incomplete' {
            $result = Test-SqlElasticJobEnvironment @script:baseParameters

            $result.ServerExists | Should -BeFalse
            $result.IsComplete | Should -BeFalse
        }

        It 'Should not probe the database or agent on a missing server' {
            $null = Test-SqlElasticJobEnvironment @script:baseParameters

            Should -Invoke -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -Times 0 -Exactly
            Should -Invoke -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When only the agent is missing' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith { [PSCustomObject]@{ ServerName = 'srv' } }
            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith { [PSCustomObject]@{ DatabaseName = 'jobdb' } }
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith { throw 'Agent does not exist.' }
        }

        It 'Should report the agent as absent and the environment as incomplete' {
            $result = Test-SqlElasticJobEnvironment @script:baseParameters

            $result.ServerExists | Should -BeTrue
            $result.DatabaseExists | Should -BeTrue
            $result.AgentExists | Should -BeFalse
            $result.IsComplete | Should -BeFalse
        }
    }
}
