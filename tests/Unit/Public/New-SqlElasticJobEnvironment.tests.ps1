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

    Context 'When assigning a user-assigned managed identity to a new agent' {
        BeforeAll {
            $script:identityId = '/subscriptions/sub-1/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-jobs'

            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ ServerName = 'srv' }
            }

            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ DatabaseName = 'jobdb' }
            }

            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith { throw 'Agent does not exist.' }

            Mock -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{
                    AgentName = 'agent01'
                    Identity  = [PSCustomObject]@{
                        UserAssignedIdentities = @{ $script:identityId = @{} }
                    }
                }
            }
        }

        It 'Should require -UserAssignedIdentityId when -UseUserAssignedManagedIdentity is used' {
            { New-SqlElasticJobEnvironment @script:baseParameters -UseUserAssignedManagedIdentity -Confirm:$false } |
            Should -Throw -ExpectedMessage '*-UserAssignedIdentityId*'

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should create the agent with the identity in one step' {
            $result = New-SqlElasticJobEnvironment @script:baseParameters -UseUserAssignedManagedIdentity -UserAssignedIdentityId $script:identityId -Confirm:$false

            $result.CreatedAgent | Should -BeTrue
            $result.AssignedIdentity | Should -BeTrue

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $IdentityType -eq 'UserAssigned' -and $UserAssignedIdentityId -contains $script:identityId
            }
        }
    }

    Context 'When assigning a user-assigned managed identity to an existing agent' {
        BeforeAll {
            $script:identityId = '/subscriptions/sub-1/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-jobs'

            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ ServerName = 'srv' }
            }

            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ DatabaseName = 'jobdb' }
            }

            Mock -CommandName Set-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{
                    AgentName = 'agent01'
                    Identity  = [PSCustomObject]@{
                        UserAssignedIdentities = @{ $script:identityId = @{} }
                    }
                }
            }
        }

        It 'Should assign the identity when the agent does not have it yet' {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'agent01'; Identity = $null }
            }

            $result = New-SqlElasticJobEnvironment @script:baseParameters -UseUserAssignedManagedIdentity -UserAssignedIdentityId $script:identityId -Confirm:$false

            $result.AssignedIdentity | Should -BeTrue

            Should -Invoke -CommandName Set-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $IdentityType -eq 'UserAssigned' -and $UserAssignedIdentityId -contains $script:identityId
            }
        }

        It 'Should not reassign the identity when the agent already has it' {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{
                    AgentName = 'agent01'
                    Identity  = [PSCustomObject]@{
                        UserAssignedIdentities = @{ $script:identityId = @{} }
                    }
                }
            }

            $result = New-SqlElasticJobEnvironment @script:baseParameters -UseUserAssignedManagedIdentity -UserAssignedIdentityId $script:identityId -Confirm:$false

            $result.AssignedIdentity | Should -BeFalse

            Should -Invoke -CommandName Set-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should stop without marking the identity as assigned when Set-AzSqlElasticJobAgent fails' {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'agent01'; Identity = $null }
            }

            Mock -CommandName Set-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                Write-Error 'Identity assignment failed.'
            }

            { New-SqlElasticJobEnvironment @script:baseParameters -UseUserAssignedManagedIdentity -UserAssignedIdentityId $script:identityId -Confirm:$false } |
            Should -Throw -ExpectedMessage '*Identity assignment failed*'
        }
    }

    Context 'When creating a user-assigned managed identity that does not exist yet' {
        BeforeAll {
            $script:identityId = '/subscriptions/sub-1/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-jobs'

            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ ServerName = 'srv' }
            }

            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ DatabaseName = 'jobdb' }
            }

            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith { throw 'Agent does not exist.' }

            Mock -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{
                    AgentName = 'agent01'
                    Identity  = [PSCustomObject]@{
                        UserAssignedIdentities = @{ $script:identityId = @{} }
                    }
                }
            }

            Mock -CommandName Get-AzUserAssignedIdentity -ModuleName $script:moduleName -MockWith { throw 'Identity does not exist.' }

            Mock -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ Id = $script:identityId; Name = 'id-jobs' }
            }
        }

        It 'Should require -UserAssignedIdentityName' {
            { New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -UseUserAssignedManagedIdentity -CreateUserAssignedManagedIdentity -Confirm:$false } |
            Should -Throw -ExpectedMessage '*-UserAssignedIdentityName*'

            Should -Invoke -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should require -CreateUserAssignedManagedIdentity to be used with -UseUserAssignedManagedIdentity' {
            { New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -CreateUserAssignedManagedIdentity -UserAssignedIdentityName 'id-jobs' -Confirm:$false } |
            Should -Throw -ExpectedMessage '*-UseUserAssignedManagedIdentity*'

            Should -Invoke -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should create the identity and assign its resource ID to the agent' {
            $result = New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -UseUserAssignedManagedIdentity -CreateUserAssignedManagedIdentity -UserAssignedIdentityName 'id-jobs' -Confirm:$false

            $result.AssignedIdentity | Should -BeTrue

            Should -Invoke -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'id-jobs' -and $Location -eq 'westeurope'
            }

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $UserAssignedIdentityId -contains $script:identityId
            }
        }

        It 'Should stop without creating the agent when identity creation fails' {
            Mock -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -MockWith {
                Write-Error 'Identity creation failed.'
            }

            { New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -UseUserAssignedManagedIdentity -CreateUserAssignedManagedIdentity -UserAssignedIdentityName 'id-jobs' -Confirm:$false } |
            Should -Throw -ExpectedMessage '*Identity creation failed*'

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should stop without creating the agent when Azure returns no resource ID for the identity' {
            Mock -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ Id = ''; Name = 'id-jobs' }
            }

            { New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -UseUserAssignedManagedIdentity -CreateUserAssignedManagedIdentity -UserAssignedIdentityName 'id-jobs' -Confirm:$false } |
            Should -Throw -ExpectedMessage '*no resource ID*'

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When server creation fails' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith { throw 'Server does not exist.' }
            Mock -CommandName New-AzSqlServer -ModuleName $script:moduleName -MockWith {
                Write-Error 'Server name is already in use.'
            }
        }

        It 'Should stop without marking the server as created or creating dependent resources' {
            { New-SqlElasticJobEnvironment @script:baseParameters -Location 'westeurope' -ServerAdministratorCredential $script:credential -Confirm:$false } |
            Should -Throw -ExpectedMessage '*Server name is already in use*'

            Should -Invoke -CommandName New-AzSqlDatabase -ModuleName $script:moduleName -Times 0 -Exactly
            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When database creation fails' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ ServerName = 'srv' }
            }
            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith { throw 'Database does not exist.' }
            Mock -CommandName New-AzSqlDatabase -ModuleName $script:moduleName -MockWith {
                Write-Error 'Database provisioning failed.'
            }
        }

        It 'Should stop without marking the database as created or creating an agent' {
            { New-SqlElasticJobEnvironment @script:baseParameters -Confirm:$false } |
            Should -Throw -ExpectedMessage '*Database provisioning failed*'

            Should -Invoke -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When agent creation fails' {
        BeforeAll {
            Mock -CommandName Get-AzSqlServer -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ ServerName = 'srv' }
            }
            Mock -CommandName Get-AzSqlDatabase -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ DatabaseName = 'jobdb' }
            }
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith { throw 'Agent does not exist.' }
            Mock -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                Write-Error 'Agent provisioning failed.'
            }
        }

        It 'Should stop without marking the agent as created' {
            { New-SqlElasticJobEnvironment @script:baseParameters -Confirm:$false } |
            Should -Throw -ExpectedMessage '*Agent provisioning failed*'
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
