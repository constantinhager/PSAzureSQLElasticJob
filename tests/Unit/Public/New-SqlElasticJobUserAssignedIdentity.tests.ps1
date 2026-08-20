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

Describe 'New-SqlElasticJobUserAssignedIdentity' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Id = '/subscriptions/sub-1/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-jobs'; Name = 'id-jobs' }
        }
    }

    Context 'When the identity already exists' {
        BeforeAll {
            Mock -CommandName Get-AzUserAssignedIdentity -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ Id = '/subscriptions/sub-1/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-jobs'; Name = 'id-jobs' }
            }
        }

        It 'Should return the existing identity without creating one' {
            $result = New-SqlElasticJobUserAssignedIdentity -ResourceGroupName 'rg' -Name 'id-jobs'

            $result.Name | Should -Be 'id-jobs'

            Should -Invoke -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the identity does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzUserAssignedIdentity -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should create the identity' {
            $result = New-SqlElasticJobUserAssignedIdentity -ResourceGroupName 'rg' -Name 'id-jobs' -Location 'westeurope' -Confirm:$false

            $result.Name | Should -Be 'id-jobs'

            Should -Invoke -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Location -eq 'westeurope'
            }
        }

        It 'Should refuse to create the identity without a location' {
            { New-SqlElasticJobUserAssignedIdentity -ResourceGroupName 'rg' -Name 'id-jobs' -Confirm:$false } |
            Should -Throw -ExpectedMessage '*-Location*'

            Should -Invoke -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should create nothing when -WhatIf is used' {
            New-SqlElasticJobUserAssignedIdentity -ResourceGroupName 'rg' -Name 'id-jobs' -Location 'westeurope' -WhatIf

            Should -Invoke -CommandName New-AzUserAssignedIdentity -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
