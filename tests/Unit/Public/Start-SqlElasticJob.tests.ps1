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

Describe 'Start-SqlElasticJob' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Start-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ JobExecutionId = 'exec-1' }
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

        It 'Should start the job and return the execution' {
            $result = Start-SqlElasticJob @script:jobParameters -Confirm:$false

            $result.JobExecutionId | Should -Be 'exec-1'
        }

        It 'Should map Name to the JobName parameter Azure expects' {
            $null = Start-SqlElasticJob @script:jobParameters -Confirm:$false

            Should -Invoke -CommandName Start-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $JobName -eq 'nightly'
            }
        }

        It 'Should pass -Wait through to Azure when supplied' {
            $null = Start-SqlElasticJob @script:jobParameters -Wait -Confirm:$false

            Should -Invoke -CommandName Start-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Wait -eq $true
            }
        }

        It 'Should start nothing when -WhatIf is used' {
            Start-SqlElasticJob @script:jobParameters -WhatIf

            Should -Invoke -CommandName Start-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the job does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJob -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should throw and start nothing' {
            { Start-SqlElasticJob @script:jobParameters -Confirm:$false } |
                Should -Throw -ExpectedMessage '*was not found*'

            Should -Invoke -CommandName Start-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
