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

Describe 'Assert-AzContext' {
    Context 'When no Azure context is available' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith { $null }
        }

        It 'Should throw an actionable error naming Connect-AzAccount' {
            InModuleScope -ModuleName $script:moduleName {
                { Assert-AzContext } | Should -Throw -ExpectedMessage '*Connect-AzAccount*'
            }
        }
    }

    Context 'When a context exists but carries no subscription' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ Subscription = $null }
            }
        }

        It 'Should throw rather than return a half-initialised context' {
            InModuleScope -ModuleName $script:moduleName {
                { Assert-AzContext } | Should -Throw -ExpectedMessage '*Connect-AzAccount*'
            }
        }
    }

    Context 'When a valid context is available' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{
                    Subscription = [PSCustomObject]@{ Id = '00000000-0000-0000-0000-000000000001' }
                }
            }
        }

        It 'Should return the context' {
            InModuleScope -ModuleName $script:moduleName {
                $result = Assert-AzContext

                $result.Subscription.Id | Should -Be '00000000-0000-0000-0000-000000000001'
            }
        }

        It 'Should accept a matching subscription id' {
            InModuleScope -ModuleName $script:moduleName {
                { Assert-AzContext -SubscriptionId '00000000-0000-0000-0000-000000000001' } |
                    Should -Not -Throw
            }
        }

        It 'Should throw when the requested subscription differs from the context' {
            InModuleScope -ModuleName $script:moduleName {
                { Assert-AzContext -SubscriptionId '00000000-0000-0000-0000-000000000002' } |
                    Should -Throw -ExpectedMessage '*Set-AzContext*'
            }
        }
    }
}
