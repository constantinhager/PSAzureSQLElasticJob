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

Describe 'New-SqlElasticJob' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName New-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ JobName = 'nightly'; Created = $true }
        }

        $script:jobParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
            Name              = 'nightly'
        }
    }

    Context 'When the job already exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ JobName = 'nightly'; Created = $false }
            }
        }

        It 'Should return the existing job without creating one' {
            $result = New-SqlElasticJob @script:jobParameters

            $result.Created | Should -BeFalse

            Should -Invoke -CommandName New-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the job does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should create the job' {
            $result = New-SqlElasticJob @script:jobParameters

            $result.Created | Should -BeTrue

            Should -Invoke -CommandName New-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should create the job disabled unless -Enable is supplied' {
            $null = New-SqlElasticJob @script:jobParameters

            Should -Invoke -CommandName New-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                -not $Enable
            }
        }

        It 'Should pass the recurring schedule through to Azure' {
            $null = New-SqlElasticJob @script:jobParameters -IntervalType 'Day' -IntervalCount 1 -Enable

            Should -Invoke -CommandName New-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $IntervalType -eq 'Day' -and $IntervalCount -eq 1 -and $Enable -eq $true
            }
        }

        It 'Should pass -RunOnce through to Azure' {
            $null = New-SqlElasticJob @script:jobParameters -RunOnce

            Should -Invoke -CommandName New-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $RunOnce -eq $true
            }
        }

        It 'Should reject an unsupported interval type' {
            { New-SqlElasticJob @script:jobParameters -IntervalType 'Fortnight' -IntervalCount 1 } |
                Should -Throw
        }

        It 'Should not allow -RunOnce together with a recurring interval' {
            { New-SqlElasticJob @script:jobParameters -RunOnce -IntervalType 'Day' -IntervalCount 1 } |
                Should -Throw
        }

        It 'Should create nothing when -WhatIf is used' {
            New-SqlElasticJob @script:jobParameters -WhatIf

            Should -Invoke -CommandName New-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
