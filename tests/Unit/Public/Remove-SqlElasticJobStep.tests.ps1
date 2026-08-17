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

Describe 'Remove-SqlElasticJobStep' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Remove-AzSqlElasticJobStep -ModuleName $script:moduleName

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

        It 'Should remove the step' {
            Remove-SqlElasticJobStep @script:stepParameters -Confirm:$false

            Should -Invoke -CommandName Remove-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should remove nothing when -WhatIf is used' {
            Remove-SqlElasticJobStep @script:stepParameters -WhatIf

            Should -Invoke -CommandName Remove-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should return the removed step with -PassThru' {
            $result = Remove-SqlElasticJobStep @script:stepParameters -PassThru -Confirm:$false

            $result.StepName | Should -Be 'rebuild'
        }
    }

    Context 'When the step does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobStep -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should be a no-op by default' {
            { Remove-SqlElasticJobStep @script:stepParameters -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Remove-AzSqlElasticJobStep -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should throw when -Strict is used' {
            { Remove-SqlElasticJobStep @script:stepParameters -Strict -Confirm:$false } |
                Should -Throw -ExpectedMessage '*was not found*'
        }
    }
}
