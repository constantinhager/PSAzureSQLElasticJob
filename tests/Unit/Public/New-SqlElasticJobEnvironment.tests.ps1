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

Describe 'New-SqlElasticJobEnvironment' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Get-AzResourceGroup -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ ResourceGroupName = 'rg' }
        }

        Mock -CommandName New-AzSqlServer -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ ServerName = 'srv' }
        }

        Mock -CommandName New-AzSqlDatabase -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ DatabaseName = 'jobdb' }
        }

        Mock -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ AgentName = 'agent01' }
        }

        $script:credential = [System.Management.Automation.PSCredential]::new(
            'sqladmin',
            (ConvertTo-SecureString -String 'not-a-real-password' -AsPlainText -Force))

        $script:baseParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            DatabaseName      = 'jobdb'
            AgentName         = 'agent01'
        }
    }

    Context 'When nothing exists yet' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith { throw 'Server does not exist.' }
            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith { throw 'Database does not exist.' }
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith { throw 'Agent does not exist.' }
        }

        It 'Should create the server, the database and the agent' {
            $result = New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -ServerAdministratorCredential $script:credential -Confirm:$false

            $result.CreatedServer | Should -BeTrue
            $result.CreatedDatabase | Should -BeTrue
            $result.CreatedAgent | Should -BeTrue
        }

        It 'Should default the job database to service objective S1' {
            $null = New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -ServerAdministratorCredential $script:credential -Confirm:$false

            Should -Invoke -CommandName New-AzSqlDatabase -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $RequestedServiceObjectiveName -eq 'S1'
            }
        }

        It 'Should honour an explicit service objective' {
            $null = New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -ServerAdministratorCredential $script:credential -ServiceObjectiveName 'S2' -Confirm:$false

            Should -Invoke -CommandName New-AzSqlDatabase -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $RequestedServiceObjectiveName -eq 'S2'
            }
        }

        It 'Should create nothing when -WhatIf is used' {
            $null = New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -ServerAdministratorCredential $script:credential -WhatIf

            Should -Invoke -CommandName New-AzSqlServer -ModuleName $script:moduleName -Times 0 -Exactly
            Should -Invoke -CommandName New-AzSqlDatabase -ModuleName $script:moduleName -Times 0 -Exactly
            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should refuse to create a server without a location' {
            { New-SqlElasticJobEnvironment @script:baseParameters -ServerAdministratorCredential $script:credential -Confirm:$false } |
                Should -Throw -ExpectedMessage '*-Location*'
        }

        It 'Should refuse to create a server without an administrator credential' {
            { New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -Confirm:$false } |
                Should -Throw -ExpectedMessage '*-ServerAdministratorCredential*'
        }
    }

    Context 'When everything already exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ ServerName = 'srv' }
            }

            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ DatabaseName = 'jobdb' }
            }

            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'agent01' }
            }
        }

        It 'Should create nothing' {
            $result = New-SqlElasticJobEnvironment @script:baseParameters -Confirm:$false

            $result.CreatedServer | Should -BeFalse
            $result.CreatedDatabase | Should -BeFalse
            $result.CreatedAgent | Should -BeFalse

            Should -Invoke -CommandName New-AzSqlServer -ModuleName $script:moduleName -Times 0 -Exactly
            Should -Invoke -CommandName New-AzSqlDatabase -ModuleName $script:moduleName -Times 0 -Exactly
            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should not require a location or credential' {
            { New-SqlElasticJobEnvironment @script:baseParameters -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'When only the agent is missing' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ ServerName = 'srv' }
            }

            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ DatabaseName = 'jobdb' }
            }

            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith { throw 'Agent does not exist.' }
        }

        It 'Should create only the agent' {
            $result = New-SqlElasticJobEnvironment @script:baseParameters -Confirm:$false

            $result.CreatedServer | Should -BeFalse
            $result.CreatedDatabase | Should -BeFalse
            $result.CreatedAgent | Should -BeTrue

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 1 -Exactly
        }
    }

    Context 'When the resource group does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzResourceGroup -ModuleName $script:moduleName -MockWith {
                throw 'Resource group could not be found.'
            }
        }

        It 'Should throw and create nothing' {
            { New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -ServerAdministratorCredential $script:credential -Confirm:$false } |
                Should -Throw -ExpectedMessage '*Resource group*'

            Should -Invoke -CommandName New-AzSqlServer -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the caller cannot read the server due to permissions' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith {
                throw 'The client does not have authorization to perform action.'
            }
        }

        It 'Should surface the authorization error instead of trying to create the server' {
            { New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -ServerAdministratorCredential $script:credential -Confirm:$false } |
                Should -Throw -ExpectedMessage '*authorization*'

            Should -Invoke -CommandName New-AzSqlServer -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
