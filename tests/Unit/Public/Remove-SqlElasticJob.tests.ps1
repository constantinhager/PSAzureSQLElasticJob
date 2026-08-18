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

Describe 'Remove-SqlElasticJob' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Remove-AzSqlElasticJob -ModuleName $script:moduleName

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

        It 'Should remove the job' {
            Remove-SqlElasticJob @script:jobParameters -Confirm:$false

            Should -Invoke -CommandName Remove-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should pass -Force through to Azure when supplied' {
            Remove-SqlElasticJob @script:jobParameters -Force -Confirm:$false

            Should -Invoke -CommandName Remove-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Force -eq $true
            }
        }

        It 'Should remove nothing when -WhatIf is used' {
            Remove-SqlElasticJob @script:jobParameters -WhatIf

            Should -Invoke -CommandName Remove-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should return the removed job with -PassThru' {
            $result = Remove-SqlElasticJob @script:jobParameters -PassThru -Confirm:$false

            $result.JobName | Should -Be 'nightly'
        }
    }

    Context 'When the job does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should be a no-op by default' {
            { Remove-SqlElasticJob @script:jobParameters -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Remove-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should throw when -Strict is used' {
            { Remove-SqlElasticJob @script:jobParameters -Strict -Confirm:$false } |
                Should -Throw -ExpectedMessage '*was not found*'
        }
    }
}
