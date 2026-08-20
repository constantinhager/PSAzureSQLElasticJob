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

Describe 'Assert-AzResourceProviderRegistered' {
    BeforeAll {
        Mock -CommandName Start-Sleep -ModuleName $script:moduleName -MockWith { }
        Mock -CommandName Register-AzResourceProvider -ModuleName $script:moduleName -MockWith { }
    }

    Context 'When the provider is already registered' {
        BeforeAll {
            Mock -CommandName Get-AzResourceProvider -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ ProviderNamespace = 'Microsoft.ManagedIdentity'; RegistrationState = 'Registered' }
            }
        }

        It 'Should not register the provider' {
            InModuleScope -ModuleName $script:moduleName {
                { Assert-AzResourceProviderRegistered -ProviderNamespace 'Microsoft.ManagedIdentity' } | Should -Not -Throw
            }

            Should -Invoke -CommandName Register-AzResourceProvider -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the provider is not registered but finishes registering' {
        BeforeAll {
            $script:callCount = 0

            Mock -CommandName Get-AzResourceProvider -ModuleName $script:moduleName -MockWith {
                $script:callCount++

                if ($script:callCount -lt 2) {
                    [PSCustomObject]@{ ProviderNamespace = 'Microsoft.ManagedIdentity'; RegistrationState = 'NotRegistered' }
                } else {
                    [PSCustomObject]@{ ProviderNamespace = 'Microsoft.ManagedIdentity'; RegistrationState = 'Registered' }
                }
            }

            Mock -CommandName Register-AzResourceProvider -ModuleName $script:moduleName -MockWith { }
        }

        It 'Should register the provider and wait for it to finish' {
            InModuleScope -ModuleName $script:moduleName {
                { Assert-AzResourceProviderRegistered -ProviderNamespace 'Microsoft.ManagedIdentity' -PollIntervalSeconds 1 } | Should -Not -Throw
            }

            Should -Invoke -CommandName Register-AzResourceProvider -ModuleName $script:moduleName -Times 1 -Exactly
        }
    }

    Context 'When the provider never finishes registering' {
        BeforeAll {
            Mock -CommandName Get-AzResourceProvider -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ ProviderNamespace = 'Microsoft.ManagedIdentity'; RegistrationState = 'NotRegistered' }
            }

            Mock -CommandName Register-AzResourceProvider -ModuleName $script:moduleName -MockWith { }
        }

        It 'Should throw once the timeout elapses' {
            InModuleScope -ModuleName $script:moduleName {
                { Assert-AzResourceProviderRegistered -ProviderNamespace 'Microsoft.ManagedIdentity' -TimeoutSeconds 2 -PollIntervalSeconds 1 } |
                Should -Throw -ExpectedMessage '*did not finish registering*'
            }
        }
    }
}
