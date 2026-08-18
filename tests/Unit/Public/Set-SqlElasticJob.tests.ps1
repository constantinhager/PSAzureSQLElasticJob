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

Describe 'Set-SqlElasticJob' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Set-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ JobName = 'nightly' }
        }

        $script:jobParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
            Name              = 'nightly'
        }
    }

    Context 'When the job exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ JobName = 'nightly' }
            }
        }

        It 'Should update the job' {
            $null = Set-SqlElasticJob @script:jobParameters -Description 'updated'

            Should -Invoke -CommandName Set-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should send -Enable through to Azure when enabling a job' {
            $null = Set-SqlElasticJob @script:jobParameters -Enable

            Should -Invoke -CommandName Set-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Enable -eq $true
            }
        }

        It 'Should still call Azure when disabling a job with -Enable:$false' {
            # A mock cannot distinguish an unbound switch from one bound to
            # $false, so the presence-versus-value forwarding itself is covered
            # by the Add-OptionalParameter tests.
            $null = Set-SqlElasticJob @script:jobParameters -Enable:$false

            Should -Invoke -CommandName Set-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should update nothing when -WhatIf is used' {
            Set-SqlElasticJob @script:jobParameters -Description 'updated' -WhatIf

            Should -Invoke -CommandName Set-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the job does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should throw rather than silently create a job' {
            { Set-SqlElasticJob @script:jobParameters -Description 'updated' } |
                Should -Throw -ExpectedMessage '*was not found*'

            Should -Invoke -CommandName Set-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
