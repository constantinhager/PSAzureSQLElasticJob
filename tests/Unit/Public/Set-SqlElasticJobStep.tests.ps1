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

Describe 'Set-SqlElasticJobStep' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Set-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ StepName = 'rebuild' }
        }

        $script:stepParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
            JobName           = 'nightly'
            Name              = 'rebuild'
        }
    }

    Context 'When the step exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ StepName = 'rebuild' }
            }
        }

        It 'Should update the step' {
            $null = Set-SqlElasticJobStep @script:stepParameters -TimeoutSeconds 7200

            Should -Invoke -CommandName Set-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $TimeoutSeconds -eq 7200
            }
        }

        It 'Should only send the properties that were supplied' {
            $null = Set-SqlElasticJobStep @script:stepParameters -TimeoutSeconds 7200

            Should -Invoke -CommandName Set-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $null -eq $CommandText -and $null -eq $TargetGroupName
            }
        }

        It 'Should update nothing when -WhatIf is used' {
            Set-SqlElasticJobStep @script:stepParameters -TimeoutSeconds 7200 -WhatIf

            Should -Invoke -CommandName Set-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the step does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should throw rather than silently create a step' {
            { Set-SqlElasticJobStep @script:stepParameters -TimeoutSeconds 7200 } |
                Should -Throw -ExpectedMessage '*was not found*'

            Should -Invoke -CommandName Set-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
