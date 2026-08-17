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

Describe 'Add-SqlElasticJobStep' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Add-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ StepName = 'rebuild'; Created = $true }
        }

        $script:stepParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
            JobName           = 'nightly'
            Name              = 'rebuild'
            TargetGroupName   = 'all-databases'
            CommandText       = 'EXEC dbo.usp_RebuildIndexes'
        }
    }

    Context 'When the step already exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ StepName = 'rebuild'; Created = $false }
            }
        }

        It 'Should return the existing step without adding one' {
            $result = Add-SqlElasticJobStep @script:stepParameters

            $result.Created | Should -BeFalse

            Should -Invoke -CommandName Add-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the step does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should add the step' {
            $result = Add-SqlElasticJobStep @script:stepParameters

            $result.Created | Should -BeTrue

            Should -Invoke -CommandName Add-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should pass the command text and target group through to Azure' {
            $null = Add-SqlElasticJobStep @script:stepParameters

            Should -Invoke -CommandName Add-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $CommandText -eq 'EXEC dbo.usp_RebuildIndexes' -and $TargetGroupName -eq 'all-databases'
            }
        }

        It 'Should omit optional retry settings that were not supplied' {
            $null = Add-SqlElasticJobStep @script:stepParameters

            Should -Invoke -CommandName Add-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $null -eq $RetryAttempts -and $null -eq $TimeoutSeconds -and $null -eq $CredentialName
            }
        }

        It 'Should pass supplied retry settings through to Azure' {
            $null = Add-SqlElasticJobStep @script:stepParameters -RetryAttempts 3 -TimeoutSeconds 600

            Should -Invoke -CommandName Add-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $RetryAttempts -eq 3 -and $TimeoutSeconds -eq 600
            }
        }

        It 'Should add nothing when -WhatIf is used' {
            Add-SqlElasticJobStep @script:stepParameters -WhatIf

            Should -Invoke -CommandName Add-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
