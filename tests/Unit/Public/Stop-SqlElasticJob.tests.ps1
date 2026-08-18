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

Describe 'Stop-SqlElasticJob' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Stop-AzSqlElasticJob -ModuleName $script:moduleName

        $script:executionId = [System.Guid]::Parse('5555e5e5-5555-4e55-a555-5555e5e55555')

        $script:jobParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
            Name              = 'nightly'
        }
    }

    It 'Should stop the identified execution' {
        Stop-SqlElasticJob @script:jobParameters -JobExecutionId $script:executionId -Confirm:$false

        Should -Invoke -CommandName Stop-AzSqlElasticJob -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $JobName -eq 'nightly' -and $JobExecutionId -eq $script:executionId
        }
    }

    It 'Should stop nothing when -WhatIf is used' {
        Stop-SqlElasticJob @script:jobParameters -JobExecutionId $script:executionId -WhatIf

        Should -Invoke -CommandName Stop-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
    }

    It 'Should reject a job execution id that is not a GUID' {
        { Stop-SqlElasticJob @script:jobParameters -JobExecutionId 'not-a-guid' -Confirm:$false } |
            Should -Throw
    }

    Context 'When the caller is not signed in' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith { $null }
        }

        It 'Should throw before calling Azure' {
            { Stop-SqlElasticJob @script:jobParameters -JobExecutionId $script:executionId -Confirm:$false } |
                Should -Throw -ExpectedMessage '*Connect-AzAccount*'

            Should -Invoke -CommandName Stop-AzSqlElasticJob -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
